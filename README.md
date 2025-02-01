# Demo cluster

Terraform project to delpoy multiple clusters in AWS

# How to

Clone the repository.
```
git clone https://github.com/sorianfr/demo-cluster.git
cd demo-cluster
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

after a successful deployment use the `demo_connection` from the output to ssh into the controlplane.

# Clean up
Keep in mind that cloud providers charge you based on the time that you have spent on running resources,at any point you can use `terraform destroy` to completely destroy the project and.

