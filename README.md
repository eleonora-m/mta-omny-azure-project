# 🚇 OMNY-Scale: Scalable Fare Processing System on Azure

## 📌 Project Overview
This project simulates an auto-scalable, highly available cloud infrastructure designed to handle peak-hour transaction loads for the MTA OMNY contactless fare payment system. Built entirely with Infrastructure as Code (IaC), this architecture dynamically adjusts resources to ensure zero downtime during rush hours while optimizing costs during off-peak times.

## 🏗 Architecture & Tech Stack
* **Cloud Provider:** Microsoft Azure
* **Infrastructure as Code (IaC):** Terraform
* **Containerization:** Docker
* **Web Server / API Simulator:** Nginx

## ⚙️ Key Components
1. **Virtual Network (VNet) & Subnet:** Provides an isolated and secure internal network for the payment servers.
2. **Virtual Machine Scale Set (VMSS):** The core auto-scaling engine. It automatically provisions new Ubuntu servers based on traffic demands.
3. **Azure Load Balancer:** Distributes incoming payment API requests (simulated on port 80) evenly across the VMSS instances to prevent overload.
4. **Network Security Group (NSG):** Acts as a strict firewall, only allowing specific inbound traffic (HTTP) to reach the load balancer.
5. **Cloud-init (Custom Data):** Automates the installation of Docker and deployment of the Nginx container upon server creation, eliminating the need for manual configuration.

## 🚀 How to Deploy
1. Clone the repository.
2. Ensure you have the Azure CLI installed and authenticated (`az login`).
3. Initialize Terraform:
   `terraform init`
4. Review the infrastructure plan:
   `terraform plan`
5. Deploy the resources (creates the Load Balancer, Network, and VMSS):
   `terraform apply -auto-approve`
6. Once deployed, Terraform will output the `load_balancer_public_ip`. Navigate to this IP in your browser to verify the simulated OMNY API (Nginx) is responding.

## 🧹 Cleanup
To avoid unnecessary cloud charges, tear down the infrastructure when testing is complete:
`terraform destroy -auto-approve`
