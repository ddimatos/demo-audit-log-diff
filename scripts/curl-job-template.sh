#!/bin/sh

# Basic script on how to execute a job template on AAP, query until status of job is 'running'
# then download the job log. There is little error handling built into this, current expectations
# are than this executes on a happy path.

ENV_SOURCE_FILE="../.env"
export SEP_LINE_NL="\n-------------------------------------------------------------------------------\n"

# ---------------------------------------------------------------------
# Sourcing the setup file to setup and teardown the demo script
# ---------------------------------------------------------------------

if [ -f "$ENV_SOURCE_FILE" ]; then
  echo "${SEP_LINE_NL}[INFO] Sourcing $ENV_SOURCE_FILE${SEP_LINE_NL}"
  . "$ENV_SOURCE_FILE"
else
  echo "${SEP_LINE_NL}[WARN] There is no environment file $ENV_SOURCE_FILE,
  please be sure to configure script variables'USER', 'HOST' and \
  'MY_ANSIBLE_LIBRARY' in this script${SEP_LINE_NL}"
fi

export AAP_AUTH_TOKEN=${MY_AAP_AUTH_TOKEN:="changme"}
export HOST_IP=${MY_HOST_IP:="hostname"}


# ---------------------------------------------------------------------
# Curl - run job template 9
# ---------------------------------------------------------------------
echo "${SEP_LINE_NL}[INFO] Running job template using AAP REST API${SEP_LINE_NL}"
response=$(curl -s -k -X POST -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/job_templates/9/launch/" |jq )
echo ${response}


# ---------------------------------------------------------------------
# Query - job 9 template
# ---------------------------------------------------------------------
#job_id=$( jq -r  '.id' <<< "${response}" )
job_id=$( echo "${response}"|  jq -r '.id')
sleep 2
echo "${SEP_LINE_NL}[INFO] Get job template status using AAP REST API for job id ${job_id} ${SEP_LINE_NL}"
result=$(curl -s -k -X GET -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/" |jq )
#stat=$( jq -r  '.status' <<< "${result}" )
stat=$( echo "${response}"|  jq -r '.status')

while [ "${stat}" = "running" ]; do
  sleep 1
  result=$(curl -s -k -X GET -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/" |jq )
  #stat=$( jq -r  '.status' <<< "${result}" )
  stat=$( echo "${response}"|  jq -r '.status')
  echo "[INFO] Ansible job template has not completed, status=[${stat}]"
done

echo "${SEP_LINE_NL}[INFO] Ansible job template has completed with status=[${stat}], displaying result${SEP_LINE_NL}"
echo "${result}"

echo "${SEP_LINE_NL}[INFO] Downloading Ansible job template log for further review${SEP_LINE_NL}"
curl -O -k -J -L -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/stdout?format=txt_download"
