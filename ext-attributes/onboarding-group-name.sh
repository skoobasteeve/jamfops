#!/bin/sh

# Intended to be used with the onboarding script (https://github.com/skoobasteeve/jamfops/blob/main/scripts/jamf-onboarding.sh)

for file in /tmp/.Onboarding/*; do
	Team="${file##*/}"
done

echo "<result>$Team</result>"
