k3d cluster create iot  -p "80:80@loadbalancer" -p "8888:8888@loadbalancer" -p "443:443@loadbalancer"

until [ ! -z $K3D_IP ]; do K3D_IP=$(kubectl get svc -A | grep traefik | tr " " "\n" | grep "172."); done 2>/dev/null

#helm upgrade --install gitlab gitlab-7.4.1/gitlab    --set global.hosts.domain=ncameiri.42.com   --set global.hosts.externalIP=$K3D_IP   --set postgresql.image.tag=13.6.0     --set certmanager-issuer.email=me@example.com --set gitlab-runner.install=false  --set nginx-ingress.enabled=false 

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=ncameiri.42.com \
  --set global.hosts.externalIP=$K3D_IP \
  --set certmanager-issuer.email=me@example.com \
  --set gitlab-runner.install=false \
  --set nginx-ingress.enabled=false 

kubectl patch ing gitlab-webservice-default -p '{"spec": {"ingressClassName": "traefik"}}'

#kubectl patch ing gitlab-webservice-default -p '{"spec": {"tls": [{"hosts":["'"$K3D_IP"'"], "secretName": "gitlab-gitlab-tls"}]}}'

#kubectl  patch ing gitlab-webservice-default -p '{"spec":{"rules":[{"host":"","http":{"paths":[{"backend":{"service":{ "name":"gitlab-webservice-default","port":{"number":8181 }}},"path": "/", "pathType": "Prefix"}]}}]}}'  

git config --global http.sslVerify "false"
kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f /vagrant/confs/argo_manifest_latest.yaml
kubectl apply -f ../p3/argo_in.yaml -n argocd 

echo "\033[0;35mYour ARGO CD Login, DONT SHARE THIS WITH ANYONE\n\tlogin: admin\n\tpassword:  "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d); echo "\033[0m"

echo "\033[0;32mYour GitLAB Login, DONT SHARE THIS WITH ANYONE\n\tlogin: root\n\tpassword:  "$(kubectl  get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d); echo "\033[0m"

echo "\033[0;31mAdd this to your /etc/hosts:\n\t$K3D_IP\tgitlab.ncameiri.42\n\t$K3D_IP\targo-cd-42.ncameiri\033[0m"


sudo snap install glab 


glab config set skip_tls_verify true --host gitlab.ncameiri.42.com
glab auth login --hostname gitlab.ncameiri.42.com --token 

export GITLAB_HOST=gitlab.ncameiri.42.com
export GITLAB_TOKEN=