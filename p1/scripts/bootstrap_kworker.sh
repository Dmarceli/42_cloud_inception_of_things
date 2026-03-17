#!/bin/bash

# Load environment variables from the Vagrant synced folder
source /vagrant/scripts/.env

echo "[TASK 1] Join node to Kubernetes Cluster"

while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done

apt-get  install -y sshpass 

# Label the node as a worker


#get join script from master 
sshpass -p "${ROOT_PASSWORD}" scp -o StrictHostKeyChecking=no root@dmarcelis.42.com:/home/vagrant/joincluster.sh .
mkdir -p /etc/rancher/k3s
sshpass -p "${ROOT_PASSWORD}" scp -o StrictHostKeyChecking=no root@dmarcelis.42.com:/etc/rancher/k3s/k3s.yaml /etc/rancher/k3s/k3s.yaml
bash joincluster.sh 
sed -i 's/127.0.0.1/192.168.56.110/' /etc/rancher/k3s/k3s.yaml
kubectl label node "$(hostname | tr '[:upper:]' '[:lower:]')" node-role.kubernetes.io/worker=true
echo "Cluster Joined!"