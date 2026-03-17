#!/bin/bash

# Load environment variables from the Vagrant synced folder
source /vagrant/scripts/.env

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.56.110 dmarceliS.42.com dmarceliS
EOF

echo "[TASK 2] Install Curl"
apt update && apt-get install curl -y

echo "[TASK 3] Enable ssh password authentication"
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Set Root password
echo "[TASK 4] Set root password"
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd root
#echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Create user evaluation for passwordless SSH access
echo "[TASK 5] Create user evaluation and configure SSH key"
id -u evaluation &>/dev/null || useradd -m -s /bin/bash evaluation
echo "evaluation ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/evaluation
if [ -n "$SSH_PUB_KEY" ]; then
    mkdir -p /home/evaluation/.ssh
    echo "$SSH_PUB_KEY" > /home/evaluation/.ssh/authorized_keys
    chmod 700 /home/evaluation/.ssh
    chmod 600 /home/evaluation/.ssh/authorized_keys
    chown -R evaluation:evaluation /home/evaluation/.ssh
fi

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc

echo "[TASK 6] Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --tls-san $(hostname) --advertise-address=192.168.56.110  --disable-network-policy --bind-address=192.168.56.110 "\
    K3S_KUBECONFIG_MODE="644" sh -

echo "[TASK 7] Applying apps..."
kubectl apply -f /vagrant/confs/apps/app1.yaml
kubectl apply -f /vagrant/confs/apps/app2.yaml
kubectl apply -f /vagrant/confs/apps/app3.yaml