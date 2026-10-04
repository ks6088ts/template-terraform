resource "terraform_data" "feature_dependencies" {
  count = var.enable_test_vm && !var.enable_private_endpoint_example ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.enable_private_endpoint_example
      error_message = "enable_private_endpoint_example must be true when enable_test_vm is true."
    }
  }
}

locals {
  validation_cloud_config = var.enable_test_vm && var.enable_private_endpoint_example ? join("\n", [
    "#cloud-config",
    yamlencode({
      package_update  = false
      package_upgrade = false
      write_files = [
        {
          path        = "/usr/local/bin/validate-private-blob"
          permissions = "0755"
          owner       = "root:root"
          content     = file("${path.module}/scripts/validate_private_blob.sh")
        },
        {
          path        = "/etc/systemd/system/validate-private-blob.service"
          permissions = "0644"
          owner       = "root:root"
          content     = <<-UNIT
            [Unit]
            Description=Validate private Blob DNS and HTTPS connectivity
            Wants=network-online.target
            After=network-online.target

            [Service]
            Type=oneshot
            ExecStart=/usr/local/bin/validate-private-blob ${module.storage[0].account_name}.blob.core.windows.net ${module.private_endpoint_blob[0].private_ip_address}
            TimeoutStartSec=600
            StandardInput=null
            StandardOutput=tty
            StandardError=tty
            TTYPath=/dev/ttyS0

            [Install]
            WantedBy=multi-user.target
          UNIT
        },
      ]
      runcmd = [
        ["systemctl", "daemon-reload"],
        ["systemctl", "enable", "--now", "validate-private-blob.service"],
      ]
    }),
  ]) : null
}

module "linux_vm" {
  count  = var.enable_test_vm ? 1 : 0
  source = "../../modules/azure/linux_vm"

  name                     = local.resource_name
  resource_group_name      = module.resource_group.name
  location                 = module.resource_group.location
  tags                     = var.tags
  subnet_id                = module.spoke_virtual_network.subnet_ids["snet-workload"]
  size                     = var.vm_size
  admin_username           = var.vm_admin_username
  os_disk_size_gb          = var.vm_os_disk_size_gb
  os_disk_type             = var.vm_os_disk_type
  custom_data              = local.validation_cloud_config == null ? null : base64encode(local.validation_cloud_config)
  boot_diagnostics_enabled = true
  identity_enabled         = false

  depends_on = [terraform_data.feature_dependencies, module.private_endpoint_blob]
}
