# Azure Windows 11 US Low-Cost VM with RDP Access from Brazil

This Terraform project provisions a Windows 11 VM in a US Azure region and restricts RDP access to your Brazilian public IP address.

Default settings:

- Azure region: `eastus`
- Resource group: `rg-win11-us-lowcost`
- VM size: `Standard_B2s`
- Disk: `Standard_LRS`
- OS: Windows 11 Pro Marketplace image
- RDP: allowed only from `allowed_rdp_ip`

## Files

- `main.tf` - Azure resources
- `variables.tf` - input variables
- `outputs.tf` - useful outputs
- `terraform.tfvars.example` - sample values
- `.gitignore` - avoids committing state and secrets

## Prerequisites

Install:

- Azure CLI
- Terraform

Login:

```bash
az login
az account set --subscription "<your-subscription-id>"
```

## Configure

Copy the example vars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
location = "eastus"
resource_group_name = "rg-win11-us-lowcost"
vm_size = "Standard_B2s"
admin_username = "azureuser"
admin_password = "Use-A-Strong-Password-Here-123!"
allowed_rdp_ip = "YOUR_PUBLIC_IP/32"
windows_11_sku = "win11-24h2-pro"
```

To find your public IP, search online for "what is my IP", then append `/32`.

Example:

```hcl
allowed_rdp_ip = "189.10.20.30/32"
```

## Deploy

Because Azure network resources can sometimes have read-after-create propagation issues, this project pins the AzureRM provider to v4 and includes longer network resource timeouts. You can also apply with low parallelism:

```bash
terraform init -upgrade
terraform plan
terraform apply -parallelism=1
```

## Connect

After apply:

```bash
terraform output public_ip_address
```

From Windows:

```bash
mstsc /v:<PUBLIC_IP>
```

From macOS, use Microsoft Remote Desktop and connect to the public IP.

## If the Windows 11 SKU is unavailable

List available Windows 11 SKUs in your selected region:

```bash
az vm image list \
  --location eastus \
  --publisher MicrosoftWindowsDesktop \
  --offer windows-11 \
  --all \
  --output table
```

Then update `windows_11_sku` in `terraform.tfvars`.

## Stop compute charges when not using the VM

Deallocate the VM:

```bash
terraform output deallocate_command
```

Then run the returned command, or run:

```bash
az vm deallocate \
  --resource-group rg-win11-us-lowcost \
  --name <VM_NAME>
```

You still pay for disk storage and the static public IP, but compute billing stops while the VM is deallocated.

## Destroy everything

```bash
terraform destroy
```
