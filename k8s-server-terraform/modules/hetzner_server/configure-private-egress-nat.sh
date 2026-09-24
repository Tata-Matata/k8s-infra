#!/usr/bin/env bash

# Exit immediately if:
#   - a command returns a non-zero exit status (-e)
#   - an unset variable is referenced (-u)
#   - a command inside a pipeline fails (-o pipefail)
#
# Together, these make errors much less likely to be silently ignored.
set -euo pipefail

sysctl_config_path="/etc/sysctl.d/99-k8s-private-egress.conf"

# ------------------------------------------------------------
# Find the public-facing network interface
# ------------------------------------------------------------

# ip route shows for example:
#
#   default via 10.0.0.1 dev eth0 proto dhcp src 10.0.0.5
#
# The important part is:    dev eth0
#
# which tells us that eth0 is the interface used to reach
# destinations for which there is no more specific route.
#
# Therefore, we treat this interface as the PUBLIC interface.
# awk prints field 5 of the line containing default
public_interface="$(ip route show default | awk '/default/ { print $5; exit }')"


# ------------------------------------------------------------
# Find the private-facing network interface
# ------------------------------------------------------------
# Look for network interfaces whose name starts with "e".
  #
  # The input from:
  #
  #   ip -o link show
  #
  # looks roughly like:
  #
  #   1: lo: <LOOPBACK,...>
  #   2: eth0@if123: <BROADCAST,...>
  #   3: eth1: <BROADCAST,...>
  # This is assuming the interfaces have names such as eth0/eth1/ens...
  # and is therefore somewhat dependent on the naming scheme.
  # Compare this interface with the public interface we found above
  # We don't want to select the public interface again.
private_interface="$(ip -o link show | awk -F': ' -v public_interface="${public_interface}" '
  /^[0-9]+: e/ {
    split($2, iface, "@");
    if (iface[1] != public_interface) {
      print iface[1];
      exit
    }
  }
')"

if [[ -z "${public_interface}" || -z "${private_interface}" ]]; then
  echo "Could not determine public/private interfaces for NAT" >&2
  exit 1
fi

# ------------------------------------------------------------
# Enable IPv4 forwarding persistently, then reload sysctl so the new setting is
# active before the FORWARD and MASQUERADE rules are relied on.
# ------------------------------------------------------------

cat > "${sysctl_config_path}" <<'EOF'
net.ipv4.ip_forward=1
EOF

sysctl --system >/dev/null


# ------------------------------------------------------------
# Configure NAT / source address translation
# ------------------------------------------------------------


iptables -t nat -C POSTROUTING -s __PRIVATE_NETWORK_CIDR__ -o "${public_interface}" -j MASQUERADE || \
  iptables -t nat -A POSTROUTING -s __PRIVATE_NETWORK_CIDR__ -o "${public_interface}" -j MASQUERADE


# ------------------------------------------------------------
# Allow forwarding from private network -> public network
# ------------------------------------------------------------


iptables -C FORWARD -i "${private_interface}" -o "${public_interface}" -j ACCEPT || \
  iptables -A FORWARD -i "${private_interface}" -o "${public_interface}" -j ACCEPT

# ------------------------------------------------------------
# Allow return traffic from Internet -> private network
# ------------------------------------------------------------


iptables -C FORWARD -i "${public_interface}" -o "${private_interface}" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || \
  iptables -A FORWARD -i "${public_interface}" -o "${private_interface}" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

netfilter-persistent save