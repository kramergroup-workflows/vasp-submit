# Create Vasp Wapper script
# -----------------------------
# The CASM python library contains a useful wapper that does multiple runs etc. 
# We will repackage that and distribute as driver for Vasp calculations.
FROM rackspacedot/python37 as py

WORKDIR /work
COPY vasp-driver /work/vasp-driver

RUN python -m zipapp -p "/usr/bin/env python" vasp-driver


# Obtain VASP 
# -----------------------------
# The VASP binary cannot be publicly distributed due to license constrains
# and platform specific compilation.
# This build container obtains the binary from a private S3 store such as minio
# using the S3_HOST and access-key and secret arguments
FROM minio/mc as s3

ARG S3_HOST
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY

RUN mc config host add --insecure minio https://$S3_HOST $S3_ACCESS_KEY_ID $S3_SECRET_ACCESS_KEY
RUN mc --insecure cp minio/vasp/vasp5.4.4-iridis5-executables.tar.gz /tmp/vasp5.4.4-iridis5-executables.tar.gz
RUN mc --insecure cp minio/vasp/vasp5.4.4-thomas-executables.tar.gz /tmp/vasp5.4.4-thomas-executables.tar.gz

WORKDIR /bin/iridis5
RUN tar xvzf /tmp/vasp5.4.4-iridis5-executables.tar.gz

WORKDIR /bin/thomas
RUN tar xvzf /tmp/vasp5.4.4-thomas-executables.tar.gz

# -------------------------------------------------------------------------------------------------------------
FROM alpine

# The VASP input files are expected in the folder
VOLUME [ "/data/vasp" ]

# SSH private keys are expected in folder
VOLUME [ "/ssh" ]

# The USERNAME is used to identify the account on the machine
ENV USERNAME "noone"

# CLUSTER defines the used scripts
ENV CLUSTER "iridis5"

# The HOSTNAME of the login node
ENV HOSTNAME "iridis5_a.soton.ac.uk"

# The walltime allowed for the job
ENV WALLTIME "24:00:00"

# Common base folder for all jobs
ENV BASEDIR "workflows"

# The JOB_NAME will be used to identify the calculation
# in the queue
ENV JOB_NAME "vasp"

# The JOB_Type is used by the vasp-driver to determine what type of workflow
# should be initiated
ENV JOB_TYPE "relax"

# The VASP executable to use
ENV VASP vasp.5.4.4.intel.std

# An email will be send to this address when the job
# has completed or was terminated
ENV JOB_EMAIL "noreply@nowhere.com"

RUN apk --no-cache add openssh-client bash gettext
RUN mkdir -p /assets/iridis5 && \
    mkdir -p /assets/thomas
COPY --from=s3 bin/iridis5/* /assets/iridis5/
COPY --from=s3 bin/thomas/* /assets/thomas/
COPY --from=py /work/vasp-driver.pyz /assets/vasp-driver.pyz

COPY build/docker/vasp-submit/entrypoint.sh /entrypoint.sh
COPY scripts/qscript.* /assets

ENTRYPOINT [ "/entrypoint.sh" ]