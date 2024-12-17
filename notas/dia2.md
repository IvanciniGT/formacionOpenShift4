# Contenedor

Entorno aislado donde ejecutar procesos... dentro de un kernel de SO (Linux).
Aislado:
- Sus propias variables de entorno
- Su propia conf. de red --> Su propia IP
- Su propio Sistema de Archivos:
    - Tendre instalados programas, configuraciones... dependencias
- Puede tener limitaciones de acceso al Hardware (solo 2 cpus, solo 2Gbs RAM)

Se crean desde imagenes de contenedor:

# Imagen de contenedor

Es un archivo comprimido que suele llevar dentro:
- Una estructura de carpetas compatible con POSIX
- Programas ya instalados con preconfiguraciones
- Metadatos:
    - Qué puertos usan esos programas
    - En que directorios del FS guardan datos
    - El proceso inicial que debe ejecuatrse al arrancar el contenedor

# Volumenes

Son puntos de montaje en el FS del conetendor que pauntan a volumenes de 
almacenamiento fuera del FS del contenedor:
- Carpetas compartidas con el host
- Carpetas NFS
- Volumenes iSCSI

## Para qué sirven?

- Persistencia de datos tras la eliminación del contenedor
- Compartir datos entre contenedores
- Inyectar ficheros / directorios a un contenedor

# Configuración

Las imágenes llevan programas preinstalados.. pero su configuración es la que yo quiero? NO
Cómo los configuro?
- Inyectar un fichero de configuración mediante volumenes.
- Variables de entorno

# Gestores de contenedores:

- Docker
- Podman
- Crio
- ContainerD

---

# Kubernetes (Openshift, Tanzu, Karbon...)

Va a orientado a montar un entorno de producción (HA, escalabilidad, seguridad) basado en contenedores.

Kubernetes es quien opera el entorno de producción.
Y nosotros nos limitamos a configurar estados en kubernetes. USAMOS LENGUAJE DECLARATIVO.

Todas las configuraciones (estados) los suministramos a kubernetes mediante Archivos de MANIFIESTO YAML.

```yaml

apiVersion:     v1        # Librería que define ese tipo de objeto: api/version
kind:           Namespace # Tipo de objeto que defino

metadata:
    name:       ivan
    
# spec:

```

## Tipos de objeto básicos que manejamos en kubernetes

### Node

Un entorno en que pudo ejecutar contenedores (máquina física, virtual)

### Namespace

DEFINICION:         Espacio de nombres. Grupo de recursos (objetos) cuyos nombres son únicos.
                    Dentro de un namespace los nombres (NAME DEL METADATA) son únicos.
PARA QUE SE USA:    Permitir el mismo despliegue en varios "entornos" dentro del cluster
                    Separar proyectos/despliegues
                    Limitar acceso / permisos a usuarios
                    Limitar recursos
Muchos objetos de kubernetes van asociados a un namespace.. aunque no todos.

### Pod

Un grupo de contenedores que:
- Comparten configuración de red (y por ende IP, y además puedenb hablar entre si mediante localhost)
- Se despliegan en el mismo host
    - Pueden compartir volumenes locales de almacenamiento
- Escalan juntos
- Se reinician juntos

Cuántos POD vamos a crear nosotros en un cluster? NINGUNO
En su lugar creamos plantillas:

### Plantillas de pods

#### Deployment

Plantilla de pod + número inicial de pods creados desde esa plantilla.

#### StatefulSet

Plantilla de pod + número inicial de pods creados desde esa plantilla + Plantilla(s) de pvc

#### DaemonSet

Plantilla de pod de la que kubernetes crea 1 pod en cada nodo del cluster

### Job

### CronJob

### COMUNICACIONES EN EL CLUSTER

#### Service

#### Ingress

### Configmap

### Secret

### PV          (no va a asociado a namespace)

### PVC

### HPA




### Role        (no va a asociado a namespace)

### RoleBinding (no va a asociado a namespace)

### ClusterRole (no va a asociado a namespace)

### ClusterRoleBinding  (no va a asociado a namespace)

### NetworkPolicy

### ResourceQuota

### LimitRange

### ServiceAccount  (no va a asociado a namespace)



---

# Comunicaciones en un cluster de kubernetes
    
                           
                           
    192.168.0.10:443         
        192.168.1.101:38080
        192.168.1.102:38080
        192.168.1.201:38080
        192.168.1.202:38080
        192.168.1.203:38080                                                             Navegador: https://miapp
    Balanceador de carga                    miapp -> 192.168.0.10                       MenchuPC
         |                                      |                                         |
    192.168.0.10                            DNS Server                                    |
         |                                      |                                         |
-+-------+--------------------------------------+-----------------------------------------+--- red de mi empresa 192.168.0.0/16
 |                                      
 += 192.168.1.101 - Nodo maestro1
 ||                  |     - Netfilter
 ||                  |          10.10.1.103:80,443 -> 10.10.0.221:80,443
 ||                  |          10.10.1.101:1521 -> 10.10.0.101:1521
 ||                  |          10.10.1.102:8080 -> 10.10.0.201:8080 | 10.10.0.202:8080
 ||                  |          192.168.1.101:38080 -> 10.10.1.103:80
 ||                  |
 ||                  + 10.10.0.10 - CoreDNS
 ||                                     base-datos -> 10.10.1.101
 ||                                     web-logic  -> 10.10.1.102
 ||                                     proxy-reverso  -> 10.10.1.103
 ||
 += 192.168.1.102 - Nodo maestro2
 ||                  |     - Netfilter
 ||                  |          10.10.1.101:1521 -> 10.10.0.101:1521
 ||                  |          10.10.1.102:8080 -> 10.10.0.201:8080 | 10.10.0.202:8080
 ||                  |          192.168.1.102:38080 -> 10.10.1.103:80
 ||                  |          10.10.1.103:80,443 -> 10.10.0.221:80,443
 ||   
 ||
 += 192.168.1.201 - Nodo1
 ||                  |     - Netfilter
 ||                  |          10.10.1.101:1521 -> 10.10.0.101:1521
 ||                  |          10.10.1.102:8080 -> 10.10.0.201:8080 | 10.10.0.202:8080
 ||                  |          192.168.1.201:38080 -> 10.10.1.103:80
 ||                  |          10.10.1.103:80,443 -> 10.10.0.221:80,443
 ||                  |
 ||                  +- 10.10.0.201 - Pod Weblogic
 ||                  |                      + Contenedor Weblogic : 8080
 ||                  |                                      jdbc://base-datos:1521
 ||                  +- 10.10.0.221 - Pod Proxy reverso
 ||                                         + Contenedor nginx : 80, 443
 ||                                                         http://miapp:80 --> http://web-logic:8080  < INGRESS
 ||                                                                -----
 += 192.168.1.202 - Nodo2
 ||                  |     - Netfilter
 ||                  |          10.10.1.101:1521 -> 10.10.0.101:1521
 ||                  |          10.10.1.102:8080 -> 10.10.0.201:8080 | 10.10.0.202:8080
 ||                  |          192.168.1.202:38080 -> 10.10.1.103:80
 ||                  |          10.10.1.103:80,443 -> 10.10.0.221:80,443
 ||                  |
 ||                  +- 10.10.0.101 - Pod OracleDatabase
 ||                                         + Contenedor BBDD : 1521
 ||
 += 192.168.1.203 - Nodo3
                     |     - Netfilter
                     |          10.10.1.101:1521 -> 10.10.0.101:1521
                     |          10.10.1.102:8080 -> 10.10.0.201:8080 | 10.10.0.202:8080
                     |          192.168.1.203:38080 -> 10.10.1.103:80
                     |          10.10.1.103:80,443 -> 10.10.0.221:80,443
                     |
                     +- 10.10.0.202 - Pod Weblogic
                                            + Contenedor Weblogic : 8080
                                                            jdbc://base-datos:1521

La red virtual del cluster : 10.10.0.0/16

En weblogic, daré de alta la BBDD... 
OPCION 1 : URL:   jdbc://10.10.0.101 ? Funciona? SI
           Lo haría alguna vez en la vida? NUNCA JAMAS ! Por qué?
            - A priori no conozco la IP
            - Esa IP puede variar
Qué me interesa?
    - Usar un nombre de red: fqdn: base-datos
            URL:   jdbc://base-datos
    - Pero, eso no me exime de tener una IP que no cambie: 10.10.1.101

Dentro del kernel de Linux, hay un componente que se llama NETFILTER
Por NETFILTER pasan TODAS las comunicaciones de red de un kernel LINUX.

La IP de servicio no tiene ningún programa detras (ni un HA Proxy, ni balanceador de carga ni nada...)
Es solo una regla en NETFILTER (DE CADA HOST). Ese trabajo quién lo hace?

ESO ES LO QUE DA UN SERVICIO (Service de kubernetes)
- ClusterIP:    IP Fija de Balanceo  + entrada en el dns de kubernetes apuntando a esa IP
                    ^^^
                Lo que tengo es una IP de balanceo... NO UN BALANCEADOR DE CARGA (nginx, apache httpd, haproxy, envoy)
                                                        Suelen llevar una COLA de peticiones
- NodePort:     ClusterIP + Exposición de esa IP/Puerto en cada nodo del host, en un puerto por encima del 30000
- LoadBalancer: NodePort + Configuración AUTOMATIZADA de un balanceador de carga EXTERNO compatible con Kubernetes.
    Para usar un servicio de tipo LOADBALANCER, lo primero que necesito es disponer de un Balanceador de carga externo compatible con Kubernetes
    Los clouds, cuando le contrato un cluster de Kubernetes / Openshift, me "regalan" (€€€) un balanceador de carga externo compatible con kubernetes
    Si trabajo con un cluster on prem, necesito instalar YO un balanceador de carga externo compatible: METALLB
    Openshift ya lo lleva.. se me instala solo on prem.

Voy a exponer "solo" el proxy reverso. Ese proxy reverso he de configurlo... darle REGLAS de alta.
Esas reglas es lo que llamamos INGRESS.

# INGRESS CONTROLLER

Es el conjunto de:
- Pods creados desde plantillas que ejecutan un PROXY REVERSO
- Un programa que queda en el cluster ejecutándose en segundo plano de forma que cuando alguien (humano) carga un objeto de tipo INGRESS
  en el cluster, modifican los ficheros de configuración de los proxies reversos que estén en ejecución.

Un INGRESS lo que me ofrece es un a sintaxis para configurar las REGLAS del proxy reverso, INDEPENDIENTE del proxy reverso concreto que yo use.

Openshift me da ya preinstalado un INGRESS CONTROLLER.
Lo que ocurre es que en Openshift luego no trabajamos con Objetos de tipo Ingress. Trabajamos con objetos de tipo ROUTE!

La gestión del DNS de la empresa me la como yo.. KUBERNETES NO TRAE NADA para automatizar esa gestión.
Hay addons que me permiten automatizar ese trabajo: OFICIAL (no de serie en kubernetes): https://github.com/kubernetes-sigs/external-dns
Openshift me regala esto: 
- Route = Ingress + Configuración automática de DNS Externo
    Route es lo que os he llamado CRD: Custom Resource Definition... que ofrece REDHAT
En los nodos maestros se instala el PLANO DE CONTROL ???
Básicamente los programas propios de kubernetes:
- Base de datos:    etcd
- KubeProxy:        Da de alta reglas en el NETFILTER DE CADA HOST
                    Se instala en cada HOST: DaemonSet 
- api:              Con quien nos comunicamos del cluster desde nuestros clientes:
                        - kubectl
                        - oc (Openshift)
                        - dashboards gráficos:          Monitorizar (Entrar un momentito y alguna ñapa... y ver el estado del cluster)
                            - kube-dashboard            Operar? NO (no son automatizables)
                            - Openshift dashboard
- Driver de red         Quien monta y gestiona la Red virtual (entre los nodos) a la que se conectarán los pods
- CoreDNS
- Controller Manager    Este es el que hace toda la operación
- Scheduller            Es el que se encarga de determinar en que nodo pone un pod.
                            - Compromiso de recursos del nodo
                            - Afinidades y antifinidades
                            - Taints y Tolerations

En kubernetes, al instalarlo, montamos un primer nodo maestro.
Le instalo un driver de red virtual

---

Por lo que llevamos

Servicios en un cluster:
                    Cuántos?    %
    ClusterIP           Todos menos 1       Comunicaciones INTERNAS
    ------------------------------------------------------------------
    NodePort            0                   Comunicaciones EXTERNAS
    LoadBalancer        1
        IngressController: Proxy Reverso


---

# Imágenes de contenedor

Qué identifica a una imágen de contenedor... 
Cómo identificamos NOSOTROS HUMANOS una imagen de contenedor?

    registry/repo:tag

El registry es opcional... si no pongo registry se toma por defecto el que esté 
configurado en el gestor de contenedores (docker, containerd, crio) de la máquina (host)

    nginx:latest
          ------
    -----   tag
    repo

    No he puesto registry


    artefactos.iochannel.tech/ivancinigt/iochannel-ssh-container:v1.0.0
    -------------------------
    registry                 -----------------------------------
                                repo                             ------
                                                                 tag

    Eso si.. en mi caso, mi registry requiere login

Las empresas suelen tener sus propios registries privados para SUS IMAGENES de contenedor:
- Gitlab
- Artifactory
- Nexus
- Quay.io.  Registry de Redhat
        Quay es un producto también. Y puedo montarlo on Prem 

Kubernetes NO TIENE un registry propio.
Openshift SI TRAE UN REGISTRY PROPIO.
Y podemos crear imágenes y subirlas al registry de OPENSHIFT

El TAG también es opcional. Si no pongo nada, se toma por defecto: latest

PERO CUIDADO: latest es un tag más, como cualquier otro.
Los fabricante pueden decidir publicar una imagen con tag LATEST o NO.
Es más el uso de "latest" es una muy mala práctica!

Habitualmente encontramos imágenes cuyo tag lleva dentro la versión del software
(usando para la versión: ESQUEMA SEMANTICO)

    1.2.3
    
                    ¿Cuándo suben?
    1   MAJOR       Breaking changes
                    Cambios que rompen RETROCOMPATIBILIDAD (cuando quito cosas)
    2   MINOR       Nueva funcionalidad
                    Funcionalidad marcada como obsoleta (deprecated) 
                        + Adicionalmente pueden venir bugfixes
    3   PATCH       Arreglo de bugs

En los tags de las imágenes encontramos:
    - Tags FIJOS: Que siempre apuntan a la misma IMAGEN / VERSION
    - Tags VARIABLES: Que van cambiando la imagen / version a la que apunta.
    
TAGS HABITUALES:
- latest            NUNCA... Hoy me puede instalar la versión 1.2.3 y mañana sin enterarme la 2.0.0
- 1                 NUNCA... Hoy me puede instalar la versión 1.2.3 y mañana sin enterarme la 1.3.0
                        En esa versión vendrá NUEVA FUNCIONALIDAD que no usaré
                        pero puede traer nuevos BUGS
- 1.2       ****    (APTA PARA PRODUCCION) Más FLEXIBLE. La funcionalidad que necesito viene marcada por 1.2
                    Lo que quiero es PARA ESA FUNCIONALIDAD lña verisón que tenga MAS BUGS CORREGIDOS               
- 1.2.3             ESTA ES LA MAS CONSERVADORA (APTA PARA PRODUCCION)

Y el día N quizás TODOS ELLOS apuntan a la misma imagen. 

---

Asignación de recursos a CONTENEDORES:

                requests:               Lo que se garantiza
                    cpu:        1
                    memory:     1GiB
                limits:                 Lo que se podría permitir usar dado el caso
                    cpu:        2000m
                    memory:     1GiB

java -Xmx2000m -Xms2000m
        ^           ^
        maximo      inicial
        
    Cuál es la recomendación en JAVA: MISMO VALOR
    Si yo sé que puedo llegar a necesitar X RAM... la pido desde el principio.
    AQUI EN KUBERNETES IGUAL !!!!
    El limit de RAM = REQUEST RAM
    
# A qué afectan los request y los limits:

## Scheduler

                                                  SCHEDULER
                                                    V
            CARACTERISTICAS     COMPROMETIDO <-> DISPONIBLE      USO       <->   SIN USAR
            RAM     CPU         RAM     CPU      RAM     CPU     RAM     CPU     RAM     CPU
    Nodo1    10      4                           2       0                       0       0
        Pod nginx                 4       2                      5       2
            En estas kubernetes SE CRUJE el primer pod de nginx.. NI COLORAO SE PONE.
        Pod nginx2                4       2                      5       2
    Nodo2    10      4                           3       2                       6       2
        Pod postgres              7       2                      4       2

    Pod: nginx
    Request  4       2
    Limit    8       3

    Pod: postgresql
    Request  7       2
    Limit    8       3

A un programa le puedo ir quitando CPU sin problema... IRA MAS LENTO
A un programa no le puedo quitar RAM... ni un byte.. O el programa EXPLOTA






# MEMORIA: 1GiB

1 Gibibyte

1 GB = 1000 MB
1 MB = 1000 KB Antiguamente eran 1024... CAMBIO HACE 25 años para compatibilizar con los prefijos del SI

Se inventaron otra medida: bibytes. Los bibytes son los operan en 1024

# CPU:

Podemos establer el tiempo de uso (compartido) de CPUs.
- 1 ... Le dejo usar el equivalente a 1 core al 100%... que en un momento dado pueden ser 
    - 2 cores al 50%
    - 1 core al 50% y 2 cores al 25%
- 1000m = 1 MILICORES
- 200m ~ El equivalente a usar un core al 20% 

 
# Asignación de Pods a nodos

Quién hace ese trabajo?: Scheduler
En base a qué?
- Recursos (requests)
- Afinidades/Antiafinidades
- Toleraciones / Taints

## Podemos dar hints (pistas, indicaciones) que influyan en la decisión de kubernetes (scheduler) acerca de dónde ubicar un pod.

- Afinidad a nivel de host
     ```yaml
    nodeName: NOMBRE DE UN NODO             # Cómo lo veis???   Para cosas hiper concretas (HA)
    nodeSelector:                           # Qué tal?          GUAY. Necesito una máquina con GPU
        ETIQUETAS (Labels)
    affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In            # In, NotIn, Exists, DoesNotExist, Gt and Lt
                values:
                - antarctica-east1
                - antarctica-west1
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1           # A igualdad de condiciones, la opción (NODO) que tenga más puntos gana
            preference:
              matchExpressions:
              - key: another-node-label-key
                operator: In
                values:
                - another-node-label-value
    ```
- Afinidad a nivel de pod

    Quiero que pongas el pod en un nodo que también tenga ya otro pod.

- Antiafinidad a nivel de pod

    Quiero que pongas el pod en un nodo que no tenga ya otro pod.

                    
    MariaDB (app=bd)
    NGINX   (app=webserver)
    
    El mariaDB lo tengo ya en el nodo1... 
    
    Si digo afinidad con nodos 
    
    Despliegue de nginx                                                         NODO 1 (mariadb)          NODO2(nginx)      NODO3
    afinidad con pods que tengan etiqueta app=bd                                    √
    afinidad con pods que tenga etiqueta app != bd                                                          √
    antiafinidad con pods que tengan etiqueta app=bd                                                        √               √
    antiafinidad con pods que tengan etiqueta app != bd                             √                                       √

DE ESTAS TRES REGLAS (afinidad a nivel de nodo, afinidad a nivel de por y antiafinidad a nivel de pod) cuál es la que más usamos?

EN "TODO" DESPLIEGUE USAMOS SIEMPRE ANTIAFINIDAD A NIVEL DE POD, como poco!
Quiero que todo pod genere antiafinidad consigo mismo!
```yaml
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
        topologyKey: topology.kubernetes.io/zone
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: security
              operator: In
              values:
              - S2
          topologyKey: topology.kubernetes.io/zone
```

topologyKey???
CAMBIA EL CONCEPTO:

- Afinidad a nivel de pod

    Quiero que pongas el pod en un nodo que comparta valor de una etiqueta concreta que te doy (TOPOLOGY KEY) con un nodo 
    que también tenga ya otro pod con una etiqueta que cumpla una condición.

- Antiafinidad a nivel de pod

    Quiero que pongas el pod en un nodo  que comparta valor de una etiqueta concreta que te doy (TOPOLOGY KEY) con un nodo
    que no tenga ya otro pod  pod con una etiqueta que cumpla una condición.
    

    Nodo1 (tipo=produccion)

    Nodo2 (tipo=produccion)

    Nodo3 (tipo desarrollo)

    Nodo4 (tipo desarrollo)

    Quiero 2 pods de tipo Agenerando antiafinidad entre si, con topologyKey: tipo
    - Donde se monta el primer pod?
    Se agrupan los nodos por topologyKey:
        produccion: Nodo1 y Nodo2
        desarrollo: Nodo3 y Nodo4

    En que nodos hay un pod de tipo A? En ninguno
    No genero antiafinidad con nadie.. y por ende me valen todos.
        
    Nodo1 (tipo=produccion)
        POD A
    Nodo2 (tipo=produccion)

    Nodo3 (tipo desarrollo)

    Nodo4 (tipo desarrollo)
        
    Segundo POD? 
    En que nodos hay un pod de tipo A? En Nodo1... Pues en ningun nodo de ese grupo (que comparta valor de la topology Key: tipo) se monta mi pod.
    Genero antiafinidad con todos ellos.
    Me valdrían solo el Nodo3 y el Nodo4
        
Kubernetes por defecto mete algunas etiquetas en los nodos... al añadirlos al cluster:
                beta.kubernetes.io/arch=amd64
                beta.kubernetes.io/os=linux
                kubernetes.io/arch=amd64
                kubernetes.io/hostname=ip-172-31-16-45
                kubernetes.io/os=linux
                node-role.kubernetes.io/control-plane=
                node.kubernetes.io/exclude-from-external-load-balancers=
                
kubernetes.io/arch  La arquitectura de microprocesador. Las imagenes de contenedor llevan un programa COMPILADO para un SO / ARQUITECTURA DE MICRO.
No solo existen los procesadores intel y AMD... Si monto un cluster de kubernetes con RASPI! arm

- node.kubernetes.io/exclude-from-external-load-balancers=
    Os imaginais ésta qué hace???  Si el nodo tiene esta etiqueta no se le mandan peticiones desde el balanceador externo

- kubernetes.io/hostname            Nombre del nodo.
  Esta es la que más usamos como topologyKey

No quiero que montes un WEBLOGIC en un NODO que tenga el mismo NOMBRE que otro NODO que tenga ya un WEBLOGIC
Y como el NOMBRE de un nodo es UNICO, solo hay 1 nodo con ese nombre.
    No quiero que montes un WEBLOGIC en un NODO que tenga ya un WEBLOGIC
    
Pregunta!
Hay 2 grandes tipos de usuarios en un cluster de Kubernetes:
- Administrador del cluster, que vela por el buen uso del cluster y su funcionamiento normal
- Gente que instala allí cosas (Desarrollador)

Quién configura las AFINIDADES/ANTIAFINIDADES? Administrador/DESARROLLADOR
El desarrollador es el que define el POD.
El desarrollador es el que sabe que su app necesita GPU
Y el administrador habrá etiquetado ciertos nodos informando que tienen GPU
Y esa información DEBE CIRCULAR!

Esta guay que el desarrollador me pueda decir que su app requiere GPU.
Pero eso evitaría que un app que no requiere GPU se monte en un nodo con GPU?

    Yo desarrollo digo: POD A -> nodo (gpu=true)
    Yo desarrollo digo: POD B -> nodo cualquiera --- Podría acabar es pod en un nodo con GPU? Si
    
Y YO ADMINISTRADOR DEL CLUSTER debo permitir eso? que se haga un mal uso del cluster?
Que una máquina dotata de GPU se use para cosas que no requieran GPU? NO

Y para eso Kubernetes tiene el concepto de los TINTES: Taints

Las afinidades están pensadas para desarrollo, Los tintes están pensados para el Administrador

Yo como administrador, configuro un HOST (NODO) para que SOLO ACEPTE PODS que TOLEREN (tolerancias) un tinte (TAINT)
Realmente lo que hago es marcar el nodo con un tinte.

El desarrollador debe añadir una toleración a ese tinte en su pod.

    $ kubectl taint nodes node1 gpu=true:NoSchedule  ESTO SOLO TIENE PERMISO EL ADMINISTARDOR DEL CLUSTER (igual que poner las etiquetas: LABELS)
    
```yaml 
# Desarrollador
    tolerations:
    - key: "gpu"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
```
Esto hace que se evite por accidente el mal uso (el scheduling de ciertos pods) de los nodos.

Los tintes/toleraciones trabajan en conjunto con las afinidades.
DESARROLLADOR : Yo quiero un nodo con gpu (LABEL) y acepto nodos con tinte GPU=True
ADMINISTRADOR:  Este nodo tiene un tinte GPU=True

---

Con los volumenes pasa igual:
- PV        <       ADMINISTRADOR
- PVC       <       DESARROLLADOR


Con los resources (requests y limits):
- Quien los define en el POD? DESARROLLADOR
- Pero... un ADMINISTRADOR va a permitir que un EQUIPO solocita 300Gbs de RAM? y 50 cores?
    - Si los paga...
      En base a lo que pague le limitaré el número de cores / ram a nivel de SU NAMESPACE 
        RESOURCE QUOTA  \   ADMINISTRADOR
        LIMIT RANGE     /

Igual que un Namespace (en Openshift llamado PROJECT) es un objeto que definen LOS ADMINISTRADORES

Y un SERVICE es un objeto pensado para DESARROLLADOR.
---

# Muchos objetos, al definirse (en su YAML) pueden incorporar ETIQUETAS: LABELS

```yaml
kind: Pod
apiVersion: v1

metadata:
    name: mipod
    labels:
        mietiqueta1: mivalor1
        mietiqueta2: mivalor2
```

Incluso desde linea de comandos podemos poner etiquetas:

$ kubectl label node node17 mietiqueta1=valor1


---

## VOLUMENES en Kubernetes

Cambia un poquito (MUCHO) la cosa con respecto a DOCKER
De entrada en kubernetes hay MUCHOS TIPOS DE VOLUMENES
- No persistentes:
    - Compartir datos entre contenedores:                       emptyDir
    - Inyectar ficheros/configuraciones a un contenedor         configMap   Meter ficheros/carpetas
                                                                secret      Meter ficheros/carpetas de datos sensibles (que requieren de encriptación)
                                                                hostPath    Mater datos del host al contenedor (monitorizar /proc)
- Persistentes
    - Persistir información tras la muerte de un contenedor

PERO... en Kubernetes los volumenes no se definen a nivel de contenedor... sino a nivel de POD
Pero es a nivel de contenedor que se montan en una ruta

En el PVC el desarrololador (negocio) pide lo que necesita (en su lenguaje)
En el PV el administrador registra en kubernetes un volumen que previamente haya sido creado en algún sitio (cabina, nfs, aws)
    con unas determinadas características
    
Y como se liga el PVC y el PV? Eso lo hace kubernetes.. Es el tinder de los volumenes... ES EL QUE HACE MATCH !

Lo que pasa es qauí luego se complica aún más... Nos falta meter el concepto de: PROVISIONADO DINAMICO DE VOLUMENES