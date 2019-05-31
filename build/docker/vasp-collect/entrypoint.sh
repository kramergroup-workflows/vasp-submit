#!/bin/sh

echo "Copying VASP output files"
cd /data/vasp
ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "tar czf - --exclude=vasp --exclude=vasp-driver.pyz --exclude=qscript -C /scratch/$USERNAME/$BASEDIR/$JOB_NAME ." | tar xzf -

if [ $REMOVE = "yes" ];
then
  echo "Removing files from server"
  ssh -i /ssh/id_rsa -oStrictHostKeyChecking=no $USERNAME@$HOSTNAME "rm -rf /scratch/$USERNAME/$BASEDIR/$JOB_NAME"
fi

echo "Compressing intermediate runs"
for f in $(find . -type d -name "run.[0-9]*");
do
  tar czf $f.tar.gz $f && rm -rf $f
done

echo "Checking job completion"
python3 /assets/vasp-driver.pyz check