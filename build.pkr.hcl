packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = ">= 1.0.0"
    }
    vagrant = {
      version = ">= 1.0.0"
      source = "github.com/hashicorp/vagrant"
    }
    qemu = {
      version = ">= 1.0.0"
      source = "github.com/hashicorp/qemu"
    }
  }
}

variable "image_name" {
  type    = string
  default = "${env("IMAGE_NAME")}"
}

variable "box_file_name" {
  type    = string
  default = "${env("BOX_FILE_NAME")}"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  boot_command = [
    "<enter><wait>",
    "passwd <<EOF<enter>vagrant<enter>vagrant<enter>EOF<enter>",
    "uci delete network.lan<enter>",
    "uci set network.mgmt=interface<enter>",
    "uci set network.mgmt.device='eth0'<enter>",
    "uci set network.mgmt.proto='dhcp'<enter>",
    "uci add_list firewall.@zone[0].network=mgmt<enter>",
    "uci commit<enter>",
    "fsync /etc/config/network<enter>",
    "/etc/init.d/network restart<enter>",
    "service firewall restart<enter>"
  ]
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "qemu" "openwrt-libvirt" {
  boot_command     = local.boot_command
  boot_wait        = "20s"
  cpus             = 1
  disk_image       = true
  disk_interface   = "virtio"
  format           = "qcow2"
  headless         = true
  iso_checksum     = "none"
  iso_url          = "${var.image_name}.img"
  memory           = 128
  net_device       = "virtio-net"
  shutdown_command = "poweroff"
  ssh_password     = "vagrant"
  ssh_username     = "root"
  ssh_wait_timeout = "300s"
}

source "virtualbox-ovf" "openwrt-virtualbox" {
  boot_command         = local.boot_command
  boot_wait            = "20s"
  guest_additions_mode = "disable"
  headless             = true
  shutdown_command     = "poweroff"
  source_path          = "${var.image_name}.ovf"
  ssh_password         = "vagrant"
  ssh_username         = "root"
  ssh_wait_timeout     = "300s"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--boot1", "disk"],
    ["modifyvm", "{{ .Name }}", "--memory", "128", "--vram", 16],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--usbxhci", "off"]
  ]
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = [
    "source.qemu.openwrt-libvirt",
    "source.virtualbox-ovf.openwrt-virtualbox"
  ]

  provisioner "shell" {
    expect_disconnect   = "true"
    scripts             = [
      "scripts/packages.sh",
      "scripts/vagrant.sh",
      "scripts/cleanup.sh",
      "scripts/v25_halt_fix.sh"
    ]
    start_retry_timeout = "15m"
  }

  post-processor "vagrant" {
    output               = "${var.box_file_name}"
    vagrantfile_template = "templates/vagrantfile.rb"
  }
}
