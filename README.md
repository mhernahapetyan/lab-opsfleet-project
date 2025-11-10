🚀 EKS + Karpenter Terraform Infrastructure

This repository provisions a fully managed AWS EKS cluster with Karpenter autoscaling, supporting both x86 and ARM (Graviton) workloads.

It uses Terraform v1.9.8 and AWS native resources to build a scalable, multi-architecture Kubernetes environment.

⚙️ Terraform Version

Requires Terraform v1.9.8

Make sure your local CLI or CI/CD runner matches this version:

terraform version

🧩 Prerequisites

Before applying Terraform, you must create:

An S3 bucket (for storing Terraform state)

A DynamoDB table (for state locking)

You can create them via the AWS CLI:

# Variables
export AWS_REGION=eu-central-1
export BUCKET_NAME=my-eks-terraform-state
export DYNAMODB_TABLE=my-eks-terraform-locks

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Enable versioning for safety
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for Terraform state locking
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST


Then update your backend configuration (in backend.tf):

terraform {
  backend "s3" {
    bucket         = "my-eks-terraform-state"
    key            = "env-name/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "my-eks-terraform-locks"
    encrypt        = true
  }
}

🚀 How to Deploy

Navigate to your environment folder

cd environments/dev


(replace dev with your environment name — e.g., staging, prod)

Initialize Terraform

terraform init


Preview changes

terraform plan


Apply infrastructure

terraform apply


This will:

Create the EKS cluster

Configure managed system node groups

Deploy Karpenter for autoscaling

Provision EC2NodeClasses for both x86 and ARM64 architectures

☸️ Using the Cluster

After Terraform finishes, configure your kubeconfig:

aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-dev


Verify cluster access:

kubectl get nodes
kubectl get pods -A


You should see system nodes and Karpenter pods running.

🧬 Running Workloads on x86 or Graviton

Karpenter dynamically launches the right EC2 instances based on your pod’s architecture selector.

Run a Pod on x86 (amd64)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-x86
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-x86
  template:
    metadata:
      labels:
        app: demo-x86
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
EOF


Karpenter will automatically launch an x86 node (EC2NodeClass -x86) if needed.

Run a Pod on Graviton (ARM64)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-arm64
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-arm64
  template:
    metadata:
      labels:
        app: demo-arm64
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
EOF


Karpenter will detect the arm64 selector and spin up a Graviton instance automatically.

🧹 Cleanup

To destroy all resources when done:

terraform destroy


This will delete:

The EKS cluster

Karpenter resources

NodeGroups and security groups

IAM roles and profiles created by this setup

📘 Summary
Component	Description
EKS Cluster	Managed Kubernetes control plane
Karpenter	Dynamic autoscaler for multi-arch workloads
NodeClasses	EC2 instance definitions (x86 / ARM64)
NodePools	Scheduling logic for workloads
Terraform Backend	S3 + DynamoDB for remote state and locking
🧠 Tips for Developers

To deploy your own apps, create manifests under k8s/ and apply them using kubectl apply -f.

To test Karpenter scaling, deploy multiple replicas and observe node provisioning:

kubectl scale deployment demo-x86 --replicas=10
watch kubectl get nodes


You can use kubectl port-forward to access your pod locally:

kubectl port-forward deployment/demo-x86 8080:80