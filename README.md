# Telex Application Deployment using Helm, ArgoCD, and Terraform on AWS EKS

This repository demonstrates the deployment of the Telex application using **Helm**, **ArgoCD**, and **Terraform on AWS EKS**. This project showcases my learning and practical experience in deploying Kubernetes applications with advanced tooling for **continuous delivery and infrastructure as code (IaC)**.

## Project Overview

In this project, I:
1. Installed **Helm** locally for managing Kubernetes resources (for ArgoCD installation).
2. Configured infrastructure using **Terraform** to set up an **EKS** cluster on AWS.
3. Installed and configured **ArgoCD** for continuous delivery on the Kubernetes cluster.
4. Deployed the **Telex application** by setting up ArgoCD via its web interface.
5. Integrated Helm and ArgoCD into the CI/CD pipeline.
6. Implemented AWS STS AssumeRole for secure access management.

## Prerequisites

To reproduce or follow the steps in this guide, you'll need:

- **Helm** (v3.0+) - for installing ArgoCD.
- **Terraform** (v1.0+) - for AWS EKS setup.
- **AWS CLI** (v2.0+) - for managing AWS resources.
- **kubectl** (v1.19+) - for interacting with Kubernetes.
- **Git** - for version control.
- **ArgoCD** (installed on the EKS cluster).

An AWS account is also required to create and manage the EKS cluster, VPC, IAM roles, and other related infrastructure.

## Step-by-Step Process

### 1. Installing Helm Locally

Helm is a package manager for Kubernetes. Even though I didn't create a Helm chart for the Telex app, I used Helm to install ArgoCD into the Kubernetes cluster.

Install Helm:

```bash
# For MacOS/Linux
brew install helm

# For Windows
choco install kubernetes-helm
```

Verify the installation:

```bash
helm version
```

### 2. Setting Up AWS EKS Infrastructure using Terraform

Using **Terraform**, I provisioned an AWS EKS cluster along with its supporting infrastructure (such as VPC, subnets, IAM roles, and security groups).

Here’s a simplified example of the Terraform configuration for the EKS cluster:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "1.24"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa     = true
}

```

After defining the configuration, I ran the following commands to deploy the infrastructure:

```bash
# Initialize Terraform
terraform init

# Apply the configuration to create the infrastructure
terraform apply
```

This created an EKS cluster named `my-cluster` in the specified AWS region.

### 3. Configuring `kubectl` to Work with the EKS Cluster

Once the EKS cluster was successfully set up, I configured `kubectl` to interact with the cluster by updating the Kubernetes configuration.

```bash
aws eks update-kubeconfig --region us-east-1 --name my-cluster
```

This command allows me to access and manage the Kubernetes cluster using `kubectl`.

### 4. Installing ArgoCD in the Kubernetes Cluster Using Helm

ArgoCD is a powerful tool for GitOps-based continuous delivery in Kubernetes. I used Helm to install ArgoCD into the EKS cluster.

First, add the ArgoCD Helm repository:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

Then, install ArgoCD into the Kubernetes cluster:

```bash
helm install my-argo-cd argo/argo-cd --version 7.6.7
```

Once ArgoCD was successfully installed, I was able to access its UI to configure the Telex application.

Thanks for the update! Here's the revised section for accessing the ArgoCD web interface using a LoadBalancer instead of port-forwarding.

---

### 5. Accessing the ArgoCD Web Interface

After installing ArgoCD, I exposed the ArgoCD web interface by changing the service type from `ClusterIP` to `LoadBalancer`. This allows external access to the ArgoCD dashboard.

To modify the service:

```bash
kubectl edit service my-argo-cd-argocd-server 
```

In the editor, I changed the `spec.type` from `ClusterIP` to `LoadBalancer`:

```yaml
spec:
  type: LoadBalancer
```

After saving and exiting, a LoadBalancer was provisioned, and I obtained the external IP for accessing the ArgoCD UI. You can check the status of the LoadBalancer with:

```bash
kubectl get svc
```

Once the external IP was ready, I accessed the ArgoCD UI via the following URL:

```
http://<EXTERNAL-IP>
```

The default username for ArgoCD is `admin`, and I retrieved the password using:

```bash
kubectl get secret my-argo-cd-argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
```

I then logged into the ArgoCD web interface and proceeded to configure the Telex application for continuous delivery.

### 6. Setting Up the Telex Application in ArgoCD via the Web Interface

After logging into the ArgoCD web UI, I manually created the Telex application for continuous delivery. Here's how I set it up:

1. **Repository Setup**: I connected my GitHub repository containing the Kubernetes manifests for the Telex application.
   - In the **Git URL** field, I entered the URL to my GitHub repo (e.g., `https://github.com/AugustHottie/telex-deployment.git`).
   - I left the **Path** blank since I did not use Helm charts for this deployment.

2. **Cluster Setup**: I selected my EKS cluster as the deployment target.
   - In the **Destination Cluster** field, I selected `https://kubernetes.default.svc`.
   - The **Namespace** was set to `telex` for this deployment.

3. **Sync Policy**: I set up automated synchronization for continuous deployment.
   - I enabled **Auto-Sync** to allow ArgoCD to detect changes in the GitHub repository and automatically deploy updates.

4. **Application Deployment**: After completing the configuration, ArgoCD pulled the manifests from the repository and deployed the Telex application on the EKS cluster.

### 7. Monitoring and Managing the Application

The ArgoCD dashboard allows me to easily monitor the state of the Telex application, check for any issues, and review the GitOps workflow.

- **Sync Status**: I can see if the application is up-to-date with the repository.
- **Application Health**: The health status shows whether the application is running correctly.
- **Logs**: I can view detailed logs for troubleshooting.

### 8. Integrating Helm and ArgoCD into the CI/CD Pipeline

To integrate Helm and ArgoCD into the CI/CD pipeline, I added the following steps to the workflow:

1. Install Helm:
```yaml
- name: Install Helm
  run: |
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

2. Add ArgoCD Helm repo:
```yaml
- name: Add ArgoCD Helm repo
  run: |
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
```
3. Install ArgoCD:
```yaml
- name: Install ArgoCD
  run: |
    helm install my-argo-cd argo/argo-cd --version 7.6.7 --namespace argocd --create-namespace
```

4. Configure ArgoCD for Telex deployment
```yaml
- name: Configure ArgoCD for Telex deployment
  run: |
    kubectl apply -f argocd-application.yaml
```

### 9. Implementing AWS STS AssumeRole
To enhance the security of the Telex application, I implemented AWS STS AssumeRole. This allows the application to assume an IAM role with limited permissions, reducing the risk of unauthorized access.

Here's how I implemented AWS STS AssumeRole:
1. **Assume the role**: This role is created for github OpenID connect to run the CI/CD pipeline.
```bash
aws sts assume-role --role-arn <your arn> --role-session-name eks-session
```
2. Set the returned credentials as environment variables:
```bash
export AWS_ACCESS_KEY_ID=<AccessKeyId>
export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
export AWS_SESSION_TOKEN=<SessionToken>
```
3. When the session expires, unset the expired tokens:
```bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```
4. Create a new session by repeating steps 1 and 2.
Remember that temporary credentials have an expiration time. Always check the 'Expiration' field in the AssumeRole response to know when you'll need to refresh your credentials.


### 10. Utilizing GitHub OpenID Connect (OIDC) for AWS Authentication

This project leverages GitHub OpenID Connect (OIDC) for secure authentication with AWS. This approach is used both in the GitHub Actions pipeline and for local development, enhancing security by eliminating the need for long-lived AWS credentials.

1. For the GitHub Actions pipeline:
   - The workflow uses the `aws-actions/configure-aws-credentials` action with OIDC.
   - This allows the pipeline to securely authenticate with AWS without storing AWS credentials as long-lived GitHub secrets.

2. For local development:
   - The same IAM role used by the GitHub Actions workflow can be assumed locally.
   - This provides a consistent authentication method across CI/CD and development environments.

For more details on setting up OIDC with AWS, refer to the [GitHub documentation](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services).

### Conclusion

This project demonstrates the deployment of the Telex application using **ArgoCD** for continuous delivery, **Helm** for package management, **Terraform** for infrastructure as code on **AWS EKS**, and **AWS STS AssumeRole** for secure access management. I gained hands-on experience in managing Kubernetes deployments with GitOps, setting up a scalable cloud infrastructure, and implementing secure access practices.

Feel free to explore this repository and the steps outlined above to deploy your own applications using the same tools and techniques.

## Future Enhancements

- Implement automated scaling with the Kubernetes **Horizontal Pod Autoscaler (HPA)**.
- Add **monitoring and alerting** using Prometheus and Grafana.
- Integrate **CI/CD pipelines** with ArgoCD for more advanced deployment workflows. ✅
