#!/bin/bash

function valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a ip_parts <<< "$ip"
        [[ ${ip_parts[0]} -le 255 && ${ip_parts[1]} -le 255 && ${ip_parts[2]} -le 255 && ${ip_parts[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#Get the last value of external ip
FILE="/tmp/updatedns"
[ -f "$FILE" ] && read -r OLD < "$FILE"

#Get the external ip from router
CONTENT=$(/usr/bin/upnpc -s | grep ^ExternalIPAddress | cut -c21-)

if ! valid_ip "$CONTENT"; then
    mail.py hans.winzell@gmail.com "Error while getting IP"
    exit 1
fi

if [ "$CONTENT" != "$OLD" ]; then
    ID="xxxxxxx"
    TOKEN="xxxxxxxx"
    ZONE_ID="xxxxxxxx"
    TYPE="A"
    NAME="domain.com"
    PROXIED="false"
    TTL="1"

    response=$(curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$ID" \
        -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
        --data '{"type":"'"$TYPE"'","name":"'"$NAME"'","content":"'"$CONTENT"'","proxied":'"$PROXIED"',"ttl":'"$TTL"'}' 2>/dev/null | python -m json.tool | jq '.success')

    mail.py mail@domain.com "$CONTENT $response"
    echo "$CONTENT" > "$FILE"
fi

