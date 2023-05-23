# Azure VPN Lab with NAT

This creates an onprem vnet with vpn gateway connected to a hub vnet vpn gateway and a spoke vnet attached to the hub. The onprem and hub vnets have the same ip range and are natted on the hub vpn gateway with ingress and egress NAT rules. VM's are created in all 3 vnets. You'll be prompted for the resource group name, location where you want the resources created, your public ip, and username and password to use for the VM's. NSG's are placed on the default subnets of each vnet allowing RDP access from your public ip. This also creates a logic app that will delete the resource group in 24hrs. The topology will look something like this:
![vpnlabwithnat](https://github.com/quiveringbacon/AzureVPNLabwithNAT/assets/128983862/cf086a79-127a-4c4b-a6f1-07ba2ea6eafb)

You can run Terraform right from the Azure cloud shell by cloning this git repository with "git clone  https://github.com/quiveringbacon/AzureVPNLabwithNAT.git ./terraform".
Then, "cd terraform" then, "terraform init" and finally "terraform apply -auto-approve" to deploy.

