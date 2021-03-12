#!/bin/sh

#### README ####
#
# The below script moves computer groups from one JAMF instance to another. Useful when setting up a sandbox environment that needs to match prod.
#
#### REQUIREMENTS ####
#
# * JAMF user credentials with read/write access to computer groups
#
#### USER VARIABLES ####

# No trailing / please :)
SOURCE_JAMF_URL=""
DEST_JAMF_URL=""

SOURCE_API_USER=""
SOURCE_API_PASS=""
DEST_API_USER=""
DEST_API_PASS=""

# Pulls group ID numbers from JAMF source and sorts them
PROD_GROUPS=$(curl -X GET "$SOURCE_JAMF_URL/JSSResource/computergroups" -H  "accept: application/xml" -u "$SOURCE_API_USER":"$SOURCE_API_PASS" | xml ed -d '//computers' | grep "<id>" | grep -Eo '[0-9]{1,4}' | sort -n)

# Pulls groups from JAMF source and outputs XML files for each group
for id in $PROD_GROUPS; do
    curl -X GET "$SOURCE_JAMF_URL/JSSResource/computergroups/id/$id" -H  "accept: application/xml" -u "$SOURCE_API_USER":"$SOURCE_API_PASS" | xml ed -d '//computers' > /tmp/jamf/"$id".xml;
done

# Pushes groups to JAMF destination from previously created XML files
for group in /tmp/jamf/*; do
    curl -X POST "$DEST_JAMF_URL/JSSResource/computergroups/id/0" -ku "$DEST_API_USER":"$DEST_API_PASS" -T "$group";
done

exit 0