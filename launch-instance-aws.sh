showValues() {
  echo "REGION:        $REGION"
  echo "IMAGE_ID:      $IMAGE_ID"
  echo "KEY_NAME:      $KEY_NAME"
  echo "ROLE:          $ROLE"
  echo "PRIVATE_IP:    $PRIVATE_IP"
  echo "NEW_HOST:      $NEW_HOST"
  echo "SG_IDS:        $SG_IDS"
  echo "INSTANCE_TYPE: $INSTANCE_TYPE"
  echo "VOL_SIZE:      $VOL_SIZE"
  echo "SUBNET_ID:     $SUBNET_ID"
  echo "EBS_OPT:       $EBS_OPT"
  echo "TAGS:          $TAGS"
  echo "USER_DATA:     $USER_DATA"
  echo ""
}

REGION=${1}
IMAGE_ID=${2}
KEY_NAME=${3}
ROLE=${4}
PRIVATE_IP=${5}
NEW_HOST=${6}
SG_IDS=${7}
INSTANCE_TYPE=${8}
VOL_SIZE=${9}
SUBNET_ID=${10}
EBS_OPT=${11}
TAGS="Key=Name,Value=${NEW_HOST} ${@:12}"
USER_DATA="cloudera-managerizer-${NEW_HOST}.sh"

#showValues && exit

INSTANCE_ID=`
aws --output text --region ${REGION} \
  ec2 run-instances \
  --image-id ${IMAGE_ID} \
  --key-name ${KEY_NAME} \
  --security-group-ids ${SG_IDS} \
  --user-data file://${USER_DATA} \
  --instance-type ${INSTANCE_TYPE} \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=${VOL_SIZE},VolumeType=gp2}" \
  --subnet-id ${SUBNET_ID} \
  --private-ip-address ${PRIVATE_IP} \
  $([ "${EBS_OPT}" == "yes" ] && echo --ebs-optimized || echo --no-ebs-optimized) \
  --associate-public-ip-address | sed -n 2,2p | awk '{print $7}'
`
echo "create instance $INSTANCE_ID for ${NEW_HOST}"

if [ "${INSTANCE_ID}" != "" ]; then
  aws --region ${REGION} \
    ec2 create-tags \
    --resources ${INSTANCE_ID} \
    --tags ${TAGS}
fi
