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

