
# Kubectl es el cliente de Kubernetes
# oc es el cliente de Openshift

kubectl VERBO TIPO_DE_OBJETO NOMBRE_DE_OBJETO -n NAMESPACE args-adicionales

TIPO_OBJETO:
- Node
- Pod
- Deployment
- ConfigMap
- Statefulset
- Persistenvolume       pv
- Service               svc

VERBO: Depende del tipo de objeto
- GET
- WATCH (como el GET, pero deja la terminal trincada.. monitorizando)
- DELETE
- DESCRIBE
- EDIT                      # PROHIBIDO !
- LOGS  POD
- EXEC  POD     -c NOMBRE_CONTENEDOR

Hay también comandos que trabajan sobre ficheros:
- kubectl create -f FICHERO -n NAMESPACE    # Crea todos los recursos definidos en el fichero
- kubectl apply  -f FICHERO -n NAMESPACE    # Crea todos los recursos definidos en el fichero si no existen
                                            # Y si existen TRATA de editarlos.. no siempre es posible
- kubectl delete -f FICHERO -n NAMESPACE    # Borra todos los recursos definidos en el fichero



# Con respecto al -n NAMESPACE

Si no pongo -n NAMESPACE se toma por defecto el namespace llamado "default"
Puedo poner también --all-namespaces en según qué comandos:
    kubectl get pods --all-namespaces
