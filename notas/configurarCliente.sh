echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt update
sudo apt install -y kubectl

wget https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-07-14-153706-ga/openshift-client-linux-4.5.0-0.okd-2020-07-14-153706-ga.tar.gz
tar -xvf openshift-client-linux-4.5.0-0.okd-2020-07-14-153706-ga.tar.gz
sudo mv oc /usr/local/bin/

mkdir -p ~/.kube
cp config ~/.kube/config 
chmod 600 ~/.kube/config 

kubectl config use-context kubernetes-admin@kubernetes
kubectl get node
oc get node