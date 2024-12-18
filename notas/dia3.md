# Volumenes en Clusters de Producción con Contenedores

## Para qué sirven?

- Persistencia de datos                         VOLUMENES PERSISTENTES
        nfs
        iscsi
        ... y decenas
        Kubernetes/Openshift traen algunos...
        Pero... Las cabinas de almacenamiento ofrecen sus propios tipos de volumen a kub.
- Compartir información entre contenedores      VOLUMENES NO PERSISTENTES
        emptyDir: {}
- Inyectar ficheros/carpetas                    VOLUMENES NO PERSISTENTES
        configMap
        secret
        hostPath

## Cómo se definen:

Los volumenes se definen a nivel de POD.
Pero se montan a nivel de CONTENEDOR.
Puedo tener un volumen declarado en un POD y que cada contenedor de ese POD lo monte en una ruta diferente

```yaml

kind:               Pod
apiVersion:         v1

metadata:   
    name:           pod-ivan
    
spec:
    volumes:
        - name: miVolumen
          emptyDir: 
            medium: Memory
        - name: miVolumen2
          hostPath:
            path: /home/ubuntu/environment/datos
            type: DirectoryOrCreate
        - name: miVolumen3
          persistentVolumeClaim:
            claimName:  mi-peticion
    containers:
        - name:         contenedor1
          image:        nginx
          pullPolicy:   IfNotPresent
          volumeMount:
            - name:     miVolumen
              mountPath: /datos

        - name:         contenedor2
          image:        fedora
          pullPolicy:   IfNotPresent
          command: 
            - tail 
            - -f 
            - /dev/null
          volumeMount:
            - name:     miVolumen
              mountPath: /datosOtros
          volumeMount:
            - name:     miVolumen2
              mountPath: /datosOtros2
```

---

# Contenedores en PODs.

Al contrario que en DOCKER, los contenedores de un POD DEBEN ESTAR EN FUNCIONAMIENTO PERPETUO.
Dicho de otra forma, si kubernetes detecta que un contenedor no está trabajando.. SE VUELVE LOCO !

En un contenedor ejecutamos procesos.

El primer proceso que arranca es el COMANDO del contenedor. Y recibe el id 1.
La vida del contenedor está vinculada a la de ese comando/proceso 1.
Si el proceso 1 acaba... o cae... El contenedor se da por finalizado.

KUBERNETES QUIERE que TODOS LOS CONTENEDORES de un POD estén corriendo de perpetua. No admite un contenedor que acabe.
Los contenedores de los PODS están pensados para ejecutar procesos que se queden corriendo indefinidamente: NGINX, MYSQL, JENKINS, ELASTIC...
Si detecta que un contenedor no está corriendo... A REINICIAR EL POD ! Si tiene que reiniciar el pod 257.987 veces, lo hace sin problema.
A ver si la siguiente se queda arriba.

Ese es el funcionamiento ESTANDAR DE KUBERNETES y NO SE PUEDE ALTERAR!


El log de un contenedor es la SALIDA ESTANDAR Y DE ERROR del proceso 1 que corre en el contenedor.

## Cómo determina kubernetes que un Contenedor / POD debe ser reiniciado?

- Si el proceso 1 de un contenedor está corriendo o no.
    Si no: REINICIO DE POD
  Esto es suficiente en un entorno de producción? NO
- En docker existe el concepto de HEALTH CHECK
  En Kubernetes NO. Existe el concepto de PROBES... y hay varios que se pueden configurar a nivel de CONTENEDOR:
- STARTUP PROBE         Mira si el contenedor está arrancando.
                            Definimos un comando de comprobación y un tiempo límite hasta que el comando responda EXIT CODE 0
                            Si en el tiempo límite establecido no responde un 0, KUBERNETES REINICIO DE POD

                            A los 5 segundos comienza a hacer pruebas
                            Hazlas cada 6 segundos
                            Si en 300 pruebas ha fallado -> REINICIAS

- LIVENESS PROBE        Una vez que el startup ha concluido, empiezan los liveness probe
                            Tratan de determinar si el proceso sigue vivo... y en un estado saludable.
                            Estas pruebas se hacen cada X tiempo (es otro comando que configuramos)
                            Si varias veces seguida (esto también es configurable) no responde un 0: KUBERNETES: REINICIO DE POD
                                Tengo una BBDD, puedo tirar un comando para ver si acceso a ella... OK
- READYNESS PROBE       Cuando tengo un contenedor VIVO, en paralelo se comienzan a ejecutar las pruebas de READYNESS
                            Esta prueba (que es otro comando) trata de determinar si un proceso está listo para prestar servicio a los usuarios.
                            Estas pruebas se hacen cada X tiempo (es otro comando que configuramos)
                            Si varias veces seguida (esto también es configurable) no responde un 0: KUBERNETES: SACARLO DE BALANCEO (del service asociado)
                                Tengo una BBDD, intento ejecutar una query SQL... falla!
                                    Eso significa que el pod está mal? (que la BBDD está para reiniciar?)
                                    No tiene por qué? A lo mejor la BBDD está en modo mnto.. haciendo un backup.

Al definirse un SERVICE de kubernetes... qué era un service de kubernetes en su forma más básica CLUSTERIP)?
- IP DE BALANCEO + Entrada en el dns de kubernetes
- La IP De balanceo, balancea entre?
    - Los pods que tengan una etiqueta (LABEL) y estén READY!
    - Si no están ready, no se meten a esta lista!
    - Si dejan de estar READY, se sacan de la lista de balanceo

## Y entonces, en srio de verdad de la buena, que no puedo ejecutar un trabajo que acabe?

Y si quiero lanzar un proceso los jueves por la noche que haga un backup de una BBDD?
Ese proceso, si lo quiero ejecutar dentro de kubernetes, se TIENE QUE EJECUTAR en un contenedor.

Para esto Kubernetes tiene otro objeto: JOB
Un JOB difiere de un POD en que los contenedores del JOB están pensados para ejecutar trabajos que ACABEN!.
Si un trabajo de un JOB no acaba, KUBERNETES se vuelve loco! y LO REINICIA!!!
Justo lo contrario que los PODs

Sobre los JOBS (por encima de ellos) tenemos el concepto de CRON JOB.

Luego hay una cosita más...

DENTRO DE UN POD, además de CONTAINERS, podemos definir INIT-CONTAINERS
Si un Init Container no acaba, se reinicia el pod.
Los Containers se ejecutan en paralelo, una vez los initContainers hayan acabado.
Los InitContainer se van ejecutando SECUENCIALMENTE según el orden definido en el pod.
Los init Container están pensados para tareas de inicialización.
Coge un volumen, descarga en él unos ficheros de un repo de git... y listo
Ahora arranca un apache... y ponle como fichero de configuración el que está en el volumen que hemos rellenado en el initi-container

```yaml

kind:               Pod
apiVersion:         v1

metadata:   
    name:           pod-ivan
    
spec:
    initContainers:
        - name:         init-contenedor1
          image:        fedora
          pullPolicy:   IfNotPresent
          command: 
            - echo
            - HOLA
        - name:         init-contenedor2
          image:        fedora
          pullPolicy:   IfNotPresent
          command: 
            - echo
            - ADIOS
    containers:
        - name:         contenedor1
          image:        nginx
          pullPolicy:   IfNotPresent

        - name:         contenedor2
          image:        fedora
          pullPolicy:   IfNotPresent
          command: 
            - tail 
            - -f 
            - /dev/null
```

---

Hay imágenes de contenedor que no están pensadas para ejecutarse directamente:
- Fedora
- Ubuntu
- Alpine
- Debian

Son lo que llamamos imágenes BASE de contenedor.
Se utilizan como BASE sobre la que montar imágenes CUSTOM.

Yo monto en mi empresa mi app.
Creo un contenedor con imagen ALPINE.
Eso me da toda una estructura de carpetas y algunos comandos útiles... que puedo usar ahora para montar mi app en ese contenedor.
    Para poder montar mi app.. necesito un tomcat.. wget http://apache.or/download/tomcat7
                                                    tar..
Una vez monto mi app, exporto el contenedor como una imagen nueva... que es la que distribuyo.

---


# Continuación volúmenes

Como veís eso de estar creando volumenes (PVC / PV) en el kubernetes?
Al final, el desarrollador/negocio tiene que decir lo que necesita.. es decir, crear el pvc?
Eso lo podemos automatizar? NO

Y la creación del pv, que hace el administrador? Esa sería automatizable?

Para crear un volumen, que hay que hacer? desde el punto de vista del administrador?
1. Crearlo en el sitio FISICO (Cabina, AWS, AZURE,...)
2. Registrarlo

Esto sería automatizable? SI, directamente en KUBERNETES

Ese es el papel de los PROVISIONADORES DINAMICOS DE VOLUMENES

En todo cluster montamos (los ADMINISTRADORES) unos PROVISIONADORES DINAMICOS:
- Un programa que monitoriza las PVC que se crean en el cluster por los desarrolladores
- Cuando una pvc es detectada, si el storageClass que viene en la pvc es el storageClass
  que atiende ese provisionador (CADA PROVISIONADOR SE CONFIGURA PARA ATENDER 1 o VARIOS storageclass)
  El provisionador:
    - Crear un volumen en el BACKEND CORRESPONDIENTE, del tamaño EXACTO que pide desarrollo
    - Registra la PV en Kubernetes

Yo como administrador, no voy a estar creando PVs. Configuro alguien que lo haga por mi.
Y de paso, que cree el volumen REAL donde sea.

Cuando contratamos un cluster de Kubernetes a un cloud:
- AWS
- AZURE
En ese cluster de kubernetes que el CLOUD me monta, ya me vienen muchas cosas:
- BALANCEADOR DE CARGA EXTERNO
- INGRESS CONTROLLER
- PROVISIONADOR DINAMICO DE VOLUMENES que trabaja contra el CLOUD como soporte físico de los mismos
Cuando montamos un cluster de kubernetes on prem, me toca a mi montar un PROVISIONADOR DE VOLUMENES

Con OPENSHIFT, mismo rollo.
Openshift lo puedo contratar sobre AWS.. y me trae todo esto preconfigurado (para trabajar contra AWS)
Openshift lo puedo contratar sobre AZURE.. y me trae todo esto preconfigurado (para trabajar contra AZURE)
Si lo monto en PREM... ya me toca a mi.
Si en lugar de Openshift monto TANZU (la distro de kubernetes de vmware) me vendrá en automático un provisionador 
de volumenes que trabaje en automático sobre VMWARE (vSAN)

---

# ServiceAccount

CREDENCIALES/CUENTA que puedo usar apra comunicarme con la API DE KUBERNETES.
Ese service account puedo usarlo YO (HUMANO) o un programa.
De hecho, quien lo usa siempre es un programa.
    kubectl --serviceAccount--> apiServer
    oc      --serviceAccount--> apiServer
    kubernetes-dashboard    --serviceAccount--> apiServer
    openshift-dashboard     --serviceAccount--> apiServer

Los service accounts quien los usa son PROGRAMAS... SIEMPRE!
    Como los de arriba (oc, dashboard)
    o por ejemplo: NFS PROVISIONER

Asociado a ese concepto: SERVICE ACCOUNT: Nombre
```yaml

apiVersion: v1
kind: ServiceAccount

metadata:
  name: release-name-nfs-subdir-external-provisioner
```

Kubernetes genera un TOKEN DE SEGURIDAD.

# Role

Un role es un nombre, que tiene asociados una serie de permisos dentro de un namespace

Permiso? VERBO que puedo aplciar sobre un TIPO DE OBJETO


```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-release-name-nfs-subdir-external-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pod"]
    verbs: ["get" "create", "update", "patch"]
```
# RoleBinding

La asocacion de un ROLE a un SERVICE ACCOUNT

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-release-name-nfs-subdir-external-provisioner
subjects:
  - kind: ServiceAccount
    name: release-name-nfs-subdir-external-provisioner
    namespace: provisionador
roleRef:
  kind: Role
  name: leader-locking-release-name-nfs-subdir-external-provisioner
  apiGroup: rbac.authorization.k8s.io
```

# ClusterRole

Un cluster role es un nombre, que tiene asociados una serie de permisos a nivel de cluster

Permiso? VERBO que puedo aplciar sobre un TIPO DE OBJETO
```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: release-name-nfs-subdir-external-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
```

# ClusterRoleBinding

La asocacion de un CLUSTERROLE a un SERVICE ACCOUNT

Cuando un programa hace una petición al API SERVER:
    - Quiero hacer un CREATE de un PV
El apiServer, revisa que en los ROLES o CLUSTER ROLES asociados (BINDINGs) al SERVICE ACCOUNT
que el programa está mandando, esté declarado ese verbo para ese tipo de objeto.









---

Kubernetes SOLO TIENE EL CONCEPTO DE SERVICE ACCOUNT

En Openshift hay otro concepto ADICIONAL (Otro tipo de objeto): USER
Un USER de Openshift es una extensión del objeto SERVICE ACCOUNT de kubernetes

Kubernetes no obliga a los pods a declarar un service account.
Solo deben llevarlo, aquellos pods que tenga un contenedor, 
que ejecute un programa que tenga que hablar con el API SERVER

Openshift SI OBLIGA a que todo pod tenga un service account

JENKINS
    JOB ---> Ese job quiero que se ejecute en su propio POD
    Y Jenkins debe crear un POD para el job... monitorizarlo
    Y cuando acabe el JOB, borrarlo
    
    Jenkins encesita comunicación con el APISERVER

ANSIBLE TOWER
    Cuando ejecuta un playbook en Kubernetes, ese playbook lo ejecuta dentro de un JOB
    Y ese JOB Ansible Tower debe crearlo ... y borrarlo después.
    
    Ansible Tower necesita un service account