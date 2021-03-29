#!/bin/bash

#### README ####
#
# This script is intended to run as a cron job on an always-on macOS machine. 
# It works as part of an overall git-focused workflow where the master/main branch is the source-of-truth for your AutoPKG recipe overrides.
# 
# It does the following:
# 1. Git pull from the master/main branch of recipe overrides repository.
# 2. Updates your AutoPkgr recipe list for scheduled runs.
# 3. Sends notifications to Slack for new, deleted, and modified recipes.
#
#### REQUIREMENTS ####
# 
# * Always-on macOS machine
# * Git
# * AutoPkgr and all dependencies
#
#### USER VARIABLES ####

# Github repo where your AutoPkg recipe overrides are stored
github_repo=""
overrides_folder=""

# AutoPkgr recipe list file, default is "$HOME/Library/Application Support/AutoPkgr/recipe_list.txt"
recipe_list_file=""

# Generate from your Slack workspace for notifications
slack_webhook_url=""


#### DON'T EDIT BELOW THIS LINE ####

recipe_list_file_old="/private/tmp/recipe_list.old.txt"
recipes="$(find "$overrides_folder" -type f -name "*.recipe")"
progname="$(basename "$0")"
IFS=$'\n'

#### FUNCTIONS ####

# Error handling
error_exit() {

    echo "${progname}: ${1:-"Unknown Error"}" 1>&2
    curl -X POST "$slack_webhook_url" -H "Content-type: application/json" --data \
    '{"type": "mrkdwn", "text": '"${progname}"': '"${1:-"Unknown Error"}"'"}'
    exit 1

}

# Creates recipe_list.txt based on recipes cloned from Github repo
update_recipe_list() {

    for recipe in $recipes; do
        recipe_list_name=$(xmllint --xpath 'string(//key[.="Identifier"]/following-sibling::string[1])' "$recipe")
        echo "$recipe_list_name" >> "$recipe_list_file"
    done

}

# Updates parent recipe repos for any new or modified recipes
update_recipe_repos() {

    modified_recipes="$(find "$overrides_folder" -type f -name "*.recipe" -mtime -30s)"
    recipe_owners=()
    recipe_repos=()

    for modified_recipe in $modified_recipes; do
        recipe_owner=$(/usr/libexec/PlistBuddy -c "Print :ParentRecipeTrustInfo:parent_recipes:" "$modified_recipe" | grep "= Dict {" | cut -c 16- | cut -f1 -d".")
        recipe_owners+=("$recipe_owner")
    done
    
    for owner in ${recipe_owners[*]}; do
        recipe_repo=$(autopkg list-repos | awk -F '[()]' '{print $2}' | grep --ignore-case "$owner")
        if [ -z "$recipe_repo" ]; then
            autopkg repo-add https://github.com/autopkg/"$owner"-recipes.git
        fi
            
        if [[ ! ${recipe_repos[*]} =~ ${recipe_repo} ]]; then
            recipe_repos+=("$recipe_repo")
        fi
    done

    for repo in ${recipe_repos[*]}; do
        autopkg repo-update "$repo"
    done

} 

# Gets any new recipes added to the list and sends them to #autopkg-alerts in Slack
slack_new_recipes() {

    new_recipes="$(diff "$recipe_list_file" "$recipe_list_file_old" | grep "< local." | cut -c 3-)"

    if [[ "$new_recipes" > /dev/null ]]; then
        curl -X POST "$slack_webhook_url" -H "Content-type: application/json" --data \
        '{"type": "mrkdwn", "text": ":man_dancing: *New recipes were added to AutoPkgr Prod* :man_dancing:\n\n'"$new_recipes"'"}'
    fi

}

# Gets any recipes that were removed from the list and sends them to #autopkg-alerts in Slack
slack_removed_recipes() {

    removed_recipes="$(diff "$recipe_list_file" "$recipe_list_file_old" | grep "> local." | cut -c 3-)"

    if [[ "$removed_recipes" > /dev/null ]]; then
        curl -X POST "$slack_webhook_url" -H "Content-type: application/json" --data \
        '{"type": "mrkdwn", "text": ":bomb: *Removed recipes from AutoPkgr Prod* :bomb:\n\n'"$removed_recipes"'"}'
    fi

}

# Gets any existing recipes that were modified and sends them to #autopkg-alerts in Slack
slack_modified_recipes() {

    modified_recipes="$(find "$overrides_folder" -type f -name "*.recipe" -mtime -30s)"
    modified_recipe_list=()

    for modified_recipe in $modified_recipes; do
        modified_recipe_name=$(xmllint --xpath 'string(//key[.="Identifier"]/following-sibling::string[1])' "$modified_recipe")
        modified_recipe_list+=("$modified_recipe_name")
    done

    modified_only=$(diff <(echo "${modified_recipe_list[*]}") <(echo "$new_recipes") | grep "< local." | cut -c 3-)

    if [[ "$modified_only" > /dev/null ]]; then
        curl -X POST "$slack_webhook_url" -H "Content-type: application/json" --data \
        '{"type": "mrkdwn", "text": ":lower_left_ballpoint_pen: *Modified recipes on AutoPkgr Prod* :lower_left_ballpoint_pen:\n\n'"$modified_only"'"}'
    fi

}

### SCRIPT ####

# Pull the latest version of the main branch for it-autopkg
git -C "$github_repo" pull || error_exit "$LINENO: An error has occurred during git pull"

# Create copy of recipe_list.txt before removing it and creating a new one, then run the functions.
if [ -f "$recipe_list_file" ]; then
    cp "$recipe_list_file" "$recipe_list_file_old"
    rm "$recipe_list_file" 
    update_recipe_list
    update_recipe_repos
    slack_new_recipes
    slack_removed_recipes
    slack_modified_recipes
elif [ ! -f "$recipe_list_file" ]; then
    update_recipe_list
    update_recipe_repos
    recipe_list="$(cat "$recipe_list_file")"
    curl -X POST "$slack_webhook_url" -H "Content-type: application/json" --data \
    '{"type": "mrkdwn", "text": "*A new recipe list was created on AutoPkgr Prod with the following recipes:*\n\n'"$recipe_list"'"}'
else
    error_exit "$LINENO: An error has occurred"
fi

# Print results
printf "\nNew Recipes:\n%s\n\nRemoved Recipes:\n%s\n\nModified Recipes:\n%s\n\n" "$new_recipes" "$removed_recipes" "$modified_only"

# Cleanup
if [ -f "$recipe_list_file_old" ]; then
    rm "$recipe_list_file_old"
fi

exit 0
