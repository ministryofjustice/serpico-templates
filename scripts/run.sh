#!/bin/bash

SQUASH_JSON_FILE='template_findings.json'
CURL_COOKIE_JAR='/tmp/curl_cookie_jar'

# Check CWD
CURRENT_WORKING_DIR=`pwd | awk -F '/' '{ print $NF }'`
if [[ "$CURRENT_WORKING_DIR" != "serpico-templates" ]]; then
    echo "Current working directory should be serpico-template repo"
    exit 1
fi

# Update template repo
git pull

# Check if docker and screen is installed
#hash screen 2>/dev/null || { echo "screen not found but required"; exit 1; }
hash docker 2>/dev/null || { echo "docker not found but required"; exit 1; }

# Pull docker image
# Run instance
# Update username/password
# Set CVSS reporting
# Run Serpico
docker build . -t moj_serpico

docker run -d -p 127.0.0.1:443:8443 -it moj_serpico /bin/bash -l -c \
    "/usr/bin/yes | ruby /Serpico/scripts/manage_users.rb -u administrator -p password;
     sed -i 's#\"cvss\": false,#\"cvss\": false,\n  \"cvssv3\": true,#' /Serpico/config.json;
     ruby /Serpico/serpico.rb" || { echo "Already have a container listening on 443?"; exit 1; }

sleep 2

echo -n "Importing templates..."

# Wait
sleep 2

###
### REPORT TEMPLATES
###

# Debug
#export HTTPS_PROXY=http://localhost:8080/

# Get cookie....
curl -s -k -c $CURL_COOKIE_JAR -X $'GET' \
    -H $'Host: localhost' \
    -H $'User-Agent: MoJ' \
    -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H $'Accept-Language: en-GB,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $'DNT: 1' \
    -H $'Connection: close' -H $'Upgrade-Insecure-Requests: 1' $'https://localhost/reports/list' > /dev/null

# Login
curl -s -k -X $'POST' \
    -H $'Host: localhost' \
    -H $'User-Agent: MoJ' \
    -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H $'Accept-Language: en-GB,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' \
    -H $'Referer: https://localhost/reports/list' -H $'Content-Type: application/x-www-form-urlencoded' \
    -H $'Content-Length: 40' -b $CURL_COOKIE_JAR -H $'DNT: 1' -H $'Connection: close' -H $'Upgrade-Insecure-Requests: 1' \
    --data-binary $'username=administrator&password=password' $'https://localhost/login' > /dev/null

# Perform redirect which curl doesn't get right in the above request
# (with -L curl tries to POST to /)
# This (probably) completes authentication
curl -L -i -s -k -X $'GET' \
    -H $'Host: localhost' \
    -H $'User-Agent: MoJ' \
    -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H $'Accept-Language: en-GB,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' \
    -H $'Referer: https://localhost/reports/list' -b $CURL_COOKIE_JAR -H $'DNT: 1' -H $'Connection: close' \
    -H $'Upgrade-Insecure-Requests: 1' $'https://localhost/' > /dev/null

# Add templates
function add_templates() {
    for template_report in template_reports/$1; do
        TEMPLATE_REPORT_FRIENDLY=`echo $template_report | sed 's#.*/##g' | sed 's#\..*##g'`
        curl -s -L -k -b $CURL_COOKIE_JAR \
            -H $'User-Agent: MoJ' \
            -H $'Accept-Language: en-GB,en;q=0.5' \
            -F "report_type=$TEMPLATE_REPORT_FRIENDLY" \
            -F "description=$TEMPLATE_REPORT_FRIENDLY" \
            -F "file=@$template_report" $'https://localhost/admin/templates/add' > /dev/null
    done
}

# docx
add_templates "*.docx"
# DOCX
add_templates "*.DOCX"

echo " done"

###
### ISSUE TEMPLATES
###

echo -n "Squashing issues..."

# Squashing the JSON objects into one file results in quicker import into Serpico than separate files
scripts/squash_findings.py --json-file $SQUASH_JSON_FILE --template-directory template_findings

echo " done"

echo -n "Importing issues..."

curl -s -i -k -b $CURL_COOKIE_JAR \
    -H $'User-Agent: MoJ' \
    -H $'Accept-Language: en-GB,en;q=0.5' \
    -F "file=@$SQUASH_JSON_FILE" \
    -F "approved=on" $'https://localhost/master/import' > /dev/null

rm $SQUASH_JSON_FILE

echo " done"
echo
echo "Blow this instance away after report for test is complete. The only way to update automatically is by running this script again."
echo "When you've completed report make sure you export / download the following:"
echo "1. Report DOCX"
echo "2. Report JSON"
echo "3. Report attachments"
echo "4. Any report templates you've worked on"
echo "5. Any finding templates you've worked on (JSON)"
echo
echo "Add report templates by sticking them in template_reports directory."
echo
echo "Add finding templates by:"
echo "1. Creating them in web application"
echo "2. Exporting all findings in JSON format"
echo "3. Running the scripts/new_findings.py script to isolate new finding templates and split them out appropriately"
echo "4. Committing code"
echo
echo "Username: administrator"
echo "Password: password"
echo "Serpico available at https://127.0.0.1/"
exit 0
