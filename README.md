# Demo cluster

Terraform project to delpoy multiple clusters in AWS

# How to

Clone the repository.
```
curl -o terraform.zip https://releases.hashicorp.com/terraform/1.5.6/terraform_1.5.6_linux_amd64.zip && unzip terraform.zip && sudo mv terraform /usr/local/bin/


git clone https://github.com/sorianfr/demo-cluster.git
cd demo-cluster
```

Change the default Calico encapsulation to IPIP

```
sed -i  "s/VXLAN/IPIPCrossSubnet/" files/calico-install.sh
```

Open up `terraform.tfvars` and adjust the variables as you like or add new clusters to the list.

Use the following command to install the require provider:
```
terraform init
```

Use the following command to check the resources that will be populated in your account:
```
terraform plan
```

> Note: At this point resources will be generated in your cloud account.

Use the following command to create the project:
```
terraform apply
```

After the deployment is finished we need to transfer the config file from each cluster to our local computer.

Use the following command to copy the cluster-a and cluster-b config files locally and override localhost with public_ips, and set cluster names:

```
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i cluster-a.pem ubuntu@$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_public_ip'):~/.kube/config ca-config

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i cluster-b.pem ubuntu@$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].instance_1_public_ip'):~/.kube/config cb-config

sed -i "s/127.0.0.1/$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_public_ip')/" ca-config
sed -i "s/default/cluster-a/" ca-config

sed -i "s/127.0.0.1/$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].instance_1_public_ip')/" cb-config
sed -i "s/default/cluster-b/" cb-config
```

```
export CLUSTER_A_CONTROL_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_private_ip')
export CLUSTER_A_WORKER_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].workers_ip.private_ip[0]')

export CLUSTER_B_CONTROL_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].instance_1_private_ip')
export CLUSTER_B_WORKER_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].workers_ip.private_ip[0]')
```


```
export KUBECONFIG=$PWD/ca-config:$PWD/cb-config
```

```
alias kubectl="kubectl --insecure-skip-tls-verify"
```
# BGP Configuration
```
kubectl --context cluster-a create -f -<<EOF
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65001
  listenPort: 179
  nodeToNodeMeshEnabled: false
  serviceClusterIPs:
    - cidr: 10.43.0.0/16
EOF
```

```
kubectl --context cluster-b create -f -<<EOF
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  logSeverityScreen: Info
  asNumber: 65002
  listenPort: 179
  nodeToNodeMeshEnabled: false
  serviceClusterIPs:
    - cidr: 10.53.0.0/16
EOF
```
# BGP Peers
```
kubectl create --context cluster-a -f -<<EOF
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp2clusterb-control
spec:
  peerIP: $CLUSTER_B_CONTROL_IP
  asNumber: 65002
---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp2clusterb-worker
spec:
  peerIP: $CLUSTER_B_WORKER_IP
  asNumber: 65002
EOF
```

```
kubectl create --context cluster-b -f -<<EOF
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp2clustera-control
spec:
  peerIP: $CLUSTER_A_CONTROL_IP
  asNumber: 65001
---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgp2clustera-worker
spec:
  peerIP: $CLUSTER_A_WORKER_IP
  asNumber: 65001
EOF
```

Use the following command to check the BGP status:
```
kubectl --context cluster-a exec -n calico-system ds/calico-node -c calico-node -- birdcl show protocols
```
We store the security group ids for each cluster
```
export SG_CLUSTER_A=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values="Calico Demo cluster-a SG" \
    --query "SecurityGroups[0].GroupId" --output text)

export SG_CLUSTER_B=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values="Calico Demo cluster-b SG" \
    --query "SecurityGroups[0].GroupId" --output text)
```
```
kubectl --context cluster-a exec -n calico-system ds/calico-node -c calico-node -- birdcl show route
```
We create in Cluster A an nginx pod and we expose it as a service
```
kubectl create --context cluster-a deployment nginx --image=nginx
kubectl create --context cluster-a service nodeport nginx --tcp 80:80
```


Authorize 
```
aws ec2 authorize-security-group-ingress \
    --group-id $SG_CLUSTER_A \
    --protocol tcp \
    --port 179 \
    --source-group $SG_CLUSTER_B \
    --region us-east-1

aws ec2 authorize-security-group-ingress \
    --group-id $SG_CLUSTER_B \
    --protocol tcp \
    --port 179 \
    --source-group $SG_CLUSTER_A \
    --region us-east-1
```

```
aws ec2 authorize-security-group-ingress \
    --group-id $SG_CLUSTER_A \
    --protocol 4 \
    --port 0 \
    --source-group $SG_CLUSTER_B \
    --region us-east-1

aws ec2 authorize-security-group-ingress \
    --group-id $SG_CLUSTER_B \
    --protocol 4 \
    --port 0 \
    --source-group $SG_CLUSTER_A \
    --region us-east-1
```

# IPPOOLS
For Cluster A:
```
kubectl --context cluster-a create -f -<<EOF
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: cluster-b-svc-cidr
spec:
  cidr: 10.53.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: false
  disabled: true
---
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: cluster-b-pod-cidr
spec:
  cidr: 10.52.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: false
  disabled: true
EOF
```
For Cluster B:
```
kubectl --context cluster-b create -f -<<EOF
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: cluster-a-svc-cidr
spec:
  cidr: 10.43.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: false
  disabled: true
---
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: cluster-a-pod-cidr
spec:
  cidr: 10.42.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: false
  disabled: true
EOF
```
We patch felixconfiguration with the external nodes.
```
kubectl --context cluster-a patch felixconfiguration default \
    --type='merge' \
    -p '{"spec":{"externalNodesList":["172.16.3.0/24", "172.16.4.0/24"]}}'
```
```
kubectl --context cluster-b patch felixconfiguration default \
    --type='merge' \
    -p '{"spec":{"externalNodesList":["172.16.1.0/24", "172.16.2.0/24"]}}'
```
At this point, curl to pod should work now fron cluster-b but curl to severice it won´t as by default it's set ExternalTrafficPolicy to Cluster. We need to set it to Local
```
kubectl patch service nginx -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```

```
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```
DNS:

if curl nginx from a pod doesnt work (from cluster-a), restart coredns

To restart CoreDNS:

```
kubectl rollout restart deployment coredns -n kube-system
```

aws ec2 authorize-security-group-ingress --group-id $SG_CLUSTER_A \
    --protocol udp --port 53 --cidr 10.43.0.0/16

aws ec2 authorize-security-group-ingress --group-id $SG_CLUSTER_A \
    --protocol tcp --port 53 --cidr 10.43.0.0/16

aws ec2 authorize-security-group-ingress --group-id $SG_CLUSTER_B \
    --protocol udp --port 53 --cidr 10.53.0.0/16

aws ec2 authorize-security-group-ingress --group-id $SG_CLUSTER_B \
    --protocol tcp --port 53 --cidr 10.53.0.0/16


# Clean up
Keep in mind that cloud providers charge you based on the time that you have spent on running resources,at any point you can use `terraform destroy` to completely destroy the project and.

