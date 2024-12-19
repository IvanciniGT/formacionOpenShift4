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