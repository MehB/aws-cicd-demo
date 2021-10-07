#! /bin/sh

started_date=$(date '+%H:%M:%S')
start=`date +%s`
while true; do 
  if [[ $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) == DELETE_IN_PROGRESS ]]
  then
    echo "EKS Cluster status : DELETE IN PROGRESS \n"
    sleep 10
  elif [[ $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) == DELETE_COMPLETE ]]
  then
    echo "EKS Cluster status : SUCCESSFULLY DELETED \n"
    end=`date +%s`
    runtime=$((end-start))
    finished_date=$(date '+%H:%M:%S')
    echo "started at :" $started_date 
    echo "finished at :" $finished_date
    hours=$((runtime / 3600)); minutes=$(( (runtime % 3600) / 60 )); seconds=$(( (runtime % 3600) % 60 )); echo "Total time : $hours h $minutes min $seconds sec"
    break
  else
    echo "EKS Cluster status : $(aws cloudformation describe-stacks --region $EKS_AWS_REGION --stack-name $EKS_STACK_NAME --query "Stacks[*].StackStatus" --output text) \n"
    break
  fi
done