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

# Create a submit script
envsubst '$NUM_NODES $JOB_NAME $JOB_EMAIL' > /data/vasp/qscript <<"EOF"
#!/bin/bash
#SBATCH --ntasks-per-node=40     # Tasks per node
#SBATCH --nodes=$NUM_NODES    # Number of nodes requested
#SBATCH --time=12:00:00          # walltime
#SBATCH --job-name=$JOB_NAME
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$JOB_EMAIL

VASP="vasp"

module load intel-mpi/2018.1.163
module load intel-compilers/2018.1.163
module load intel-mkl/2018.1.163
moudle load python 

echo "Run directory: $SLURM_SUBMIT_DIR"
cd $SLURM_SUBMIT_DIR

# mpirun -np 40 $SLURM_SUBMIT_DIR/$VASP
export PATH=$(pwd):$PATH
python vasp-driver.pyz $JOB_TYPE
EOF

# Mak sure script is executable
chmod u+x /data/vasp/qscript

# Make sure the scratch directory exists
echo "Creating job directory"
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "mkdir -p /scratch/$USERNAME/$BASEDIR"

# Copy the input files
# We pipe this through a tar command because it allows to write files to a folder without wildcards (which are problematic in scp)
echo "Copying VASP input files"
cd /data/vasp
tar czf - -C /data/vasp * | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME; tar xzf - )"

# scp -i /ssh/id_rsa -oStrictHostKeyChecking=no -r /data/vasp/* $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME

# Copy vasp driver
scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/vasp-driver.pyz $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME/vasp-driver.pyz

# Copy vasp
#scp -i /ssh/id_rsa -oStrictHostKeyChecking=no /assets/$VASP $USERNAME@$HOSTNAME:/scratch/$USERNAME/$BASEDIR/$JOB_NAME/vasp
echo "Copying VASP executable"
cd /assets
tar czf - -C /assets $VASP | ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "( cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME ; tar xzf - ; mv $VASP vasp )"

# Submit job
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "cd /scratch/$USERNAME/$BASEDIR/$JOB_NAME && sbatch qscript"