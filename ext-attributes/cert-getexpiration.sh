#!/bin/bash
#### README ####
#
# This extension attribute finds the expiration date of a certificate and reports the remaining days before expiration to JAMF. 
# If you have more than one certificate with the same Common Name, it uses the expiration date of the latest valid certificate. 
#
#### USER VARIABLES ####

# Fill with full or partial Common Name of the certificate
CERT_CN=""

cert-exp-dates () {
    
    /usr/bin/security find-certificate -a -c $CERT_CN -p > /tmp/certs.pem

    # This while loop shamelessly pilfered from a Stack Overflow answer: https://stackoverflow.com/questions/56412146/is-it-possible-to-loop-through-osx-keychain-certificates-in-a-bash-array
    # Loops through each certificate and pulls a list of expiration dates
    while read -r line; do
        if [[ "$line" == *"--BEGIN"* ]]; then
            cert=$line
        else
            cert="$cert"$'\n'"$line"
            if [[ "$line" == *"--END"* ]]; then
                echo "$cert" > /tmp/checkcert.pem
                notafter=$(openssl x509 -noout -enddate -in /tmp/checkcert.pem | cut -d= -f 2)
                # Convert to ISO 8601
                dates=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$notafter" +"%Y%m%d")
                echo "$dates"
            fi
        fi
    done < /tmp/certs.pem
}

# Only show expiration of most recent certificate
exp_date="$(cert-exp-dates | sort -n | tail -n1)"

# Report a null value and exit script if there are no matching certificates
if [ -z "$exp_date" ]; then
    echo "<result></result>"
    exit 0
fi

# Calculate days between today and expiration date
days_remain=$(( ($(date -jf %Y%m%d "$exp_date" +%s) - $(date +%s) ) / 86400))

# Report for JAMF
echo "<result>$days_remain</result>"

# Cleanup
rm /tmp/certs.pem

exit 0
