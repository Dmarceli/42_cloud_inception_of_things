#Install k3d
wget  https://github.com/k3d-io/k3d/releases/download/v5.6.0/k3d-linux-amd64
chmod +x k3d-linux-amd64

#Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

./k3d-linux-amd64 cluster create iot  -p "80:80@loadbalancer" -p "8888:8888@loadbalancer" -p "443:443@loadbalancer"

./kubectl create namespace argocd
#./kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
./kubectl apply -n argocd -f ./confs/argo_manifest_latest.yaml
./kubectl apply -f ./confs/argo_in.yaml -n argocd
./kubectl create namespace dev

while true; do
    ./kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 1> /dev/null 2> /dev/null;     
    if [ $? -eq 0 ]; then
        break;
    fi
    echo "Waiting for Argo Startup..."
    sleep 10
done

git clone https://github.com/ncameiri/ncameiri_argocd_sync.git
./kubectl apply -f ./ncameiri_argocd_sync/app-control/test-app.yaml

./kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo


while true; do
  curl -s --head  --request GET -H "Host: app1.com"  http://192.168.56.110/ | grep "404 Not Found"
  if [ $? -eq 1 ]; then
        break;
  fi
  echo "Waiting for Apps to be up..."
  sleep 10
done
echo "All apps are up and running."