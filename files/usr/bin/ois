#!/bin/sh
# Version 0.4.0
# Updated: Sep 6, 2022

if [ -z "$1" ]; then
    echo -e "\nUsage: $0 <config_name>\n"
    exit 1
fi

NAME=$1

# Get encrypted config file from server
URL="https://tommy.net.cn/router/${NAME}.bin"

if [ -f /etc/router/${NAME}.bin ]; then
    # Open encrypted config file if it's in the tmp directory
    mv /etc/router/${NAME}.bin /tmp/config.bin
else
    if [ ! -f /tmp/config.bin ]; then
        curl -SL "$URL" -o /tmp/config.bin 2> /dev/null
    fi

    if [ ! -f /tmp/config.bin ]; then
        echo -e "\nCannot get config file from '${URL}'\n\nPlease copy config file to '/tmp/config.bin'\n"
        exit 2
    fi
fi

if [ -z ${PASSWORD} ]; then
    COMMAND="openssl enc -aes-256-cbc -d < /tmp/config.bin > /tmp/config.json 2> /dev/null"
else
    COMMAND="openssl enc -aes-256-cbc -d -pass env:PASSWORD < /tmp/config.bin > /tmp/config.json 2> /dev/null"
fi

if ! eval ${COMMAND}; then
    echo -e "Cannot decrypt!!!\n"
    exit 3
fi

# Parse JSON data
JSON=`cat /tmp/config.json`
NAME=`echo "${JSON}" | jq -r '.name'`
PASSWORD=`echo "${JSON}" | jq -r '.password'`
LAN_IP=`echo "${JSON}" | jq -r '.lan_ip'`
SSH_KEY=`echo "${JSON}" | jq -r '.ssh_key' | base64 -d`

## Optional Data
WIFI_PASSWORD=`echo "${JSON}" | jq -r 'if .wifi_password == null then .password else .wifi_password end'`
SSID_2G=`echo "${JSON}" | jq -r 'if .ssid_2g == null then .name + "_2G" else .ssid_2g end'`
SSID_5G=`echo "${JSON}" | jq -r 'if .ssid_5g == null then .name else .ssid_5g end'`

NEBULA_CA=`echo "${JSON}" | jq -r 'if .nebula_ca == null then "" else .nebula_ca end'`
NEBULA_CRT=`echo "${JSON}" | jq -r 'if .nebula_crt == null then "" else .nebula_crt end'`
NEBULA_KEY=`echo "${JSON}" | jq -r 'if .nebula_key == null then "" else .nebula_key end'`
NEBULA_CFG=`echo "${JSON}" | jq -r 'if .nebula_config == null then "" else .nebula_config end'`

PPPOE_USERNAME=`echo "${JSON}" | jq -r 'if .pppoe_username == null then "" else .pppoe_username end'`
PPPOE_PASSWORD=`echo "${JSON}" | jq -r 'if .pppoe_password == null then "" else .pppoe_password end'`

# ------------------------------------------------------------
# General
# ------------------------------------------------------------

# Name
uci set system.@system[0].hostname="${NAME}"

# Setup password
echo -e "${PASSWORD}\n${PASSWORD}" | passwd root

# Timezone
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'

# Reboot daily
echo "0 6 * * * sleep 70 && touch /etc/banner && reboot" >> /etc/crontabs/root
/etc/init.d/cron enable

# ------------------------------------------------------------
# Wi-Fi
# ------------------------------------------------------------

# Enable radio
uci set wireless.radio0.disabled='0'
uci set wireless.radio1.disabled='0'

# China
uci set wireless.radio0.country='CN'
uci set wireless.radio1.country='CN'

# Bandwith 40MHz for 2.4G, 160MHz for 5G
uci set wireless.radio0.htmode='HT40'
uci set wireless.radio1.htmode='HE160'

# Channel
uci set wireless.radio0.channel='6'
uci set wireless.radio1.channel='52'

# MU-MIMO
uci set wireless.radio0.mu_beamformer='1'
uci set wireless.radio1.mu_beamformer='1'

# Encryption - WPA2 CCMP (AES) for compatibility
uci set wireless.default_radio0.encryption='psk2+ccmp'
uci set wireless.default_radio1.encryption='psk2+ccmp'

# SSID
uci set wireless.default_radio0.ssid="${SSID_2G}"
uci set wireless.default_radio1.ssid="${SSID_5G}"

# Password
uci set wireless.default_radio0.key="${WIFI_PASSWORD}"
uci set wireless.default_radio1.key="${WIFI_PASSWORD}"

## Only enable 802.11k/v/r Wi-Fi roaming for 5GHz
## Wi-Fi 802.11k
uci set wireless.default_radio1.ieee80211k='1'
## Wi-Fi 802.11v
uci set wireless.default_radio1.ieee80211v='1'
uci set wireless.default_radio1.time_advertisement='0'
## Wi-Fi 802.11r
uci set wireless.default_radio1.ieee80211r='1'
uci set wireless.default_radio1.ft_over_ds='1'
uci set wireless.default_radio1.ft_psk_generate_local='1'

# ------------------------------------------------------------
# SSH
# ------------------------------------------------------------

# Remove interface binding for SSH server
uci del dropbear.@dropbear[0].Interface

# Enable port forwarding for SSH server
uci set dropbear.@dropbear[0].GatewayPorts='on'

# Redirect to HTTPS
uci set uhttpd.main.redirect_https='on'

# Add public key to authorized_keys
echo "${SSH_KEY}" >> /etc/dropbear/authorized_keys

# ------------------------------------------------------------
# Network
# ------------------------------------------------------------

# Lan IP
#uci del dhcp.lan.ra_slaac
uci set network.lan.ipaddr="${LAN_IP}"

# ------------------------------------------------------------
# Firewall
# ------------------------------------------------------------

# Enable IPv6 forward to access intranet devices with IPv6 address
uci set firewall.@defaults[0].forward='ACCEPT'

# ------------------------------------------------------------
# DNS
# ------------------------------------------------------------

# Disable rebind protection to use domain for private ip address
uci set dhcp.@dnsmasq[0].rebind_protection='0'

# Local domain
COUNT=0
ADDRESS=`echo "${JSON}" | jq -r ".addresses[${COUNT}]"`
while [ "${ADDRESS}" != "null" ]; do
    uci add_list dhcp.@dnsmasq[0].address="${ADDRESS}"
    COUNT=$(expr $COUNT + 1)
    ADDRESS=`echo "${JSON}" | jq -r ".addresses[${COUNT}]"`
done

# Static leasing
COUNT=0
NAME=`echo "${JSON}" | jq -r ".static_leases[${COUNT}][0]"`
while [ "${NAME}" != "null" ]; do
    MAC=`echo "${JSON}" | jq -r ".static_leases[${COUNT}][1]"`
    IP=`echo "${JSON}" | jq -r ".static_leases[${COUNT}][2]"`

    uci add dhcp host
    uci set dhcp.@host[-1].name="${NAME}"
    uci set dhcp.@host[-1].dns='1'
    uci set dhcp.@host[-1].mac="${MAC}"
    uci set dhcp.@host[-1].ip="${IP}"

    # Next item
    COUNT=$(expr $COUNT + 1)
    NAME=`echo "${JSON}" | jq -r ".static_leases[${COUNT}][0]"`
done


# ------------------------------------------------------------
# Nebula
# ------------------------------------------------------------
if [ -n "${NEBULA_CA}" ]; then
    mkdir /etc/nebula > /dev/null

    echo "${NEBULA_CA}" | base64 -d > /etc/nebula/ca.crt
    echo "${NEBULA_CRT}" | base64 -d > /etc/nebula/host.crt
    echo "${NEBULA_KEY}" | base64 -d > /etc/nebula/host.key
    echo "${NEBULA_CFG}" | base64 -d > /etc/nebula/config.yml

    /etc/init.d/nebula enable
fi

# ------------------------------------------------------------
# PPPoE
# ------------------------------------------------------------
if [ -n "${PPPOE_USERNAME}" ] && [ -n "${PPPOE_PASSWORD}" ]; then
    uci set network.wan.proto='pppoe'
    uci set network.wan.username="${PPPOE_USERNAME}"
    uci set network.wan.password="${PPPOE_PASSWORD}"
    uci set network.wan.ipv6='auto'
fi

# ------------------------------------------------------------
# Save & Reboot
# ------------------------------------------------------------
uci commit
reboot
