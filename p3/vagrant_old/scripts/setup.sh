###########################
###########################
#INSTALL - DOCKER
###########################

## Add Docker's official GPG key:

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

##Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo service docker start

###########################
###########################
#FIM - DOCKER INSTALL
###########################



#wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
#ou
wget  https://github.com/k3d-io/k3d/releases/download/v5.6.0/k3d-linux-amd64
chmod +x k3d-linux-amd64

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

#sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

./k3d-linux-amd64 cluster create iot  -p "80:80@loadbalancer" -p "8888:8888@loadbalancer" -p "443:443@loadbalancer"

./kubectl create namespace argocd
#./kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
./kubectl apply -n argocd -f /vagrant/confs/argo_manifest_latest.yaml
./kubectl apply -f /vagrant/confs/argo_in.yaml -n argocd
./kubectl create namespace dev

#while até que exista



while true; do
    ./kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 1> /dev/null 2> /dev/null;     
    if [ $? -eq 0 ]; then
        break;
    fi
    echo "Waiting for Argo Startup..."
    sleep 10
done


git clone https://github.com/ncameiri/ncameiri_argocd_sync.git
./kubectl apply -f /home/vagrant/ncameiri_argocd_sync/app-control/test-app.yaml

./kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo


while true; do
  curl -s --head  --request GET -H "Host: app1.com"  http://192.168.56.110/ | grep "404 Not Found"
  if [ $? -eq 1 ]; then
        break;
  fi
  echo "Waiting for Apps to be up..."
  sleep 10
done