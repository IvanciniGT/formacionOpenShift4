
# Qué es un Contenedor?

Un entorno aislado dentro de un kernel Linux donde correr procesoS.
Entorno aislado:
- Tiene sus propias variables de entorno
- Tiene su propio FileSystem (sistema de archivos)
- Tiene su propia configuración de red (IP)
- Puede tener limitaciones de acceso a los recursos físicos del host.

Los contenedores no se parecen en nada a las máquinas virtuales. 
El tema es que si sirven para algunos objetivos que también podemos conseguir con máquinas virtuales.

## Despliegue / Instalación de software

### Método tradicional: Instalar software sobre el hierro

        App 1  +  App 2  + App3     
        ------------------------
                SO
        ------------------------
                HIERRO

Problemas:
- Dependencia del SO. Si tengo una App que no se lleva con mi SO.. voy mal!
- Incompatibildiad entre las Apps / Dependencias / Configuraciones con respecto al SO
- App1 tiene un bug (100% CPU)... App1 ---> OFFLINE
                                  App2 y App3 ---> OFFLINE
- Seguridad ---> VIRUS
    - Potencialmente App1 puede acceder a los archivos de App2 y App3
    - App1 podría incluso hacer perrererías grandes... Controla la entrada de teclado.

### Método basado en máquinas virtuales

        App 1   |  App 2  + App3     
        ------------------------
         SO     |    SO
        ------------------------
        MV 1    |    MV2
        ------------------------
            Hipervisor
        VMWare, Citrix, HyperV, 
        KVM, OracleVM, VirtualBox
        ------------------------
                SO
        ------------------------
                HIERRO

Esto resuelve todos los problemas de las instalaciones a hierro.
Pero viene con sus propios problemas:
- Muchas capas nuevas:
    - Más probabilidad de fallo
    - Configuraciones más complejas
    - Mnto se hace más complejo
    - Rendimiento
    - Merma de recursos en el host

### Método basado en contenedores

        App 1   |  App 2  + App3     
        ------------------------
          C1    |    C2
        ------------------------
        Gestor de contenedores:
        Docker, Podman, ContainerD, 
        CRIO
        ------------------------
                SO Linux
        ------------------------
                HIERRO

Las apps (procesos) que corren en un contenedor están en comunicación directa con el
Kernel del HOST.
Esto, me permite enfrentarme a casi todos los problemas que me premitian resolver las MV:
x Dependencia del SO. Si tengo una App que no se lleva con mi SO.. voy mal!
- Incompatibildiad entre las Apps / Dependencias / Configuraciones con respecto al SO
- App1 tiene un bug (100% CPU)... App1 ---> OFFLINE
                                  App2 y App3 ---> OFFLINE
- Seguridad ---> VIRUS
    - Potencialmente App1 puede acceder a los archivos de App2 y App3
    - App1 podría incluso hacer perrererías grandes... Controla la entrada de teclado.

Pero sin los inconvenientes de las MV.

Por ese motivo, hoy en día los contenedores son la forma FAVORITA DE INSTALAR SOFTWARE.
De hecho no tiene sentido instalar software fuera de un contenedor
(al menos el tipo de software del que hablamoos nosotros)

A día de hoy, "todas" las herramientas que montemos en servidor están disponibles para Linux.

Los contenedores los creamos desde IMAGENES DE CONTENEDOR...
Tampoco es algo nuevo... Desde qué creo una Máquina Virtual? Una IMAGEN DE DISCO (SO, SO, con programas por encima)

Lo que pasa es que:
- Las imágenes de contenedor no contienen un SO
- Las imágenes de sistema para MV contienen un SO.. Y eso engorda la imagen que da gusto.

Y además, lo que pasa es que:
- Las imágenes de contenedor siguen un ESTANDAR
- Las imágenes de sistema para MV también...

Las imágenes de contenedor se descargan de un registro de respositorios de imagenes de contenedor.
El más famoso:
- Docker hub
- Quay.io           (REDHAT)
- Microsoft Container Registry
- Oracle container registry
- Amazon me permite montar el mio propio

Una imagen de contenedor es un triste fichero comprimido (tar) que contiene:
- Una serie de programas YA INSTALADOS DE ANTEMANO por alguien.
- Suelen venir instalados en una estrctura de carpetas compatible con POSIX
    etc/
    home/
    bin/
    root/
    var/
    ...
- Algunas preconfiguraciones
- Metadatos:
    - Creador de la imagen
    - Puertos: METADATOS... Para informar al que use la imagen de en qué puerto 
      está PRECONFIGURADO (que yo lo cambiaré si me viene bien) un programa.
      No tiene ningún tipo de fecto funcional.
    - Volumenes

Al descargar esa imagen, se descomprime en mi host.

    HOST:
    /
        etc/
        bin/
        home/
        var/
            lib/
                docker/
                    containers/
                        minginx/
                            var/
                                nginx/
                                    access_log
                    images/
                        nginx/ (1)          chroot
                            etc/
                                nginx/
                                    nginx.conf
                            home/
                            bin/
                                ls
                                bash
                                mkdir
                                cp
                                mv
                                ...
                            root/
                            var/
                            opt/
                                nginx/
                                    nginx

Cuando un proceso aranca basado en esta imagen, lo que se hace es engañar a ese proceso para que crea que la carpeta (1) 
es la raíz del sistema de archivos. (Cosa que ya hacíamos hace 40 años: chroot)

Esa carpeta es de SOLO LECTURA. LAs modificaciones van en otra carpeta asociada al contenedor.
De hecho lo que se presenta al proceso del contenedor como el sistema de archivos es la superposición de esas 2 carpetas.

Al final, en imágenes como:
- Ubuntu
- Fedora
- Alpine

 lo que viene es: La estructura base de carpetas POSIX + 20 comandos básicos de linux:
    /etc
    /bin
        ls
        mkdir
        cp
        sh
Solo que en Ubuntu, además vienen los comandos típicos que encuentro en el SO Ubuntu:
    bash
    apt
    apt-get
Y en la imagen de fedora, los de arriba más 
    bash
    rmp
    yum
    dnf
    
Esas imágenes se usan como BASE sobre la que crear nuevas imágenes.    
---


# Volumenes en contenedores.

## Los contenedores tiene persistencia per se? Sin preconfigurar nada

Y una máquina virtual.. si la borro, tiene persistencia? NO
Y una máquina física... si la borro, tiene persistencia? NO
Y un contenedor, si lo borro, tiene persistencia? NO

Y en cualquiera de ellos, mientras no lo borre, tengo persistencia. SIN PROBLEMA

Dondé esta el lio aquí con los contenedores... El lio viene por otro lado.
Cuántas veces borro una máquina física? NUNCA... Al desmantelar
Cuántas veces borro una máquina virtual? NUNCA... Al desmantelar
Cúantas veces borro un contenedor? Como churros!
    Con contenedores tenemos otra forma de trabajo.. LA FORMA DE TRABAJO HABITUAL CAMBIA!
    
    Si tengo un nginx 1.21.3 montado...    Y ahora quiero un nginx 1.21.4?
    - Si estuviera trabajando con máquinas virtuales / físicas:
        Entro en la máquina y actualizo el nginx
    - Al trabajar con contenedores, tomo el que tengo y lo BORRO
        Y creo uno nuevo con una imagen nueva que lleve la versión que me interese.
        Y eso yo... Cuando luego llegue el kubernetes (openshift and company... esos borran contenedores cada 5 minutos)
    
    Claro... y que pasa con los datos? 
        Si lo que tengo es una BBDD (mysql) ... que va guardando sus ficheros con los datos que cargo en /var/lib/mysql...
        Si borro el contenedor... pierdo los datos.
    
    Lo que hago es tener un volumen de almacenamiento externo al contenedor /Máquina virtual/máquina física:
    - Carpeta NFS
    - iscsi
    - LUN en una cabina conectada por fibra
    - volumen contratado a un cloud
    
    Si tuviera una máquina física y quiero tener los datos fuera en un nfs... qué haría?
    - Configurar un punto de montaje (volumen) en el sistema de archivos de la máquina física apuntando al NFS
        $ mount -t TIPO_QUE_SEA RUTA_VOLUMEN /ruta/local
    Y si es en un contenedor? LO MISMO
    - Configurar un punto de montaje (volumen) en el sistema de archivos del contenedor apuntando al NFS
    
    Solo que queda automatizado... no tengo que entrar a mano a hacerlo.

Para qué sirven los volumenes en los contenedores?
- Persistencia a los datos independiente del ciclo de vida del contenedor
- Compartir datos entre contenedores (con o sin persistencia más allá de la vida del contenedor)
- Añadir capacidad
- Inyectar al contenedor configuraciones (archivos, carpetas)

---

Docker engine son 2 programas:
- Cliente
- Servidor: 
    - ContainerD (parte del código de docker) que posteriormente fue donado a una fundación para su gestión y evolución.


    dcomando "docker" que es un cliente
        VVV
    Docker SERVER - engine
        - login contra un registry
        - publicar imágenes
        - crear imágenes nuevas
        ContainerD
            crear contenedores?
            arrancar un contenedor?
            descargar una imagen?
        Ejecutar un contenedor:
            runc (Hay un proceso runc por cada contenedor que esté ejecutando)
---

## Dependencia del SO....

### Qué es Linux?

Un kernel de SO. De hecho el más usado en el mundo.
Todo SO tiene un kernel (Windows tiene kernel? Kernel NT).

Hay muchos sistemas operativos que usan Linux como Kernel:
- GNU/Linux es un SO... que se ofrece mediante distribuciones adicionalmente:
    - RHEL, Fedora, Oracle Linux
    - Debian > Ubuntu
    - Suse
    - ...
- Android
- ...

### Qué es UNIX?

UNIX era un Sistema Operativo. Hoy en día UNIX son 2 estándares: SUS + POSIX.

A los SO que determinados fabricantes desarrollan cumpliendo con esos estándares les llamamos SO Unix®:
- IBM: AIX (Unix®)
- Oracle: SOLARIS (Unix®)
- HP: HP-UX (Unix®)
- Apple: MacOS (Unix®)


---

## Comunicaciones en el mundo de docker / contenedor

    -+-------------------------------------------------------------------+------ red de amazon
     |                                                              172.31.9.17
    172.31.9.4 NAT (:8888 -> 172.17.0.2:80)                              |
     |                                                                  MenchuPC      curl http://172.17.0.2:80  ?? NO
    HOST (ivanPC)                                                                     curl http://172.31.9.4:8888 ? SI
     | |
     | 172.17.0.1
     | |
     | |-- 172.17.0.2 - Contenedor minginx
     | |                   > nginx [:80]
     | |
     | | red virtual de docker en mi host
     |
     127.0.0.1 (localhost)
     | red de loopback: Red virtual interna en mi host.
                        Sirve para que distintos procesos de mi host puedan comunicarse entre si: Puertos


$ curl http://172.17.0.2:80      ESTO FUNCIONA ya que mi host también está conectado a esa red.

Para exponer los servicios que tengo corriendo en un contenedor, puedo usar NAT. Docker me lo regala:
    docker container create --name minginx -p IP:8888:80 nginx:latest
                                                  ^   ^
                                                  ^   puerto en el contenedor
                                                  ^ 
                                                  puerto en el host
Si no pongo IP, docker usa: 0.0.0.0, es decior, en todas las ips del host abre el puerto 8888 y las peticiones a ese puerto las redirige al contenedor:
Si hiciera esto, Menchu podría acceder al nginx:
    curl http://172.31.9.4:8888
Pero Ivan podría acceder al nginx:
    curl http://172.31.9.4:8888
    curl http://127.0.0.1:8888
    curl http://172.17.0.1:8888

docker container create --name minginx -p 172.31.9.4:8888:80 nginx:latest

Usamos nat:
- Exponer a externos los servicios que tengo en un contenedor
- Poder yo acceder desde mi host al contenedor, sin necesidad de conocer previamente la ip del contenedor:
    - Esto es incomodo: docker container inspect minginx -> IP
    - Tengo garantía de que en el siguiente arranque el contenedor tenga la misma IP? NO
---






# Qué es esto? Kubernetes ( OpenShift: Distribución de kubernetes de Redhat )

No es un gestor de contenedores. 
Orquestador de contenedores? 

Kubernetes es una herramienta que me permite montar entornos de PRODUCCION basados en contenedores.
- VCENTER -> montar entornos de PRODUCCION basado en Máquinas virtuales
  Administración centralizada de hipervisores ESXI + vSAN (cabina)
- Hipervisor esXI... Sirve para montar un entorno de producción? NO DA REDUNDANCIA. Para pro necesito REDUNDANCIA.
  Al menos necesito 2 hipervisores con cierta coordinación


Cluster de Kubernetes:
    Nodo1
        Gestor de contenedoreS: docker, crio, containerd
    Nodo2
        Gestor de contenedoreS: docker, crio, containerd
        nginx
    Nodo3
        Gestor de contenedoreS: docker, crio, containerd
    
Quiero tener desplegado 1 entorno con nginx.. Y se lo digo a kubernetes.
Y kubernetes elige uno de esos nodos, y le pide a SU GESTOR DE CONTENEDORES (el del nodo) que cree un contenedor con el nginx
Y Kubernetes MONITORIZA ese contenedor... Si se cae el host(nodo2), entonces kubernetes le pide a otro nodo que ponga un contenedor con el nginx.

Dicho de otra forma, una de las labores del Kubernetes  (quizás la principal) es gestionar/orquestar gestores de contenedores.

Docker y cualquier otro gestor de contenedores gestionan contenedores de 1 host... Pero con 1 host no hay redundancia / NO PARTY !!!!
 * NOTA: Hay algún engendro por ahí (docker swarm) que intenta hacer cosillas en este sentido.... RUINA !
---

# Despliegue típico de una app en un entorno de producción:

App JAVA + Weblogic (3 weblogic)... que tire de un PostgreSQL

    Nodo1 - ip1
        Weblogic1 - app1    <
    Nodo2 - ip2
        Weblogic2 - app1    <   Balanceador de carga - ipbc    <     Proxy Inverso    <   Proxy        <   clientes (ipbc)
    Nodo3 - ip3
        Weblogic3 - app1    <
        
    Nodo4 - ip4
        PostgreSQL  - vipa  > Volumen externo de almacenamiento de datos (cabina-iscsi) 
    Nodo5 - ip5
        PostgreSQL Pasivo (Espejo)
        
    FIREWALL a nivel de red
        ip1, ip2, ip3 < -- ipbc
        ip1, ip2, ip4 -- > vipa

Esto es lo que monto en Kubernetes:
- Balanceador de carga:                         SERVICE
- Proxy reverso:                                INGRESS CONTROLLER
    Y a ese proxy reverso le pondré reglas      INGRESS
- Reglas de firewall:                           NETWORK POLICY
- Volumen de almacenamiento en mi cabina?       Persiste Volume
- Al enganche (al montaje) de ese volumen para un postgres?   PVC
- Nodo1, nodo3 ?                                POD

---

# POD?

Un pod es un conjunto de contenedores que:
- Comparten configuración de red (IP)... y además... entre ellos pueden hablar mediante: localhost
- Se despliegan en el mismo host:
    - Pueden compartir volumenes de almacenamiento LOCALES!
- Escalan juntos

> Escenario 1: Voy a montar un wordpress con mysql sobre apache

>> 1 contenedor o 2? 2
- Si creo un contenedor único.
    - Necesito una imagen con wordpress/apache y mysql... No la encontraré... Me toca crearle... FOLLON!
    - Y si quiero actualizar un programa? Necesito parar los 2? Vaya tela.
    - Y si uno se vuelve loco.. reinicia todo???
- Siempre programas separados, contenedores separados.

>> 1 pod o 2? 2.
Solo los juntaré en un pod si oblkigatoriamente necesito ponerlos en 1 pod... (en base a las condiciones de arriba)

> Escenario 2: Apache -> access_log apache.log

Esos logs muy probablemente no los quiero en el esos hosts ----> ElasticSearch
Montaré un programita tipo filebeat, fluentd que lea los logs (los archivos de log) y los mande al ES
Los pongo en 1 contenedor o 2? filebeat / apache ---> 2 por definición. DE SERIE
Los pongo en 1 pod o en 2? 1 pod

x Comparten configuración de red (IP)... y además... entre ellos pueden hablar mediante: localhost
√ Se despliegan en el mismo host:
    √ Pueden compartir volumenes de almacenamiento LOCALES! 
        RAM (Apache... le configuras rotada de los entre 2 archivos de 50Kbs
             y que los guarde en una ruta del fs... que apunte a RAM)
√ Escalan juntos

En un kubernetes, nosotros no podemos crear contenedores... Lo que podemos crear son PODS.
Cuántos pods voy a crear yo en un cluster de producción de kubernetes? NINGUNO!
Yo no quiero crear pods en kubernetes. PUEDO HACERLO... pero realmente es un tarea que quiero encomendar a KUBERNETES.

Nosotros lo que crearemos son: PLANTILLAS de PODS. Y que kubernetes cree los pods que hagan falta, basándose en esas plantillas.

Hay 3 formas de crear plantillas en kubernetes:
- Deployment:    Plantilla de pod + Número inicial de pods que quiero de esa plantilla
- Statefulset:   Plantilla de pod + Número inicial de pods que quiero de esa plantilla + Plantilla de PVCs
- Daemonset:     Plantilla de pod, de la que kubernetes crea tantos pods como nodos tenga en la infra
                 Es raro que nosotros hagamos este tipo de despliegues: 
                    - Monitorización
                    - Volumenes



---

# Automatizar

Crear una máquina (o configurar una que exista) para que realice tareas que antes hacíamos los seres humanos
          COMPUTADORA           PROGRAMA
          
LAVADORA: Automatizar el proceso de lavado de ropa.

# DEV-->OPS

Es una cultura, moviento, es una filosofía en pro de la automatización.
Para hacer esas automatizaciones (programas) usamos distintos lenguajes de programación, herramientas...
- Kubernetes: AUTOMATIZAR la operación/gestión/creación de un entorno de PRODUCCION         |
- Ansible:    AUTOMATIZAR la configuración de una infra                                      > Sysadmins
- Terraform:  AUTOMATIZAR la creación/gestión/desmantelamiento de una infra en un cloud     |
- Selenium:   AUTOMATIZAR las pruebas sobre una app web                                      > testers
- Maven:      AUTOMATIZAR el empaquetado/compilación de un proyecto JAVA                     > desarrolladores

Esas automatizaciones luego las tengo que orquestar: Jenkins, Azure Devops...

# La gran gracia de Kubernetes es que nos permite hablar un lenguaje declarativo!

Kubernetes nos permite AUTOMATIZAR la operación/gestión/creación de un entorno de PRODUCCION.
Todas las herramientas que hoy en día triunfan lo hacen por usar lenguajes declarativos:
- Kubernetes
- Ansible
- Terraform
- Angular
- Spring

Llevamos décadas acostumbrados a usar lenguajes IMPERATIVOS a trabajar con computadoras.

- mkdir carpeta         > IMPERATIVO: make directory carpeta
- cd carpeta            > IMPERATIVO: change directory carpeta

No son sino ORDENES que doy a la computadora.
Estamos muy acostumbrados... pero es un desastre.

> Federico, IF (si) hay algo que no sea una silla debajo de la ventana:
    > QUITALO (ORDEN)
> Federico, IF (si) no hay una silla debajo de la ventana (if silla == FALSE)
    > FEDERICO: If no silla , vete al ikea y compras silla
    > Federico, pon una silla debajo de la ventana                              IMPERATIVO

con el lenguaje imperativo me olvido de mi objetivo, centrándome en el proceso necesario para conseguir ese objetivo.

> Federico, debajo de la ventana tiene que haber una silla                      DECLARATIVO

con el lenguaje declarativo delego la responsabilidad de conseguir un ESTADO en un tercero... 
Centrándome en definir el estado que quiero conseguir.

Todas nuestras conversaciones (a primer nivel) con kubernetes son en este sentido.
Vamos a trabajar con ficheros de Manifiesto (YAML), en ellos solo DESCRIBIREMOS lo que quiero.

Será responsabilidad de kubernetes asegurarse que en mi entorno en todo momento tengo lo que quiero tener.

Lo que vamos a hacer es CONFIGURAR EL ESTADO DEL ENTORNO DE PRODUCCION QUE QUEREMOS TENER.
Eso lo hago en ficheros de manifiesto... creando OBJETOS dentro de kubernetes.
Cada objeto contiene la DECLARACION de algo que quiero tener.

Kubernetes por defecto nos permite configurar como 30-40 objetos.
Distribuiciones de kubernetes como Openshift (redhat), Tanzu (VMWare), Karbon (nutanix)... nos ofrecen más objetos que puedo crear.
Incluso con un kubernetes normal (sin vitaminar) también puedo ir instalando en el cluster NUEVOS TIPOS DE OBJETOS que se pueden crear.
Esos tipos de objeto adicionales a los que lleva kubernetes reciben el nombre de: CRD: Custom Resource Definition
- Openshift me da más de 200 CRDs
- Tanzu, otros tantos...

Esas definiciones las metemos en un fichero YAML (archivo de manifiesto).
Y kubernetes las guarda en su BBDD interna (etcd)... y las va aplicando.

Node
Namespace
Pod
Deployment
Statefulset
Daemonset
Service
Ingress
ConfigMap
Secret
Pv
PVC
HPA

NetworkPolicy
ResourceQuota
LimitRange
Job
CronJob
Role
RoleBinding
ClusterRole
ClusterRoleBinding
ServiceAccount
---
Route
User
Project
Machine
MachineSet
MachineAutoScaler







---

# PROXY

Protege al cliente. El cliente no es el que hace una petición a un servidor final.
Se la delega al PROXY... y es el proxy (en su nombre) el que hace la petición.
Desde el punto de vista del servidor final, quién le hace la petición? PROXY
El proxy recibe la respuesta... (la filtra) y la devuelve al cliente.

# PROXY REVERSO

Protege al servidor. El cliente no es el que hace una petición a un servidor final.
Se lo pide al proxy reverso. El proxy reverso es el que internamente hace la petición y la devuelve al cliente.


---

# Características de los entornos de producción

- ALTA DISPONIBILIDAD
    - Más hierros
- ESCALABILIDAD: Eso un problema que los contenedores no resuelven.
    - Más hierro (escalado vertical)
    - Más hierros

Cuál es la forma de enfrentarnos: REDUNDANCIA

---

# nginx 

Es un proxy reverso.