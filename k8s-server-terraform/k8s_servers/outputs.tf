## for retrieving the list of all available images in Hetzner Terraform 
## terraform plan, then terraform output available_images
output "available_images" {
  value = [
    for img in data.hcloud_images.all_x86.images : {
      name       = img.name
      os_flavor  = img.os_flavor
      os_version = img.os_version
      arch       = img.architecture
    }
  ]
}