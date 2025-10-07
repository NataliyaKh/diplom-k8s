output "private_master_ips" {
  value = [
    for name, vm in yandex_compute_instance.vm :
    vm.network_interface[0].ip_address if name == "master"
  ]
}

output "private_worker_ips" {
  value = [
    for name, vm in yandex_compute_instance.vm :
    vm.network_interface[0].ip_address if startswith(name, "worker")
  ]
}

output "external_master_ips" {
  value = [
    for name, vm in yandex_compute_instance.vm :
    vm.network_interface[0].nat_ip_address if name == "master"
  ]
}

output "external_worker_ips" {
  value = [
    for name, vm in yandex_compute_instance.vm :
    vm.network_interface[0].nat_ip_address if startswith(name, "worker")
  ]
}
