# JamfOps
### Useful scripts and workflows to help automate your JAMF environment
* [Automate package updates with AutoPkg](https://github.com/skoobasteeve/jamfops/blob/readme-diagram-updates/README.md#automate-package-updates-with-autopkg)
* [New hire onboarding with "low-touch" deployment](https://github.com/skoobasteeve/jamfops/tree/readme-diagram-updates#new-hire-onboarding-with-low-touch-deployment)
<br>

## Automate package updates with AutoPkg
The below diagram is an overview of how the files in this repo, combined with other incredible open source tools (Git, [AutoPkg](https://github.com/autopkg/autopkg), [AutoPkgr](https://github.com/lindegroup/autopkgr), [JSSImporter](https://github.com/jssimporter/JSSImporter), can help you implement basic automation and GitOps workflows to your JAMF package deployments.

![autopkg-workflow](https://user-images.githubusercontent.com/36998292/112185440-9987ad00-8bd6-11eb-9263-c896ad2eca54.jpeg)

### Order of operations
1. Create and test AutoPkg JSS recipe overrides locally on your Mac
2. Push your overrides to a common repo for your IT team and create a Pull Request
3. Run automated testing on the recipe override(s) with Github Actions ([action](https://github.com/skoobasteeve/jamfops/blob/main/github-actions/autopkg-recipe-test.yml))
4. After successful testing and review, merge the Pull Request with main/master
5. Always-on Mac running AutoPkgr pulls latest recipes from main/master with a cron job and adds them to the AutoPkgr recipe list, then notifies your team via Slack  notifications. ([script](https://github.com/skoobasteeve/jamfops/blob/main/autopkg/autopkg-pull-recipes.sh))
6. AutoPkgr runs recipes on a schedule and sends Slack notifications for new packages and errors.

### Requirements
1. An always-on macOS device or cloud instance
2. AutoPkg, AutoPkgr, JSS Importer, and Git installed on both a local Mac and an always-on device.
3. JAMF production instance
4. JAMF testing instance
5. Github account with dedicated repository for recipe overrides
6. Slack instance with Incoming Webhooks installed (for notifications)
7. Files in this repo

<br>

## New hire onboarding with "low-touch" deployment

While the much-praised concept of Zero-touch Deployment is great in theory, there are many practical reasons why an organization might choose a more traditional manual approach. The [jamf-onboarding](https://github.com/skoobasteeve/jamfops/blob/main/scripts/jamf-onboarding.sh) script and [onboarding-group-name](https://github.com/skoobasteeve/jamfops/blob/main/ext-attributes/onboarding-group-name.sh) extension attribute in this repo allows technicians to easily:

1. Assign a computer to a JAMF user
2. Place the computer in a specific "onboarding group" and run policies scoped to that group

![onboard_script](https://user-images.githubusercontent.com/36998292/112203212-aad9b500-8be8-11eb-9415-45a7ae1f5b19.gif)

### Order of operations
1. Unbox computer and create user
2. Enroll computer in JAMF if not already done via Automated Enrollment
3. Run script via Self Service or automatically via enrollment policy ([script](https://github.com/skoobasteeve/jamfops/blob/main/scripts/jamf-onboarding.sh))
4. Enter email of user to assign them
5. Choose group to assign computer, usually based on department/team
6. Group is populated via extension attribute + corresponding Smart Group ([extension attribute](https://github.com/skoobasteeve/jamfops/blob/main/ext-attributes/onboarding-group-name.sh))

### Requirements
1. Physical or remote access to new computer
2. [jamf-onboarding](https://github.com/skoobasteeve/jamfops/blob/main/scripts/jamf-onboarding.sh) script added to JAMF and customized with your own group names
3. [onboarding-group-name](https://github.com/skoobasteeve/jamfops/blob/main/ext-attributes/onboarding-group-name.sh) extension attribute added to your JAMF environment
4. Smart Groups created in JAMF that correspond to group names from previous step
5. Policies scoped to those Smart Groups
