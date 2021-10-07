# EKS Cluster provisionning

### Define all variables used to create the cluster stack

```shell
export EKS_STACK_NAME="eks-demo"
export EKS_AWS_REGION="eu-central-1"
export EKS_KEY_PAIR_NAME="my-eks-key"
```

### Create an EKS Key Pair

```shell
aws ec2 create-key-pair \
  --region $EKS_AWS_REGION \
  --key-name $EKS_KEY_PAIR_NAME \
  --tag-specifications 'ResourceType=key-pair,Tags=[{Key=Name,Value=eks-key-pair},{Key=Project,Value=aws-eks}]' \
  --output text \
  --query 'KeyMaterial' > /Users/meb/Data/dbi_services/Cloud/AWS/demo-xchange/cicd-demo/aws-cloudformation/eks.id_rsa
```

### Create the EKS Cluster with the following command

```shell
aws cloudformation create-stack --stack-name $EKS_STACK_NAME \
  --region $EKS_AWS_REGION \
  --template-body file:///Users/meb/Data/dbi_services/Cloud/AWS/demo-xchange/cicd-demo/aws-cloudformation/eks-cloudformation.yaml  \
  --capabilities CAPABILITY_NAMED_IAM
```

### Monitor the cluster creation with the below script

```shell
./eks-creation-status.sh

EKS Cluster status : CREATE IN PROGRESS

EKS Cluster status : CREATE IN PROGRESS

EKS Cluster status : SUCCESSFULLY CREATED

started at : 11:01:24
finished at : 11:21:29
Total time : 0 h 20 min 5 sec
```

### Ensure the EKS Cluster status is ACTIVE :

```shell
aws eks --region $EKS_AWS_REGION describe-cluster \
  --name EKS \
  --query "cluster.status" \
  --output text
```

# EKS cluster testing

### Kubernetes Conf File

```shell
aws eks \
  --region $EKS_AWS_REGION update-kubeconfig \
  --name EKS

Updated context arn:aws:eks:eu-central-1:732156313306:cluster/EKS in /Users/meb/.kube/config
```

### Testing Kubectl

```shell 
kubectl get nodes  
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-0-0-69.eu-central-1.compute.internal    Ready    <none>   3h11m   v1.18.9-eks-d1db3c
ip-10-0-1-174.eu-central-1.compute.internal   Ready    <none>   3h8m    v1.18.9-eks-d1db3c
```

### Application Deployment

We will deploy a pod hosting a simple Node.js web application to validate that our EKS cluster works as expected. Right after that, we will expose this pod thanks to the Kubernetes LoadBalancer service to allow external users access this application.


### Namespace creation

```shell
kubectl create namespace cicd-demo
```

### Deployment creation

```shell
kubectl -n cicd-demo apply -f /Users/meb/Data/dbi_services/Cloud/AWS/demo-xchange/cicd-demo/k8s/deployment/deployment.yaml
```

### LoadBalancer Service creation

```shell
kubectl -n cicd-demo apply -f /Users/meb/Data/dbi_services/Cloud/AWS/demo-xchange/cicd-demo/k8s/deployment/service.yaml
```

Wait a few minutes and test the application in your web browser

```shell
EKS_ELB_HOSTNAME=$(kubectl -n cicd-demo get svc cicd-demo -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') \
&& echo $EKS_ELB_HOSTNAME
```

```shell 
open http://$EKS_ELB_HOSTNAME 
or
curl http://$EKS_ELB_HOSTNAME 
```

# AWS CodeBuild - CodePipeline

### Create CodeBuildKubectl role in IAM (Already Created for the DEMO)
```shell 
./create_iam_role.sh
```

### Map the CodeBuildKubectlRole to the EKS cluster and create RBAC access to do any other action on the cluster
```shell
eksctl create iamidentitymapping --cluster EKS --arn arn:aws:iam::732156313306:role/CodeBuildKubectlRole --group system:masters --username CodeBuildKubectlRole

2021-06-23 15:59:24 [ℹ]  eksctl version 0.53.0
2021-06-23 15:59:24 [ℹ]  using region eu-central-1
2021-06-23 15:59:24 [ℹ]  adding identity "arn:aws:iam::732156313306:role/CodeBuildKubectlRole" to auth ConfigMap
```

### Verify the aws-auth configmap 
```shell
➜  aws-iam git:(master) ✗ kubectl get cm -n kube-system
NAME                                 DATA   AGE
aws-auth                             2      2d4h

➜  aws-iam git:(master) ✗ kubectl edit cm aws-auth -n kube-system
```


### Create a Build Project (UI) by using the previous created role CodeBuildKubectlRole and the following environnements variables: 

```shell
AWS_DEFAULT_REGION=eu-central-1
AWS_CLUSTER_NAME=EKS
AWS_ACCOUNT_ID=732156313306
IMAGE_REPO_NAME=cicd-demo
IMAGE_TAG=latest
```
Enable the privilege flag during the build project creation to elevate priviledges for your build project.<br/>


### CodePipeline
Create a CodePipeline Project using CodeCommit as a source and CodeBuild as a build<br/><br/>

# Resources Destruction

### Define all variables used to delete the cluster stack

```shell
export EKS_STACK_NAME="eks-demo"
export EKS_AWS_REGION="eu-central-1"
export EKS_KEY_PAIR_NAME="my-eks-key"
```

### Get Elastic Load Balancer (ELB) name

```shell
EKS_ELB_NAME=$(echo $EKS_ELB_HOSTNAME | awk -F "-" '{ print $1 }') \
&& echo $EKS_ELB_NAME
```

### ELB deletion

```shell
aws elb delete-load-balancer --region $EKS_AWS_REGION --load-balancer-name $EKS_ELB_NAME
```

### Get Security Group of ELB

```shell
EKS_ELB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --region $EKS_AWS_REGION \
  --filters Name=tag:kubernetes.io/cluster/EKS,Values=owned Name=group-name,Values=k8s-elb-$EKS_ELB_NAME \
  --query "SecurityGroups[*].{Name:GroupId}" \
  --output text) \
&& echo $EKS_ELB_SECURITY_GROUP_ID
```

### ELB Security Groups deletion

```shell
aws ec2 delete-security-group --region $EKS_AWS_REGION --group-id $EKS_ELB_SECURITY_GROUP_ID
```

### EKS cluster deletion with AWS CloudFormation stack

```shell
aws cloudformation delete-stack --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME
```

### Key pair deletion

```shell
aws ec2 delete-key-pair --region $EKS_AWS_REGION --key-name $EKS_KEY_PAIR_NAME
```

### Private key file deletion

```shell
rm -rf /Users/meb/Data/dbi_services/Cloud/AWS/demo-xchange/cicd-demo/aws-cloudformation/eks.id_rsa
```

### Remove IAM Policy

AWSCodePipelineServiceRole-eu-central-1-cicd-demo