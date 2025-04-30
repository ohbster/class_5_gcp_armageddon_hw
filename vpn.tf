# Shout out to JRemo his vpn example

resource "random_string" "shared_secret" {
    length = 32
    special = true
    override_special = "$@/"
    # upper = false
}

resource "google_compute_vpn_gateway" "eu-gateway" {
  project = "armageddon-eu"
  region = module.infra-eu.region
  name = "vpn-1"
  network = module.infra-eu.vpc_id
}

resource "google_compute_vpn_gateway" "asia-gateway" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name = "vpn-1"
  network = module.infra-asia.vpc_id
}

resource "google_compute_address" "eu-vpn_static_ip" {
  project = "armageddon-eu"
  region = module.infra-eu.region
  name = "${module.infra-eu.name}-vpn-1"
  address_type = "EXTERNAL"
  ip_version = "IPV4"
}

resource "google_compute_address" "asia-vpn_static_ip" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name = "${module.infra-asia.name}-vpn-1"
  address_type = "EXTERNAL"
  ip_version = "IPV4"
}

resource "google_compute_forwarding_rule" "eu-fr_esp" {
  project = "armageddon-eu"
  region = module.infra-eu.region
  name = "${module.infra-eu.name}-fr-esp"
  ip_protocol = "ESP"
  ip_address = google_compute_address.eu-vpn_static_ip.address
  target      = google_compute_vpn_gateway.eu-gateway.self_link

  depends_on = [ google_compute_vpn_gateway.asia-gateway ]
}

resource "google_compute_forwarding_rule" "asia-fr_esp" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name = "${module.infra-asia.name}-fr-esp"
  ip_protocol = "ESP"
  ip_address = google_compute_address.asia-vpn_static_ip.address
  target      = google_compute_vpn_gateway.asia-gateway.self_link
}

resource "google_compute_forwarding_rule" "eu-fr_udp500" {
  project = "armageddon-eu"
  region = module.infra-eu.region
  name        = "${module.infra-eu.name}-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.eu-vpn_static_ip.address
  target      = google_compute_vpn_gateway.eu-gateway.self_link
}

resource "google_compute_forwarding_rule" "asia-fr_udp500" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name        = "${module.infra-asia.name}-fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.asia-vpn_static_ip.address
  target      = google_compute_vpn_gateway.asia-gateway.self_link
}

resource "google_compute_forwarding_rule" "eu-fr_udp4500" {
  project = "armageddon-eu"
  region = module.infra-eu.region
  name        = "${module.infra-eu.name}-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.eu-vpn_static_ip.address
  target      = google_compute_vpn_gateway.eu-gateway.self_link
}

resource "google_compute_forwarding_rule" "asia-fr_udp4500" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name        = "${module.infra-asia.name}-fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.asia-vpn_static_ip.address
  target      = google_compute_vpn_gateway.asia-gateway.self_link
}

resource "google_compute_vpn_tunnel" "eu-tunnel" {
  project = "armageddon-eu"
  name = "${module.infra-eu.name}-tunnel-1"
  region = module.infra-eu.region
  peer_ip = google_compute_address.asia-vpn_static_ip.address
  shared_secret = random_string.shared_secret.result
  ike_version = 2
  
  local_traffic_selector = [module.infra-eu.subnet_cidr]
  remote_traffic_selector = [module.infra-asia.subnet_cidr]

  target_vpn_gateway = google_compute_vpn_gateway.eu-gateway.self_link
  
  depends_on = [ 
    google_compute_forwarding_rule.eu-fr_udp4500, 
    google_compute_forwarding_rule.eu-fr_udp500, 
    google_compute_forwarding_rule.eu-fr_esp ]
}

resource "google_compute_vpn_tunnel" "asia-tunnel" {
  project = "armageddon-as"
  region = module.infra-asia.region
  name = "${module.infra-asia.name}-tunnel-1"
  peer_ip = google_compute_address.eu-vpn_static_ip.address
  shared_secret = random_string.shared_secret.result
  ike_version = 2

  local_traffic_selector = [module.infra-asia.subnet_cidr]
  remote_traffic_selector = [module.infra-eu.subnet_cidr]


  target_vpn_gateway = google_compute_vpn_gateway.asia-gateway.self_link
  depends_on = [ 
    google_compute_forwarding_rule.asia-fr_esp,
    google_compute_forwarding_rule.asia-fr_udp4500,
    google_compute_forwarding_rule.asia-fr_udp500
   ]
}

resource "google_compute_route" "eu-route" {
  
  project = "armageddon-eu"
  name = "${module.infra-eu.name}-${module.infra-asia.name}-route"
  network = module.infra-eu.vpc_id
  dest_range = module.infra-asia.subnet_cidr
  priority = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.eu-tunnel.id
  depends_on = [ google_compute_vpn_tunnel.eu-tunnel ]
}

resource "google_compute_route" "asia-route" {
  project = "armageddon-as"
  name = "${module.infra-asia.name}-${module.infra-eu.name}-route"
  network = module.infra-asia.vpc_id
  dest_range = module.infra-eu.subnet_cidr
  priority = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.asia-tunnel.id
  depends_on = [ google_compute_vpn_tunnel.asia-tunnel ]
}

