#!/usr/bin/env bash


export DEVOPS_ACT_NO=xxxxxxxxx
export DEV_ACT_NO=xxxxxxxxxxxx
export QA_ACT_NO=xxxxxxxxxx
export PROD_ACT_NO=xxxxxxxxxxxx
export DEVOPS_CHKOUT_S3=xxxxxxxxx
export DEV_CODECOMMIT_REPO=xxxxxxxxxxx
export GLUE_PIPELINE_NAME=xxxxxxxxxxxx
export QA_SCRIPT_BUCKET=xxxxxxxxx
export PROD_SCRIPT_BUCKET=xxxxxxxxx


for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s/DEVOPS_ACT_NO/$DEVOPS_ACT_NO/g; s/DEV_ACT_NO/$DEV_ACT_NO/g; s/QA_ACT_NO/$QA_ACT_NO/g; s/PROD_ACT_NO/$PROD_ACT_NO/g; s/DEVOPS_CHKOUT_S3/$DEVOPS_CHKOUT_S3/g; s/DEV_CODECOMMIT_REPO/$DEV_CODECOMMIT_REPO/g; s/GLUE_PIPELINE_NAME/$GLUE_PIPELINE_NAME/g; s/QA_SCRIPT_BUCKET/$QA_SCRIPT_BUCKET/g; s/PROD_SCRIPT_BUCKET/$PROD_SCRIPT_BUCKET/g" $fname
done


create_kms_command="aws kms create-key --description \"key for cross account glue deployment\" --query KeyMetadata.Arn --profile devops --output text"
devops_kms_arn=$(eval $create_kms_command)
echo $devops_kms_arn

export DEVOPS_KMS_ARN=$devops_kms_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|DEVOPS_KMS_ARN|$DEVOPS_KMS_ARN|g" $fname
done

aws kms create-alias     --alias-name alias/cross-account-glue-key     --target-key-id $devops_kms_arn	  --profile devops 
aws kms put-key-policy     --policy-name default     --key-id $devops_kms_arn    --policy file://devops-create-kms.json  --profile devops

######### DEV STARTS
create_codecommit_access_role_command="aws iam create-role --role-name codecommit-glue-ptpeline-role --assume-role-policy-document file://dev_code_commit_role.json --query Role.Arn --output text --profile dev"

dev_codecommit_role_arn=$(eval $create_codecommit_access_role_command)
echo $dev_codecommit_role_arn

export DEV_CODECOMMIT_ROLE_ARN=$dev_codecommit_role_arn
for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|DEV_CODECOMMIT_ROLE_ARN|$DEV_CODECOMMIT_ROLE_ARN|g" $fname
done


create_codecommit_access_policy_command="aws iam create-policy --policy-name codecommit-glue-ptpeline-policy --policy-document file://dev_code_commit_policy.json --query Policy.Arn --output text --profile dev"

codecommit_access_policy=$(eval $create_codecommit_access_policy_command)
echo $codecommit_access_policy

aws iam attach-role-policy --role-name codecommit-glue-ptpeline-role --policy-arn $codecommit_access_policy --profile dev

######### DEV  ENDS

######### QA  STARTS
create_cloudformation_glue_role_command="aws iam create-role --role-name qa-cfn-glue-role --assume-role-policy-document file://qa-prod-cfn-glue-role.json --query Role.Arn --output text --profile qa"
qa_cfn_role_arn=$(eval $create_cloudformation_glue_role_command)
echo $qa_cfn_role_arn

export QA_CFN_ROLE_ARN=$qa_cfn_role_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|QA_CFN_ROLE_ARN|$QA_CFN_ROLE_ARN|g" $fname
done



create_codepipeline_cfn_glue_role_command="aws iam create-role --role-name qa-codepipleine-cfn-glue-role --assume-role-policy-document file://qa-prod-codepipleine-cfn-glue-role.json --query Role.Arn --output text --profile qa"
qa_pipeline_cfn_role_arn=$(eval $create_codepipeline_cfn_glue_role_command)
echo $qa_pipeline_cfn_role_arn

export QA_PIPELINE_CFN_ROLE_ARN=$qa_pipeline_cfn_role_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|QA_PIPELINE_CFN_ROLE_ARN|$QA_PIPELINE_CFN_ROLE_ARN|g" $fname
done

create_codepipeline_cfn_glue_policy_command="aws iam create-policy --policy-name qa-codepipleine-cfn-glue-policy --policy-document file://qa-prod-codepipleine-cfn-glue-policy.json --query Policy.Arn --output text --profile qa"
codepipeline_cfn_glue_policy_arn=$(eval $create_codepipeline_cfn_glue_policy_command)
echo $codepipeline_cfn_glue_policy_arn



aws iam attach-role-policy --role-name qa-cfn-glue-role --policy-arn $codepipeline_cfn_glue_policy_arn --profile qa
aws iam attach-role-policy --role-name qa-codepipleine-cfn-glue-role --policy-arn $codepipeline_cfn_glue_policy_arn --profile qa

aws s3api create-bucket --bucket $QA_SCRIPT_BUCKET --region us-east-1 --profile qa

######### QA  ENDS


######### PROD  STARTS

prod_create_cloudformation_glue_role_command="aws iam create-role --role-name prod-cfn-glue-role --assume-role-policy-document file://qa-prod-cfn-glue-role.json --query Role.Arn --output text --profile prod"
prod_cfn_role_arn=$(eval $prod_create_cloudformation_glue_role_command)
echo $prod_cfn_role_arn

export PROD_CFN_ROLE_ARN=$prod_cfn_role_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|PROD_CFN_ROLE_ARN|$PROD_CFN_ROLE_ARN|g" $fname
done



prod_create_codepipeline_cfn_glue_role_command="aws iam create-role --role-name prod-codepipleine-cfn-glue-role --assume-role-policy-document file://qa-prod-codepipleine-cfn-glue-role.json --query Role.Arn --output text --profile prod"
prod_pipeline_cfn_role_arn=$(eval $prod_create_codepipeline_cfn_glue_role_command)
echo $prod_pipeline_cfn_role_arn

export PROD_PIPELINE_CFN_ROLE_ARN=$prod_pipeline_cfn_role_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|PROD_PIPELINE_CFN_ROLE_ARN|$PROD_PIPELINE_CFN_ROLE_ARN|g" $fname
done

prod_create_codepipeline_cfn_glue_policy_command="aws iam create-policy --policy-name prod-codepipleine-cfn-glue-policy --policy-document file://qa-prod-codepipleine-cfn-glue-policy.json --query Policy.Arn --output text --profile prod"
prod_codepipeline_cfn_glue_policy_arn=$(eval $prod_create_codepipeline_cfn_glue_policy_command)
echo $prod_codepipeline_cfn_glue_policy_arn



aws iam attach-role-policy --role-name prod-cfn-glue-role --policy-arn $prod_codepipeline_cfn_glue_policy_arn --profile prod
aws iam attach-role-policy --role-name prod-codepipleine-cfn-glue-role --policy-arn $prod_codepipeline_cfn_glue_policy_arn --profile prod

aws s3api create-bucket --bucket $PROD_SCRIPT_BUCKET --region us-east-1 --profile prod

######### PROD  ENDS

######### DEVOPS  STARTS



create_pipeline_execution_role_command="aws iam create-role --role-name glue-pipeline-execution-role --assume-role-policy-document file://devops-codepipleine-role.json --query Role.Arn --output text --profile devops"

pipeline_execution_role_arn=$(eval $create_pipeline_execution_role_command)
echo $pipeline_execution_role_arn

export PIPELINE_EXECUTION_ROLE_ARN=$pipeline_execution_role_arn

for fname in `ls *.json`
do
sed --in-place='.bak'  -e "s|PIPELINE_EXECUTION_ROLE_ARN|$PIPELINE_EXECUTION_ROLE_ARN|g" $fname
done


create_pipeline_execution_policy_command="aws iam create-policy --policy-name glue-pipeline-execution-policy --policy-document file://devops-codepipleine-policy.json --query Policy.Arn --output text --profile devops"

pipeline_execution_policy_arn=$(eval $create_pipeline_execution_policy_command)
echo $pipeline_execution_policy_arn


aws iam attach-role-policy --role-name glue-pipeline-execution-role --policy-arn $pipeline_execution_policy_arn --profile devops


aws s3api create-bucket --bucket $DEVOPS_CHKOUT_S3 --region us-east-1 --profile devops
aws s3api put-bucket-policy     --bucket $DEVOPS_CHKOUT_S3     --policy file://devops-s3-bucket-policy.json --profile devops

aws s3api put-bucket-encryption --bucket $DEVOPS_CHKOUT_S3 --server-side-encryption-configuration file://devops-s3-bucket-kms-policy.json  --profile devops


aws codepipeline create-pipeline --cli-input-json file://devops-create-pipeline.json --profile devops

######### DEVOPS  ENDS








