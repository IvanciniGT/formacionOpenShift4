Para instalar apps en un cluster, tenemos varias opciones... pero al final todas acaban haciendo lo mismo:
CARGAR con un kubectl create -f FICHERO un fichero de manifiesto.

OPCIONES:
1. Crear yo los archivos de manifiesto a mano... Y los cargo.
    DURO... mucho trabajo. PERO en ocasiones no me queda otra: DESARROLLOS CUSTOM
2. Usar kustomize... se usa poco 
    Me permite aplicar variables a ficheros de manifiesto que alguien ha creado.
    Una especie de plantillas... PERO SON MUY POBRES en FLEXIBILIDAD esas plantillas
    Kustomize me permite generar archivos de manifiesto personalizados con mis valores.
    Yo luego aplico esos archivos
3. Usar HELM... se usa MUCHISIMO
    Con helm, los desarrolladores pueden crear CHARTS (plantillas muy potentes y flexibles)
    Crear esas plantillas es complicao. 
        HELM usa un lenguaje de programación llamado MUSTACHE.
        Me tengo que crear archivos de manifiesto a mano.. y luego parametrizarlos y añadirles LOGICA
        con ese lenguaje llamado MUSTACHE
    Usar esas plantillas es MUY SENCILLO. NOS ENCANTA.
    HELM no solo genera los archivos... se encarga de desplegarlos en el cluster. 
    LO HACE TODO !
        Instalar programas
        Desinstalar programas
        Actualizar a nuevas versiones
    De casi cualquier producto comercial, encuaentro un CHART de HELM
4. Operadores - Si los hay, están guay
    Se pocos productos encuentro un OPERADOR
    Redhat ADORA LOS OPERADORES... y en OPENSHIFT me los intentan meter hasta en la sopa!
    Y están guays!
    Los operadores definen CRDs: Nuevos tipos de objetos
    E instalan programas que monitorizan la creación de esos tipos de objeto...
    Y cuando un objeto de ese tipo es creado, ellos generan archivos de manifiesto y los despliegan

    Por ejemplo: Instalo un operador de MariaDB. Al hacerlo puedo crear objetos kubernetes de tipo MARIADB
    ```
    kind: MariaDB
    apiVersion: mariadb/v1 # Operadores
    
    metadata:
        name: mi-mariadb-1
    spec:
        port: 3306
        usuario:
        contyraseña:
        tamañoDeBBDD:
        memoriaRAM:
    ````
    Ese fichero es el que yo aplico
    Al aplicarlo, un programa que instala el OPERADOR se ca cuenta de que he cargado / creado ese objeto.
    Y genera un archivo de manifiesto, definiedo: Deployment, Service, Ingress... y lo aplica.
    
    El operador me permite CAMBIAR EL NIVEL DEL LENGUAJE. Yo ya no hablo de Pods, ConfigMaps, Routes
    Hablo de Una BBDD con 4 Gms de RAM y 40 de HDD
    
# Instalar HELM
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Instalar apps

A helm le pido que haga un despliegue basado en un CHART.
Le daré también:
- un namespace donde hacerlo, 
- un nombre que identifique ese despliegue...
    Eso me permitirá en el futuro ACTUALIZARLO o BORRARLO
- mis configuraciones específicas
    - Se puede pasar por linea de comandos (NO LO HACEMOS NUNCA)
    - Se puede pasar en un fichero YAML (GUAY !!!!!!!)

Lo habitual es tomar un fichero de personalizacion que SIEMPRE OFRENCEN LOS FABRICANTES DEL CHART:
values.yaml

Y lo personalizo con mis cosas.

$ helm install NOMBRE_DE_DESPLIEGUE CHART -f MI_FICHERO_VALUES -n NAMESPACE --create-namespace

# DESINSTALAR

$ helm uninstall NOMBRE_DE_DESPLIEGUE -n NAMESPACE


---

# Como me hago con ese fichero values.yaml que los fabricantes ofrecen por defecto:
1. Buscarlo en su repo de git: TODOS LOS CHART DE HELM los encuentro en GITHUB (comerciales)
        ^ NO LO HACEMOS   
2. Me descargo en chart y copio el archivo = GUAY 

# Pasos:
1. Identificar el CHART (artifacthub.io)
2. Añado el repo donde se encuentra
$ helm repo add UNREPO https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
3. Descargo el chart:
$ helm pull --untar UNREPO/nfs-subdir-external-provisioner
4. Copio el fichero values.yaml y lo tuneo 
5. Instalo:
$ helm install mi-provisionador nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    -f values.yaml -n provisionador --create-namespace