#!/usr/bin/env bash

BRANCH=$1
SHORT_SHA=$2
LOCATION=$3

echo "BRANCH=${BRANCH} COMMIT_SHA=${SHORT_SHA} -- LOCATION--${LOCATION}"
gcloud components install gke-gcloud-auth-plugin --quiet

project_to_branch_map=($(cat /workspace/config/env_mapper.txt))
for mapping in ${project_to_branch_map[@]}; do
  project_id=$(echo ${mapping} | cut -d"~" -f1)
  dag_bucket=$(echo ${mapping} | cut -d"~" -f2 | sed "s/\/dags//g")
  branch=$(echo ${mapping} | cut -d"~" -f3)
  echo "${project_id}--${dag_bucket}--${branch}"

  if [ ${BRANCH} == ${branch} ]; then
    echo "Deploying to Project -- ${project_id}"
    target=${dag_bucket}/data/${SHORT_SHA}
    gcloud config set project ${project_id}
    gsutil -m rsync -r -d dags/ ${target}/
    gcloud config list
    echo "gcloud composer environments run ${project_id} --location ${LOCATION} dags list -- --subdir /home/airflow/gcs/data/${SHORT_SHA}/"
    gcloud composer environments run ${project_id} --location ${LOCATION} dags list -- --subdir /home/airflow/gcs/data/${SHORT_SHA}/
    gsutil -m rm -rf ${target}
  fi
done
