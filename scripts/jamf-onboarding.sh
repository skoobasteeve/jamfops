#!/bin/bash

#### README ####
#
# This script is intended to be used by IT staff who are manually configuring computers for new hires. 
# It must be ran on the user's computer and can be invoked automatically during enrollment or manually via Self Service. 
#
# The goal is to assign the computer to a user and then install packages and configurations specific to their department/team.
# It does this by giving computers a temporary Extension Attribute that adds them to a Smart Computer Group in JAMF. 
#
#### REQUIREMENTS ####
#
# * Corresponding Extension Attribute that locates the temp file (https://github.com/skoobasteeve/jamfops/ext-attributes/onboarding-group-name.sh)
# * Smart Computer Groups in JAMF that add computers with the corresponding extension attribute.
#
# DON'T FORGET TO EDIT THE GROUP LIST ON LINE 35

# Get user email via a prompt.

results=$( /usr/bin/osascript -e "display dialog \"Assign computer to user:\" default answer \"Email address...\" buttons {\"Cancel\",\"OK\"} default button {\"OK\"}" )
username=$( echo "$results" | /usr/bin/awk -F "text returned:" '{print $2}' )

# Create temporary directory and prompt user to choose onboarding group

tempdir="/tmp/.Onboarding"

if [ -d "$tempdir" ];
    then rm -rf "$tempdir"
    fi
mkdir "$tempdir"

#### EDIT THIS LIST ####
# This where you would add the individual groups at your org. Use whatever makes sense for you. 
# Note the formatting and don't break it. 
groupchoice=$( osascript -e 'return choose from list {¬
"DEPARTMENT - TEAM",¬
"DEPARTMENT 2 - TEAM 2",¬
"LAST DEPARTMENT - TEAM 3"}' )

touch /tmp/.Onboarding/"$groupchoice"

# Clean up temp files

find /tmp/.Onboarding -type f -not -name "$groupchoice" -delete

# Run recon and assign email to user

jamf recon -endUsername "$username"

exit 0
