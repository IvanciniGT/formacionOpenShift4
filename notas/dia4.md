# TRABAJITO OPCIONAL

Intenteis montar un WORDPRESS en el cluster de kubernetes.
Os creais vuestro Namespace.

Montais pods para Wordpress 
Montais pods para el mariadb
Montais services para ambos
Montais secrets / configmaps
Montais pvcs

ESTO SERÁ UN FOLLON

Después, tratais de hacer lo mismo con un chart de helm: BITNAMI
Lo unico es tocar el fichero values.yaml
Tratais de generar desde ese chart el YAML para verlo (TEMPLATE)

---


    App ---> SQL ----> BBDD
     ^                 Esta saturada
    Y siguen llegando peticiones: EMPEORO LA SITUACION
        
        
    App ---> SQL ----> COLA ---> BBDD
    ^                            Esta saturada
    Y siguen llegando peticiones: Esas peticiones, a la primera que no responda, las voy encolando y reteniendo.
        En cuanto la BBDD vuelva a responder, le mando peticiones (las que tengo encoladas)
        
        Ayudo a resolver el problema
        Y además no tengo pérdida de servicio (tendré retraso)

    App -- dame datos? --> COLA ---> 0%    MICROSERVICIO v1.1
                                     100%    MICROSERVICIO v1.2
                           
                           Alguien tiene que darle al ENTER para iniciar el despliegue.
                           Y a ese alguien le tendrían que pagar un plus gigante por riesgo de infarto
                                y degradación de sus sitema circulatorio.

    ISTIO (Linkerd...) lo que hacen es poner un proxy (ENVOY) dentro de cada POD (SIDECAR), 
    Si tengo 500 pods, tengo 500 envoys. Y esos envoys toman control total de las 
    comunicaciones hacia el pod y desde el pod.
    Los envoys son los que reciben peticiones... e internamente las despachan usando la palabra LOCALHOST

    MICROSERVICIO ----> MICROSERVICIO ---> MICROSERVICIO
        tomcat              tomcat            tomcat
        
    Esos microservicios hablan por httpS.
    La cuestión es qué necesito para poner ahí esa S... que no es solo apretar en el teclado la tecla S
        
    Certificados + Clave pública / clave privada
    Que hay que regenerar cada mes
    Que hay que firma por una CA (necesito también una CA)
    Y esa CA darla de alta en los 700 tomcats
    Y a cada atomcat montarle su certificado y su clave privada
        
    Y ESTO COMO LO HAGO? No hay hora en el mundo
        
    ISTIO, una de las cosas que hace es esto. 
    SECURIZAR TODAS LAS COMUNICACIONES DE CLUSTER.. en 2 minutos.
---

# Deployments vs StatefulSets

Usar uno u otro NO ES UNA ELECCION. Viene impuesto por el tipo de software que se despliega.

# Mariadb - Galera: HA / Escalabilidad (Más chica) STATEFULSET

    Nodo1 MariaDB   DATOA   DATOB   - 100 Gbs
    Nodo2 MariaDB   DATOA   DATOC   - 100 Gbs
    Nodo3 MariaDB   DATOB   DATOC   - 100 Gbs

Al multiplicar por 3 la infra, la mejor potencial de rendimiento es de un 50%. 
En 2 uds de tiempo puedo meter 3 datos... 3/2 = 1.5 datos por unidad de tiempo
Con una máquina puedo meter 1 dato por unidad de tiempo

Cuando llega un dato nuevo: DATOA, dónde se guarda? 
- En 1 
- En 2  ******
- En las 3
    - Porque cada una lo guarda
    - Porque todas tiran del mismo almacenamiento.
        Los datos se guardan en un fichero. Y ese fichero no puedo tener 4 procesos a la vez modificándolo.

Lo mismo ocurre conun KAFKA, ELASTIC SEARCH...

Esto implica que cada nodo necesita SU PROPIO VOLUMEN DE ALMACENAMIENTO, y al llevarlo a Kubernetes
esto significa que cada POD necesita su PVC ---> PV

En este caso, no me interesa definir PVCs.. Sino PLANTILLAS de PVCs

    1 plantilla de PVC -> 3 PVCs -> 3 PVs

# WORDPRESS = DEPLOYMENT

    Nodo 1
        Apache / PHP / Programas del WP - VOLUMEN A
    Nodo 2                                      < BALANCEO      < CLIENTE
        Apache / PHP / Programas del WP - VOLUMEN A
        
    Cargo un fichero: PDF
    Van los 2 apaches a TOCAR el mismo fichero a la vez? NO, eso me lo garantiza el WP
    Volumen COMPARTIDO

Solo quiero un PVC -> 1 PV que comparten los programas


# Más diferencias entre ellos

Cuando trabajo con un DEPLOYMENT, a TODOS LOS EFECTOS, los pods son intercambiables entre si,
    ya que son iguales.
Cuando trabajo con un STATEFULSET, a TODOS LOS EFECTOS, los pods NO SON SIEMPRE INTERCAMBIABLES entre si.
    ya que son distintos... tiene datos distintos.. y tienen su personalidad.
    Esto implica que a veces me vale cualquiera... pero otras veces NO.
    Y en esas OTRAS VECES, he de poder elegir a CUAL DE ELLOS QUIERO INVOCAR.... evidentemente sin usar una IP.
    Necesito un fqdn que apunte a CADA POD del statefulset...
    En paralelo con un fqdn que balancee entre ellos.

## ELASTICSEARCH

Es una herramienta distribuida que opera en cluster.
Distribuida? que distintos componentes hacen distintas funciones.
Los nodos tiene ROLES: maestros, datos, ingesta, machine learning, coordinadores....

Los maestros son los que orquestan/monitorizan un cluster. De hecho en ES solo hay 1 maestro cada vez.
Pero necesito al menos configurar 3 nodos de tipo maestro. 
(potenciales maestros, de los que luego se toma SOLO 1 para el papel de maestro)

Los nodos adicionales (data, ingesta, ml) se quieren juntar con los nodos maestros para formar un cluster.
Antaño, la formación de un cluster se hacía mediante una comunicación BROADCAST en RED (grito al aire).
Más adelante se cambio por comunicaciones UNICAST (de uno a uno)

Configuramos los NODOS adicionales para que al arrancar intenten conectar con ALGUNO DE LOS MAESTROS... 
y se presenten. A cuál de los 3 se debe conectar CADA NODO ADICIONAL? A CUALQUIERA
En cuantito se presente a uno, ese UNO le presentará al resto de amiguitos.

    MAESTRO 1
    MAESTRO 2               < BALANCEO que apunte a cualquiera  <   DATA
    MAESTRO 3                      (KUBERNETES: SERVICE)

Los maestros, también tienen que presentarse entre si.
Me vale para los maestros configurar que se presenten a esa misma IP de balanceo... 
que le redirigirá a alguno de ellos? NO.. por qué?
    Porque puedo tener la mala suerte de que el MAESTRO 1, al llamar al la IP DE BALANCEO de maestros
    la petición por detrás sea enviada a él mismo... Y entonces se queda OUT del cluster

En un cluster de kubernetes la configuración es:
    MAESTRO1 -> MAESTRO2 y MAESTRO3
    MAESTRO2 -> MAESTRO3
    El resto de nodos a cualquier maestro disponible

---

BBDD puede instalarse de 3 formas:
- Standalone                Solo tengo una instancia
- Replicación               Solo tengo una instacia capaz de RECIBIR DATOS
                            Tengo otra a la espera por si la primera cae (CLUSTER ACTIVO/PASIVO)
                                Muchas BBDD permiten que la replica pueda PROVEER DATOS (QUERIES: SELECT)
- Cluster Activo - Activo   Tengo N instancias donde todas puede leer y escribir datos.

PREGUNTA:
- En un entorno de prod... Standalone SIRVE? Con Kubernetes SI y de hecho es lo más habitual!
  Y la HA?
    Si tengo los datos de la BBDD fuera, en un volumen con REDUNDANCIA BIEN PROTEGIDOS
    Si la BBDD cae... levanto otra. 
        OJO.. voy a tener tiempo de INDISPONIBILIDAD: 3 minutos.
    KUBERNETES ME OFRECE UN ACTIVO / PASIVO... lo único que el PASIVO no está preccreado ocupando espacio/recursos.


    CLUSTER ACTIVO / PASIVO con FAILOVER
    Eso es factible con una BBDD en modo replicación.
    Pero esto es un mogollón MU GORDO. 
        Si la REPLICA toma el papel de MAESTRA... ya es IRRECONCILIABLE con la maestra.
        Y me toca montar una nueva replica. 3 horas.
    Para evitar esto... El FAILOVER lo configuraré con una demora. Si a los 30 seg.. 1 minuto no contesta,
    entonces haz el failover.
---

# Alta Disponibilidad

NO ES GARANTIZAR QUE UN SISTEMA ESTARA FUNCIONANDO EL 100% del tiempo.
TRATAR DE GARANTIZAR UN DETERMINADO TIEMPO DE SERVICIO PACTADO CONTRACTUALMENTE (SLA)
- 90%           36,5 dias al año el servicio OFFLINE    |   €
- 99%           3,65 dias al año el servicio OFFLINE    |   €€
- 99.9%         8 horas al año el servicio OFFLINE      |   €€€€€€
- 99.99%        20 minutos el servicio OFFLINE          |   €€€€€€€€€€€€€€
- 99.999%       MU POQUITO                              v   €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€

Esto es la carta a los reyes magos.

---

# Charts de HELM. Consideraciones a tener en cuenta:

- Contraseñas. NUNCA ALEATORIAS y tampoco en el fichero
    No quiero una contraseña en claro en un fichero de texto... que además ese fichero irá a un sistema de control de versión.
    Alternativa GUAY: Crear nosotros un secreto con la contraseña previamente
                      Y usar el secreto en el values.yaml
                      La realidad es que los SECRETOS no los solemos crear desde archivos de manifiesto.
                      Algunos objetos pueden ser creados directamente desde comando, sin necesidad de un archivo YAML.
        
- PVC: Nunca quiero que el chart genere mis PVC... los quiero crear yo a manita!
  ¿Cuál es el problema? Estos son trucos de perro viejo.
  El problema es que si HELM es quien crea las pvc, HELM puede borrarlas.
    Y como alguien la lie y en lugar de hacer un 
        DIA 1: HELM INSTALL
        DIA 2: HELM UPDATE cuando haya una actualización
        DIA 3: HELM UNINSTALL
                    ---> BORRA LAS PVC... Y entonces estoy bien jodido
                        Con suerte en el backend real no se habrán borrado los datos...
                        Aunque puede ser que si!
        DIA 1: HELM INSTALL
