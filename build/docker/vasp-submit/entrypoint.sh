#!/bin/bash

# Check environment variables
if [ "$USERNAME" = "noone" ];
then
  echo "ERROR: No USERNAME provided"
  exit 1
fi

if [ ! -f "/ssh/id_rsa" ];
then
  echo "ERROR: RSA private-key file (/ssh/id_rsa) missing"
  exit 1
fi

# Calculate number of nodes (TODO This should be smarter )
export NUM_NODES=1

# Create a submit script and make sure it's executable
cat /assets/qscript.$CLUSTER | envsubst '$NUM_NODES $JOB_NAME $JOB_EMAIL $JOB_TYPE $WALLTIME' > /data/vasp/qscript
chmod u+x /data/vasp/qscript

# Make sure the scratch directory exists
echo "Creating job directory"
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "mkdir -p /scratch/$USERNAME/$BASEDIR/$JOB_NAME"

SUBPATH=$1

# Copy the input files
# We pipe this through a tar command because it allows to write files to a folder without wildcards (which are problematic in scp)
echo "Copying VASP input files"
cd /data/vasp/$1
tar czf - -C /data/vasp * | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME; tar xzf - )"

# scp -i /ssh/id_rsa -oStrictHostKeyChecking=no -r /data/vasp/* $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME

# Copy vasp driver
scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/vasp-driver.pyz $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME/vasp-driver.pyz

# Copy vasp
#scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/$VASP $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME/vasp
echo "Copying VASP executable"
cd /assets/$CLUSTER
tar czf - -C /assets/$CLUSTER $VASP | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME ; tar xzf - ; mv $VASP vasp )"

# Submit job
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME && sbatch qscript"