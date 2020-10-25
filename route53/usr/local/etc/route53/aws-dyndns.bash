#!/usr/bin/env bash
set -u

# --- AWS user secrets ---
AWS_ACCESS_KEY_ID=AKXXXXXXXXXXXXXXXXE6
AWS_SECRET_ACCESS_KEY=J2XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXiC
# ------------------------

# --- AWS ZONE ---
AWS_ZONE_ID=Z0XXXXXXXXXXXXXXXAI
# ----------------

# -- Root domain name
DNS_ROOT_FQDN=example.com

# -- List of subdomain that should be included
# to the Route53 DNS records alongside with the root domain
DNS_SUBDOMAINS=(
  "qbt"  
  "plex"  
  "grafana"  
  "calibre"  
  "cloud"  
  "heimdall"  
  "ha"  
  "zm"
)

# DNS Entry TTL (seconds)
DNS_TTL=5

# DNS Rechedk time (seconds)
DNS_RECHECK_TIME=30

# ============================================
# ============================================
# ============================================

function validate_ip() {
  # Validates only IPv4
  [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# --- Configure AWS CLI ---
/usr/local/bin/aws \
  configure \
  set aws_access_key_id \
  "$AWS_ACCESS_KEY_ID"

/usr/local/bin/aws \
  configure \
  set aws_secret_access_key \
  "$AWS_SECRET_ACCESS_KEY"
# ---------------------------

TS=0 
while [ 1 ] ; do
  # first time we run DNS update without a delay
  sleep "${TS}"
  TS="$DNS_RECHECK_TIME" 

  OLD_IP="$(/usr/local/bin/dig +short "$DNS_ROOT_FQDN")"
  NEW_IP="$(/usr/local/bin/curl -sS --max-time 5 https://api.ipify.org)"

  if ! validate_ip "$OLD_IP" ; then
    echo "Invalid OLD_IP: $OLD_IP"
    continue
  fi

  if ! validate_ip "$NEW_IP" ; then
    echo "Invalid NEW_IP: $NEW_IP"
    continue
  fi

  if [ "$OLD_IP" == "$NEW_IP" ]; then
    echo "No IP change detected: $OLD_IP"
    continue
  fi

  # UPSERT: http://docs.aws.amazon.com/Route53/latest/APIReference/API_ChangeResourceRecordSets.html
  # http://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
  read -r -d '' JSON_CMD << EOF
  {
    "Comment": "DynDNS update",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "$DNS_ROOT_FQDN.",
          "Type": "A",
          "TTL": $DNS_TTL,
          "ResourceRecords": [
            {
              "Value": "$NEW_IP"
            }
          ]
        }
      }
    ]
  }
EOF

  echo "Updating IP from [$OLD_IP] to [$NEW_IP] for ($DNS_ROOT_FQDN)"
  /usr/local/bin/aws \
    route53 change-resource-record-sets \
    --hosted-zone-id "$AWS_ZONE_ID" \
    --change-batch "$JSON_CMD"

  # -----------------------------------
  # ---- Update sub-domains -----------
  for domain in ${DNS_SUBDOMAINS[*]}; do
    read -r -d '' JSON_CMD << EOF
    {
      "Comment": "DynDNS update",
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "$domain.$DNS_ROOT_FQDN.",
            "Type": "A",
            "TTL": $DNS_TTL,
            "ResourceRecords": [
              {
                "Value": "$NEW_IP"
              }
            ]
          }
        }
      ]
    }
EOF

    echo "Updating IP from [$OLD_IP] to [$NEW_IP] for ($domain.$DNS_ROOT_FQDN)"
    /usr/local/bin/aws \
      route53 change-resource-record-sets \
      --hosted-zone-id "$AWS_ZONE_ID" \
      --change-batch "$JSON_CMD"

  done # sub-domains

done # main loop