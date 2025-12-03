#!/bin/sh

# ---------------------------------------------------------------------------------------------------------------------
# Demo script on how to:
# 1) Execute an AAP job template remotely
# 2) Query job status until an entry for 'finished' is made, e.g., "finished": "2025-11-23T08:33:18.159297Z",
# 3) On confirmation the job has 'finished', download the job log.
# 4) There is no error handling in this demo, value checks and more should be performed.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Create a .env file in the root of the project (../.env) and place in it values:
#  export MY_AAP_AUTH_TOKEN="abcdefghijklmnopqrstuvwxyz"
#  export MY_HOST_IP=1.23.456.789
# Optionally, you can export these in the shell, they are not included because they are unique to AAP
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# You must make OEF binaries available to the shell by updating the $PATH , e.g.,
# export PATH=$PATH:/usr/lpp/oef/V1R1M0/bin/
# ---------------------------------------------------------------------------------------------------------------------

ENV_SOURCE_FILE="../.env"
export SEP_LINE_NL="\n-------------------------------------------------------------------------------\n"

# ---------------------------------------------------------------------------------------------------------------------
# Source the '.env' file
# ---------------------------------------------------------------------------------------------------------------------

if [ -f "$ENV_SOURCE_FILE" ]; then
  echo "${SEP_LINE_NL}[INFO] Sourcing $ENV_SOURCE_FILE${SEP_LINE_NL}"
  . "$ENV_SOURCE_FILE"
else
  echo "${SEP_LINE_NL}[WARN] There is no environment file $ENV_SOURCE_FILE,
  please create one in the root project and export vars 'MY_AAP_AUTH_TOKEN' and 'MY_HOST_IP'
  in this script${SEP_LINE_NL}"
fi

export AAP_AUTH_TOKEN=${MY_AAP_AUTH_TOKEN:="changme"}
export HOST_IP=${MY_HOST_IP:="hostname"}


# ---------------------------------------------------------------------------------------------------------------------
# Use 'curl' to connect to AAP and run a job template over using the AAP REST endpoint.
# ---------------------------------------------------------------------------------------------------------------------
echo "${SEP_LINE_NL}[INFO] Running job template using AAP REST API${SEP_LINE_NL}"
response=$(curl -s -k -X POST -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/job_templates/9/launch/" |jq )
echo ${response}


# ---------------------------------------------------------------------------------------------------------------------
# Use 'curl' to query a job templates id and check its status in an loop.
# ---------------------------------------------------------------------------------------------------------------------

# Extract the JOB template ID
job_id=$( echo "${response}"|  jq -r '.id')

# Give AAP a few seconds to complete the job templates execution then evaluate the job templates log for completion.
sleep 2

echo "${SEP_LINE_NL}[INFO] Get job template status using AAP REST API for job id ${job_id} ${SEP_LINE_NL}"
result=$(curl -s -k -X GET -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/" |jq )

# Extract 'finished' status, it will be 'null' until it completes, on completion a time stamp is entered , e.g., "finished": "2025-11-23T08:33:18.159297Z"
stat=$( echo "${result}"|  jq -r '.finished')

# Loop while status is not equal to success (you probably should put a max count on the number of iterations to loop to avoid an infinite loop)
while [ "${stat}" = "null" ]; do
  sleep 2
  result=$(curl -s -k -X GET -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/" |jq )
  stat=$( echo "${result}"|  jq -r '.finished')
  echo "[INFO] Ansible job template has not completed, status=[${stat}]"
done

# Print the job log to STDOUT
echo "${SEP_LINE_NL}[INFO] Ansible job template has completed with status=[${stat}], displaying result${SEP_LINE_NL}"
echo "${result}"

# ---------------------------------------------------------------------------------------------------------------------
# Use 'curl' to download the completed job template log
# ---------------------------------------------------------------------------------------------------------------------
echo "${SEP_LINE_NL}[INFO] Downloading Ansible job template log for further review${SEP_LINE_NL}"
curl -O -k -J -L -H "Authorization: Bearer ${AAP_AUTH_TOKEN}" -H "Content-Type: application/json" "https://${HOST_IP}/api/controller/v2/jobs/${job_id}/stdout?format=txt_download"
