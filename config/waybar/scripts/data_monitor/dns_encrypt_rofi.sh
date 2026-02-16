#!/bin/bash

# Configuration
dir="$HOME/.config/waybar/scripts/data_monitor"
theme_input="$dir/placeholder.rasi"
resolved_conf="/etc/systemd/resolved.conf"

# Runs as Root via pkexec
apply_dns() {
    local dns_ips="$1"
    local provider_name="$2"

    local cmd="cat <<EOF > $resolved_conf
[Resolve]
DNS=$dns_ips
DNSOverTLS=yes
DNSSEC=no
Domains=~.
EOF
systemctl restart systemd-resolved"

    if pkexec bash -c "$cmd"; then
        notify-send "DNS Manager" "Success: Switched to $provider_name"  
    else
        notify-send "DNS Manager" "Failed to update DNS." -u critical
    fi
}

# Restore Defaults
system_dns() {
    local cmd="echo '[Resolve]' > $resolved_conf && echo '# Defaults restored' >> $resolved_conf && systemctl restart systemd-resolved"
    
    if pkexec bash -c "$cmd"; then
        notify-send "DNS Manager" "Success: Restored ISP Default Settings" -u normal
    else
        notify-send "DNS Manager" "Failed to restore defaults." -u critical
    fi
}

# Main Rofi Loop 
main() {
    while true; do
        local msg="<big><b>Encrypted DNS Setup (DoT)</b></big>"
        msg+=$'\n'
        msg+="<b>Select a profile to apply (IPv4 + IPv6)</b>"
        msg+=$'\n\n'
        msg+="1. Cloudflare (Fastest)"
        msg+=$'\n'
        msg+="2. Google (Reliability)"
        msg+=$'\n'
        msg+="3. Quad9 (Security/Malware Blocking)"
        msg+=$'\n'
        msg+="4. AdGuard (Blocks Ads + Trackers)"
        msg+=$'\n'
        msg+="5. Mullvad Adblock (Privacy + Ads)"
        msg+=$'\n'
        msg+="6. Cloudflare Family (Blocks Malware + Adult Content)"
        msg+=$'\n'
        msg+="7. AdGuard Family (Blocks Ads + Adult Content)"
        msg+=$'\n'
        msg+="8. Restore Default ISP Settings"

        local choice
        choice=$(echo " Back" | rofi -dmenu -theme "$theme_input" -mesg "$msg" -p "Select Option")

        case "$choice" in
            1)
                apply_dns "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com" "Cloudflare"
                break
                ;;
            2)
                apply_dns "8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google" "Google DNS"
                break
                ;;
            3)
                apply_dns "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net" "Quad9"
                break
                ;;
            4)
                apply_dns "94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com 2a10:50c0::ad1:ff#dns.adguard-dns.com 2a10:50c0::ad2:ff#dns.adguard-dns.com" "AdGuard"
                break
                ;;
            5)
                apply_dns "194.242.2.3#adblock.dns.mullvad.net 2a07:e340::3#adblock.dns.mullvad.net" "Mullvad"
                break
                ;;
            6)
                apply_dns "1.1.1.3#family.cloudflare-dns.com 1.0.0.3#family.cloudflare-dns.com 2606:4700:4700::1113#family.cloudflare-dns.com 2606:4700:4700::1003#family.cloudflare-dns.com" "Cloudflare Family"
                break
                ;;
            7)
                apply_dns "94.140.14.15#dns-family.adguard-dns.com 94.140.15.16#dns-family.adguard-dns.com 2a10:50c0::bad1:ff#dns-family.adguard-dns.com 2a10:50c0::bad2:ff#dns-family.adguard-dns.com" "AdGuard Family"
                break
                ;;
            8)
                system_dns
                break
                ;;
            " Back" | "")
                break
                ;;
            *) 
                ;;
        esac
    done
}

main