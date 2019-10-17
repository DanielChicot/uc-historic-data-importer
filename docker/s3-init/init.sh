#! /bin/bash

source ./environment.sh

aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
aws configure set default.region "${AWS_REGION}"
aws configure set region "${AWS_REGION}"
aws configure list

declare -i BUCKET_COUNT=$(aws_s3 ls | grep $S3_BUCKET | wc -l)

if [[ $BUCKET_COUNT -eq 0 ]]; then
    aws_s3 mb "s3://${S3_BUCKET}"
    aws_s3api put-bucket-acl --bucket "${S3_BUCKET}" --acl public-read
else
    stderr Not making bucket \'$S3_BUCKET\': already exists.
fi

. ./venv/bin/activate

if create_sample_data; then

    dd if=/dev/zero of=a-spurious.file bs=10M count=1

    aws_s3 cp a-spurious.file s3://${S3_BUCKET}/${S3_PREFIX}

    ls *.json.gz.enc | head -n1 | xargs rm -v

    for file in *.json.gz.enc *.json.gz.encryption.json; do
        aws_s3 cp $file s3://${S3_BUCKET}/${S3_PREFIX}
    done

    aws_s3 ls $S3_BUCKET/$S3_PREFIX
fi