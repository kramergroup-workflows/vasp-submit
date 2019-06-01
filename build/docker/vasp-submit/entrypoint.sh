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

# The first parameter passed to the script is taken as the 
# subpath containing the VASP input files
SUBPATH=$1


# Calculate number of nodes (TODO This should be smarter )
export NUM_NODES=1

# Define the job directory - this is cluster dependent as 
# different clusters have different layouts - as a fallback
# we use a subfolder of the $HOME directory
JOBDIR="~/$BASEDIR/$JOB_NAME"
case $CLUSTER in 
iridis5) 
  JOBDIR="/scratch/$USERNAME/$BASEDIR/$JOB_NAME"
  ;;
thomas)
  JOBDIR="/home/$USERNAME/scratch/$BASEDIR/$JOB_NAME"
  ;;
esac

# Define the job submit command - this is cluster dependent as 
# different clusters have different queue managers - We use
# GridEngine's qsub as the fallback as its still the most popular
SUBMIT="qsub"
case $CLUSTER in 
iridis5) 
  SUBMIT="sbatch"
  ;;
thomas)
  SUBMIT="qsub"
  ;;
esac

# Create a submit script and make sure it's executable
cat /assets/qscript.$CLUSTER | envsubst '$NUM_NODES $JOB_NAME $JOB_EMAIL $JOB_TYPE $WALLTIME' > /data/vasp/$SUBPATH/qscript
chmod u+x /data/vasp/$SUBPATH/qscript

# Make sure the scratch directory exists
echo "Creating job directory"
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "mkdir -p $JOBDIR"


# Copy the input files
# We pipe this through a tar command because it allows to write files to a folder without wildcards (which are problematic in scp)
echo "Copying VASP input files"
cd /data/vasp/$SUBPATH
tar czf - -C /data/vasp/$SUBPATH * | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd $JOBDIR; tar xzf - )"

# Copy vasp driver
scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/vasp-driver.pyz $USERNAME@$HOSTNAME:$JOBDIR/vasp-driver.pyz

# Copy vasp
#scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/$VASP $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME/vasp
echo "Copying VASP executable"
cd /assets/$CLUSTER
tar czf - -C /assets/$CLUSTER $VASP | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd $JOBDIR ; tar xzf - ; mv $VASP vasp )"

# Submit job
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "cd $JOBDIR && $SUBMIT qscript"