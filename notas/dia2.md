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










