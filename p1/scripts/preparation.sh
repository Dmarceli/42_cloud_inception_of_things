#!/bin/bash

# Load environment variables from the Vagrant synced folder
source /vagrant/scripts/.env

# Update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.56.110 dmarceliS.42.com dmarceliS
192.168.56.111 dmarceliSW.42.com dmarceliSW
EOF

echo "[TASK 2] Install Curl"

while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
echo "Waiting for other apt-get instances to exit"
# Sleep to avoid pegging a CPU core while polling this lock
sleep 1
done

apt update && apt-get install curl -y

echo "[TASK 11] Enable ssh password authentication"
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

# Set Root password
echo "[TASK 12] Set root password"
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd root
#echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
#echo "export TERM=xterm" >> /etc/bashrc

# Create user evaluation for passwordless SSH access
echo "[TASK 13] Create user evaluation and configure SSH key"
id -u evaluation &>/dev/null || useradd -m -s /bin/bash evaluation
echo "evaluation ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/evaluation
if [ -n "$SSH_PUB_KEY" ]; then
    mkdir -p /home/evaluation/.ssh
    echo "$SSH_PUB_KEY" > /home/evaluation/.ssh/authorized_keys
    chmod 700 /home/evaluation/.ssh
    chmod 600 /home/evaluation/.ssh/authorized_keys
    chown -R evaluation:evaluation /home/evaluation/.ssh
fi