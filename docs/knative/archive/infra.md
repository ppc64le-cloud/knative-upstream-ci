#  Infra Setup For Knative Community

### VM Details

All below vms are created in `rdr-ghatwala-tekton-knativeCI-PROD-Tok04` PowerVS in `2046434 - IBM Ecosystem CICD` IBM Cloud account.
The bastion vm has public ip, rest all vms are part of private network `knative-tekton-private-network` and access internet via bastion using SNAT.

|Name|OS|CPU|Ram|Disk|Public IP|Private IP|Network Subnet|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|k8s-7b88a7-bastion-1|CentOS-Stream-8|0.5|16|120|128.168.101.149|192.168.187.149, 192.168.25.52|k8s-f1c4bc-public-network, knative-tekton-private-network|
|k8s-7b88a7-master-1|CentOS-Stream-8|0.5|16|120|-|192.168.25.19|knative-tekton-private-network|
|k8s-7b88a7-worker-1|CentOS-Stream-8|1|16|120|-|192.168.25.157|knative-tekton-private-network|
|k8s-7b88a7-worker-2|CentOS-Stream-8|1|16|120|-|192.168.25.227|knative-tekton-private-network|
|k8s-4d853a-bastion-1|CentOS-Stream-8|0.5|16|120|128.168.101.125|192.168.25.138, 192.168.187.125|k8s-4d853a-public-network, knative-tekton-private-network|
|k8s-4d853a-master-1|CentOS-Stream-8|0.5|16|120|-|192.168.25.210|knative-tekton-private-network|
|k8s-4d853a-worker-1|CentOS-Stream-8|1|16|120|-|192.168.25.60|knative-tekton-private-network|
|k8s-4d853a-worker-2|CentOS-Stream-8|1|15|120|-|192.168.25.74|knative-tekton-private-network|

### Deploy VMs

```bash
ibmcloud pi sl
ibmcloud pi st <CRN for rdr-ghatwala-tekton-knativeCI-PROD-Tok04>
```

Latest images can be imported into PowerVS using [PowerVS-latest-Images](https://github.ibm.com/redstack-power/docs/wiki/PowerVS-latest-Images) wiki.

```bash
ibmcloud pi instance-create knative-bastion-siddhesh-ghadi --image "rhel-85-12132021" --memory 16 --network "tekton-pub-network 192.168.143.244" --network "ocp-net 192.168.25.200" --processors 0.5 --processor-type shared --key-name knative-ssh --sys-type s922 --storage-type tier1

ibmcloud pi instance-create knative-master-siddhesh-ghadi --image "rhel-85-12132021" --memory 16 --network "ocp-net 192.168.25.201" --processors 0.5 --processor-type shared --key-name knative-ssh --sys-type s922 --storage-type tier1

ibmcloud pi instance-create knative-worker1-siddhesh-ghadi --image "rhel-85-12132021" --memory 24 --network "ocp-net 192.168.25.202" --processors 0.75 --processor-type shared --key-name knative-ssh --sys-type s922 --storage-type tier1

ibmcloud pi instance-create knative-worker2-siddhesh-ghadi --image "rhel-85-12132021" --memory 24 --network "ocp-net 192.168.25.203" --processors 0.75 --processor-type shared --key-name knative-ssh --sys-type s922 --storage-type tier1
```

### Setup Bastion

- Change hostname

  ```bash
  hostname
  hostnamectl set-hostname knative-bastion
  hostname
  ```

- Use public DNS  
  ```bash
  echo 'nameserver 8.8.8.8
  nameserver 9.9.9.9' > /etc/resolv.conf
  ```

- Disable password ssh login
  
  ```bash
  #sed -i 's/^PermitRootLogin yes$/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i 's/^ChallengeResponseAuthentication yes$/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
  sed -i 's/^PasswordAuthentication yes$/PasswordAuthentication no/g' /etc/ssh/sshd_config
  systemctl reload sshd
  ```

- Setup fail to ban

  ```bash
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  yum install fail2ban -y
  
  echo '[DEFAULT]
  ignoreip = 
  # "bantime" is the number of seconds that a host is banned.
  bantime = 3600
  # A host is banned if it has generated "maxretry" during the last "findtime"
  # seconds.
  findtime = 600
  # "maxretry" is the number of failures before a host get banned.
  maxretry = 5
  banaction = iptables-multiport
  backend = systemd
  
  [sshd]
  enabled = true'>/etc/fail2ban/jail.local
  
  systemctl enable fail2ban
  systemctl start fail2ban
  
  # view status
  #fail2ban-client status sshd
  
  # unblock a ip
  #fail2ban-client set sshd unbanip <IP>
  ```

- Setup firewall

  ```bash
  yum install firewalld -y
  
  systemctl enable firewalld.service
  systemctl start firewalld.service
  
  ## move internal ips to trusted zone for proper k8s/nfs functioning
  firewall-cmd --permanent --zone=trusted --add-source=192.168.25.0/24  #private subnet
  firewall-cmd --permanent --zone=trusted --add-source=10.96.0.0/12
  firewall-cmd --permanent --zone=trusted --add-source=172.20.0.0/16
  firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/24
  firewall-cmd --add-masquerade --permanent
  systemctl restart firewalld
  
  # on bastion
  ## unblock 992(kubeapi) & 443(private registry) ports for public access
  firewall-cmd --permanent --add-port=992/tcp
  firewall-cmd --permanent --add-port=443/tcp
  systemctl restart firewalld

  firewall-cmd --list-all
  ```

- Allow 992 & 80 port in selinux 

  <!-- TODO
  Add fix(https://stackoverflow.com/a/39971725) in automation to resolve  
  "nginx: [emerg] bind() to 0.0.0.0:992 failed (13: Permission denied)"

  Add fix(https://stackoverflow.com/a/24830777) for 
  "connect() to 192.168.25.200:80 failed (13: Permission denied) while connecting to upstream"
  -->

  ```bash
  semanage port -a -t http_port_t  -p tcp 992
  setsebool -P httpd_can_network_connect 1
  ```

- Setup ssh access

  <!--TODO: Move secrets to a share box/sharepoint location-->
  `knative-ssh` private key can be found in GCP secret manager or ask Siddhesh Ghadi or Md.afsan Hossain.

  ```bash
  # Copy the knative-ssh private key to $HOME/.ssh/id_rsa
  chmod 600 $HOME/.ssh/id_rsa
  ```

- Install ansible

  ```bash
  yum install python3 python3-pip
  pip3 install ansible
  ```

- Reboot

  ```bash
  reboot
  ```

- Setup automation

  Refer [Setup automation](../README.md#setup-automation) steps in project README.

### Setup Cluster Nodes

Run below on all master & worker nodes. Ensure that the k8s automation is triggered atleast once before running below steps so that snat is configured for internet access. 

- Change hostname

  ```bash
  hostname
  hostnamectl set-hostname <UPDATE ME: knative-master, knative-worker1, knative-worker2>
  hostname
  ```

- Use public DNS  

  ```bash
  echo 'nameserver 8.8.8.8
  nameserver 9.9.9.9' > /etc/resolv.conf
  ```

- Disable password ssh login 
  
  ```bash
  #sed -i 's/^PermitRootLogin yes$/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i 's/^ChallengeResponseAuthentication yes$/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
  sed -i 's/^PasswordAuthentication yes$/PasswordAuthentication no/g' /etc/ssh/sshd_config
  systemctl reload sshd
  ```

- Setup fail to ban

  ```bash
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  yum install fail2ban -y
  
  echo '[DEFAULT]
  ignoreip = 
  # "bantime" is the number of seconds that a host is banned.
  bantime = 3600
  # A host is banned if it has generated "maxretry" during the last "findtime"
  # seconds.
  findtime = 600
  # "maxretry" is the number of failures before a host get banned.
  maxretry = 5
  banaction = iptables-multiport
  backend = systemd
  
  [sshd]
  enabled = true'>/etc/fail2ban/jail.local
  
  systemctl enable fail2ban
  systemctl start fail2ban
  
  # view status
  #fail2ban-client status sshd
  
  # unblock a ip
  #fail2ban-client set sshd unbanip <IP>
  ```

- Setup firewall

  ```bash
  yum install firewalld -y
  
  systemctl enable firewalld.service
  systemctl start firewalld.service
  
  ## move internal ips to trusted zone for proper k8s/nfs functioning
  firewall-cmd --permanent --zone=trusted --add-source=192.168.25.0/24  #private subnet
  firewall-cmd --permanent --zone=trusted --add-source=10.96.0.0/12
  firewall-cmd --permanent --zone=trusted --add-source=172.20.0.0/16
  firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/24
  firewall-cmd --add-masquerade --permanent
  systemctl restart firewalld
  
  firewall-cmd --list-all
  ```

- Reboot

  ```bash
  reboot
  ```

### Test The Environment

Refer testing [doc](../docs/testing.md#generate-prowjobs-with-mkpj-for-local-testing).

### Details to update in GCP secret

Refer GCP [doc](../gcp-secrets/README.md) for adding/updating secrets in GCP secret manager service.