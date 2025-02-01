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

Use the following command to copy the cluster-a config file:

```
export PUBLIC_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_public_ip')
echo "Public IP for cluster-a: $PUBLIC_IP"

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i cluster-a.pem ubuntu@$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_public_ip"):~/.kube/config ca-config

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i cluster-a.pem ubuntu@$(terraform output -json cluster-a | jq -r ".instance_1_public_ip"):~/.kube/config ca-config

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i cluster-a.pem ubuntu@$(terraform output -json kubernetes_clusters.value["cluster-a"] | jq -r ".instance_1_public_ip"):~/.kube/config ca-config

sed -i "s/127.0.0.1/$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_public_ip')/" config-cluster-a
sed -i "s/default/cluster-a/" config-cluster-a


sed -i "s/127.0.0.1/$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].instance_1_public_ip')/" config-cluster-b
sed -i "s/default/cluster-b/" config-cluster-b


export CLUSTER_A_CONTROL_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].instance_1_private_ip')

export CLUSTER_A_WORKER_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-a"].workers_ip.private_ip[0]')


export CLUSTER_B_CONTROL_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].instance_1_private_ip')

export CLUSTER_B_WORKER_IP=$(terraform output -json | jq -r '.kubernetes_clusters.value["cluster-b"].workers_ip.private_ip[0]')

export KUBECONFIG=$PWD/config-cluster-a:$PWD/config-cluster-b



```
# Clean up
Keep in mind that cloud providers charge you based on the time that you have spent on running resources,at any point you can use `terraform destroy` to completely destroy the project and.

