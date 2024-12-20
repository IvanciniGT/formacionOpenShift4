# Instalar software dentro de un cluster:

- Crear los yaml .. y oc|kubectl apply
- Helm
    Crear una plantilla (CHART) es complejo.
    - Conocimiento enorme del producto
    - Conocimiento de kubernetes enorme
    - Conocimiento del lenguaje de los chart de helm
    Partimos de la creación unos YAML de manifiesto.. a los que posteriormente les añadimos lógica y parametrización.
- Operador
    Crear un operador es MUCHO MAS COMPLEJO!
    Lo primero es definir unos YAML! que no son de Kubernetes...
        Si no de NUEVOS TIPOS DE OBJETO QUE YO ME INVENTO -> CRDs
        ```yaml
            kind:           BaseDatosMariaDB
            apiVersion:     miOperador/v1
            
            metadata:
                name:       miBD
                ...
            spec:
                LO QUE PONGO AQUI LO INVENTO YO
        ````
    Acto seguido he de montar un programa que lea eso (ese YAML) y desde ese YAML
        genere archivos de manifiesto en AUTOMATICO de KUBERNETES.
    Y ese programa debe ponerse en COMUNICACION con KUBERNETES (ApiServer)
    para ir creando las cosas (aplicar esos yaml)

    Como resultado, hay pocos operadores, comparados con CHARTS de HELM
    
    La gente de REDHAT me da un montón de OPERADORES en Openshift
---

# Openshift:

Es la distro de Kubernetes de Redhat.

Qué viene aquí:
- Paquete cerrado de utilidades QUE AL FINAL SIEMPRE MONTAMOS EN UN CLUSTER.
- Cuando tengo una instalación de Kubernetes en vacío: 10 pods en el control plane
- Una instalación de Openshift... nuevita.. sin tocar: + 200 pods
    - IngressController
    - Configuración automatizada de DNS
    - Gestor de Certificados
    - Provisionadores de volumenes
    - Sistema de recopilación de métricas
    - Sistema de Monitorización
    - Driver de RED
    - Dashboard gráfico
        - Integración con Operadores
    - Registro de imágenes de contenedor
    - ....

## Operadores

Se suelen instalar mediante un YAML (chart-helm).
    Una gracia de los operadores es que son programas que no están pensados para usuarios.
    Son programas que quedan corriendo en el cluster, monitorizando objetos (CRDs) que se van 
    creando/modificando/elimiando en el cluster.
    Esto implica que BASICAMENTE NO REQUIEREN PERSONALIZACION.
    - No doy mis puertos
    - Ni contraseñas
    - Ni variables de entorno
    - Ni rutas, ingress
    - Networkpolicies
    - Recursos de RAM/CPU
Y me dan esos CRDs.

No hago un despliegue de Ansible Tower, o de un ElasticSearch.
Despliego un programa que ese programa despliega Ansible Tower o ElasticSearch... 1 o 500.
Lo que hago yo (HUMANO) es configurar despliegues (pero no en lenguaje DECLARATIVO KUBERNETES)
sino en lenguage DECLARATIVO específico de ESA APP.

# Route de Openshift

Ingress + Configuración automatica de un DNS Externo + Gestión automatizada de certificados SSL

    Service Nodeport = Service ClusterIP + Exposición de puertos a nivel del host
    Service LoadBalancer = Service NodePort + Configuración automática de un Balanceador externo
    
                    Regla en NETFILTER                  Regla en NETFILTER                    REGLA (METALLB)
                        v                                       v                               v 
    Pod Apache IP < Service IP < Pod IngressController IP < Service (LB) IP Interna < Balanceador externo IP Pública    < Cliente
           ^                               ^                              < balancea entre NODOS <
        APACHE                      NGINX / HAPROXY
        
        
        APACHE < http(s) < NGINX < http(s) < NAVEGADOR cliente
        
# CERTIFICADOS y TLS

## Qué hay que securizar?
    CLIENTE > NGINX (PROXY REVERSO-INGRESS CONTROLLER)
    NGINX   > APACHE

TODAS !!!!!
Lo más básico es sólo: EDGE
                                        DENTRO DEL CLUSTER
                      --------------------------------------------------------
    CLIENTE > https > NGINX (PROXY REVERSO-INGRESS CONTROLLER) > http > APACHE
                        Certificado (clave pública)
                        Clave privada
                        

Pero lo suyo es     RE-ENCRYPT
                                        DENTRO DEL CLUSTER
                      --------------------------------------------------------
    CLIENTE > https > NGINX (PROXY REVERSO-INGRESS CONTROLLER) > https > APACHE
                        Certificado (clave pública, CA1)                 Certificado (clave pública, CA2)
                        Clave privada                                    Clave privada                        
      CA1               CA2                        
      

O esto otro:            PASSTHRU
                                        DENTRO DEL CLUSTER
                      --------------------------------------------------------
    CLIENTE > https > NGINX (PROXY REVERSO-INGRESS CONTROLLER) > https > APACHE
                        PassThru                                         Certificado (clave pública, CA1)
                                                                         Clave privada                        
      CA1
      
Eso es lo que configuro en una ruta... OJO... la ruta configura la parte del INGRESS-CONTROLLER.
    No entra en el APACHE.. es decir,
    El certificado del Apache, le pongo YO
    La clave privada del Apache, la pongo yo

Yo os conté el otro día algo para ayudarnos por su lado con el certificado del APACHE? ISTIO
    
                                        DENTRO DEL CLUSTER                          INTERNA EN EL POD
                      --------------------------------------------------------      (localhost)
    CLIENTE > https > NGINX (PROXY REVERSO-INGRESS CONTROLLER) > https > ENVOY      > http >        APACHE
                        Certificado (clave pública, CA1)                 Certificado (clave pública, CA2)
                        Clave privada                                    Clave privada                        
      CA1               CA2                                                 ^
                         ^                                                  Los genera istio
                         La genera istio
    
Los certificados del INGRESS-CONTROLLER me puedo servir del CERTMANAGER que los genere con una CA pública tipo let's encrypt
            
---

# Soy desarrollador de FRONTALES WEB

Angular, React, vueJs
    ---> .html + .js + .css ----> Web Server (Apache, nginx)
    
    
---

# Weblogic , Websphere  -  OBSOLETAS!

JEE -> 2 tipos de app servers: Clase Enterprise (EJB) , Clase WEB

Tenía sentido en sistemas MONOLITICOS GIGANTES

Antiguamente todo el HTML que recibía un cliente en su navegador se generaba en el SERVIDOR:
    - JSP, JFCs
    - ASP
    - PHP

Hoy en día el HTML se genera dentro del NAVEGADOR por programas JS.
El servidor manda JSON y programas JS en el navegador toman ese JSON y lo convierten a HTML

---
Una evolución que está habiendo: Server side rendering... Y que el HTML se vuelva a generar en Servidor... pero como fuera Navegador
    NODE
    
web-ejemplo-ansible.ivancinigt-dev.svc.cluster.local

Si estoy dentro del mismo ns/proyecto, puedo usar como fqdn:                    web-ejemplo-ansible
Si estoy en otro ns/proyecto, puedo usar como fqdn:                             web-ejemplo-ansible.ivancinigt-dev
    
---

# BASE DE DATOS

Antiguamente un desarrollador, pedía una BBDD a la gente de BBDD (Sistemas). DBA.

El desarrollador montaba un Script SQL para CREAR LA TABLAS.
    Hoy en día los desarrolladores ni saben SQL: HIBERNATE - ORM
        Eso permite a una app, al conectarse la primera vez con la BBDD crear todas las tablas que son necesarias...
        Incluso MANTENERLAS (Cambios)

JAVA. En un lenguaje que hace uso PESIMO de la RAM < FEATURE
Es parte de los puntos clave de diseño del lenguaje.
    Los desarrolladores se olvidan de la gestión de la RAM
    ```java
        String texto = "HOLA";          HOLA se guarda en algún sitio de RAM
        texto = "ADIOS";                ADIOS se guarda en otro sitio!
    ```
    
    Hacerlo con C  = 1000 horas de desarrollador a 60€/hora 60.000
    Hacerlo con J  = 700 horas de desarrollador a 50€/hora  35.000
                                                    ---------------
                                                            25.000
        
No quiero ya administrador de sistemas.. ni dba.
Yo hoy en día lo que hago es CONTRATAR UNA BBDD a Azure, AWS.. y que me den administración: Actualizaciones/Levantarla, instalarla, BACKUPS.
Evidentemente esa BBDD no va a ir igual de fina que si la administra un DBA.
Le pido al cloud más máquina!
Por qué: AL FINAL SALE MAS BARATO !

NETFLIX -> MICROSERVICIOS!
            UPS PROBLEMON VA LENTO DE COJONES MONITORIZACION -> MONOLITO ON PREM.

---

# Seguridad en Openshift

Una de las cosas donde más hincapie se hace en Openshift es en el tema de la seguridad!
Se monta sobre RHEL... y llevo SELINUX

Hay un tema muy complejo con Openshift:
- El 90% de las imágenes de contenedor que encuentro en Docker hub NO SON APTAS PARA OPENSHIFT

Openshift por defecto no admite contenedores que trabajen con usuario ROOT.
Se puede desbloquear... pero no es la idea.

Al final necesito tirar de imágenes que tenga claro que van a funcionar en Openshift.

# Instalación de Openshift

Esto no es un kubernetes normal.
Un cluster mínumo de Kubernetes lo puedo tener con un nodo.
Openshift agarrate: 
- 3 maestros: etcd - BRAINSPLIT
    Al menos necesito 3 instancias de etcd para HA.. no valen 2.
    De las 3, solo una es maestra del cluster de etcd, pero es elegida por votación popular.
- Nodos de infra: 
    Monitorización / recopilación de metricas   
- Workers:
    - Despliegues

Esto se puede instalar:
- On prem
- Cloud
    - AWS
    - Azure

---

# Escalado

Yo puedo escalar pods mientras tenga recursos FISICOS.
Y cuando se acaben? NECESITO MAQUINAS.
Esas máquinas de donde las saco? Y cómo las preparo?
    TERRAFORM                       ANSIBLE

En Openshift puedo definir ESCALADORES DE MAQUINAS !

---

    App1 
        Minutos n           100 usuarios
        Dia n+1     1000000 usuarios        
        Dia n+2       10000 usuarios
        Dia n+3     20000000 usuarios Madrid / Barça

    Web telepi
---

TANZU: Kubernetes de VMWare

---

# Muchas veces estos cluster los montamos a su vez sobre infras VIRTUALIZADAS.

1 maestro - 7 workers
    ^
    VM de VMWare
    Datos están en una cabina
    
    El que se caiga el maestro no implica que las apps no funcionen.. Las apps siguen arriba.
    Lo que pierdes es la capacidad de gestionarlas... 5 minutos
    
---

En Openshift existe el concepto de USER (Usuario) como extensión del ServiceAccount.
Aporta validación de la identidad (AUTENTICACION) mediante:
- Contraseñas
- Sistemas de doble autenticación

Lo que se define en Openshift (web REDHAT): son proveedores de identidad:
htpasswd: Es una BBDD interna de OS de usuarios:
    - Básicamente la limito al usuario ADMINISTRADOR DEL CLUSTER
Me sirve de salvaguarda... Si se caen los Proveedores de identidad, al menos tengo un usuario con el que acceder al cluster.
Pero habitualmente el resto de usuarios los defino por otro lado:
- LDAP
- Servidores IAM: OpenID
    - Github
    - Keycloak
---

Fedora ---> RHEL
KeyCloak ---> RH Keycloak
AWX ---> Ansible Tower (Ansible Automation Platform)
Wildfly ---> JBOSS

# Openshift se basa (proyecto UPSTREAM) OKD.

OKD ---> Openshift
minishift
