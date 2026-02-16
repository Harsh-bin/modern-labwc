#!/bin/bash

#################################################
# IPv4+IPv6 support, Family & Adblock options.
#################################################

# source color extraction script
USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
source "$USER_HOME/.config/waybar/scripts/css_color_extraction.sh"

resolved_conf="/etc/systemd/resolved.conf"

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${term_secondary}[!] Error: Please run as sudo.${reset}"
    exit 1
fi

system_dns() {
    echo -e "${term_primary}[*] Restoring system defaults...${reset}"
    echo "[Resolve]" >"$resolved_conf"
    echo "# Defaults restored" >>"$resolved_conf"
    systemctl restart systemd-resolved
    echo -e "${term_secondary}[✔] Done. Using ISP Settings.${reset}"
}

apply_dns() {
    local dns_settings=$1
    local name=$2

    echo -e "${term_primary}[*] Applying: $name${reset}"

    # Backup existing config
    cp "$resolved_conf" "$resolved_conf.bak" 2>/dev/null

    # Write config (Force Global DNS with Domains=~.)
    cat <<EOF >"$resolved_conf"
[Resolve]
DNS=$dns_settings
DNSOverTLS=yes
DNSSEC=no
Domains=~.
EOF

    # Restart service
    echo -e "${term_primary}[*] Restarting network service...${reset}"
    systemctl restart systemd-resolved

    # Validation
    sleep 2
    if resolvectl query google.com >/dev/null 2>&1; then
        echo -e "${term_primary}[✔] Success! System is now using $name (Encrypted).${reset}"
        resolvectl status | grep "DNS Servers" -A 2 | head -n 3
    else
        echo -e "${term_secondary}[✘] Connection Failed.${reset}"
        echo -e "    Your ISP might be blocking Port 853. Try a different provider."
        # Restore system default if it fails
        system_dns
    fi
}

clear
echo -e "${term_primary}=== ENCRYPTED DNS SETUP (DoT) ===${reset}"
echo -e "Select a profile below. All options support IPv4 & IPv6.\n"
echo ""
echo "1) Cloudflare (Fastest)"
echo "2) Google (Reliability)"
echo "3) Quad9 (Security/Malware Blocking)"
echo "4) AdGuard (Blocks Ads & Trackers)"
echo "5) Mullvad Adblock (Privacy + Ads)"
echo "6) Cloudflare Family (Blocks Malware + Adult Content)"
echo "7) AdGuard Family (Blocks Ads + Adult Content)"
echo "8) Restore Default ISP Settings"
echo ""
read -p "Select Option (1-8): " choice

case $choice in
1)
    # Cloudflare Standard
    # 1.1.1.1 / 1.0.0.1
    DNS="1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com"
    apply_dns "$DNS" "Cloudflare Standard"
    ;;
2)
    # Google
    # 8.8.8.8 / 8.8.4.4
    DNS="8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google"
    apply_dns "$DNS" "Google DNS"
    ;;
3)
    # Quad9 (Malware Blocking)
    # 9.9.9.9 / 149.112.112.112
    DNS="9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net"
    apply_dns "$DNS" "Quad9 Security"
    ;;
4)
    # AdGuard Standard (Ads + Trackers)
    # 94.140.14.14 / 94.140.15.15
    DNS="94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com 2a10:50c0::ad1:ff#dns.adguard-dns.com 2a10:50c0::ad2:ff#dns.adguard-dns.com"
    apply_dns "$DNS" "AdGuard (Ads/Trackers)"
    ;;
5)
    # Mullvad Adblock
    # 194.242.2.3 / 2a07:e340::3
    DNS="194.242.2.3#adblock.dns.mullvad.net 2a07:e340::3#adblock.dns.mullvad.net"
    apply_dns "$DNS" "Mullvad Adblock"
    ;;
6)
    # Cloudflare Family (Malware + Adult)
    # 1.1.1.3 / 1.0.0.3
    DNS="1.1.1.3#family.cloudflare-dns.com 1.0.0.3#family.cloudflare-dns.com 2606:4700:4700::1113#family.cloudflare-dns.com 2606:4700:4700::1003#family.cloudflare-dns.com"
    apply_dns "$DNS" "Cloudflare Family"
    ;;
7)
    # AdGuard Family (Ads + Trackers + Adult)
    # 94.140.14.15 / 94.140.15.16
    DNS="94.140.14.15#dns-family.adguard-dns.com 94.140.15.16#dns-family.adguard-dns.com 2a10:50c0::bad1:ff#dns-family.adguard-dns.com 2a10:50c0::bad2:ff#dns-family.adguard-dns.com"
    apply_dns "$DNS" "AdGuard Family"
    ;;
8)
    system_dns
    ;;
*)
    echo "Invalid choice."
    ;;
esac
