#!/bin/sh

# Intended to be used with the onboarding script (https://github.com/skoobasteeve/jamfops/scripts/onboarding.sh)

for file in /tmp/.Onboarding/*; do
	Team="${file##*/}"
done

echo "<result>$Team</result>"