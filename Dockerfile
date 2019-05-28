    
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

WORKDIR /bin
RUN tar xvzf /tmp/vasp5.4.4-iridis5-executables.tar.gz

# -------------------------------------------------------------------------------------------------------------
FROM alpine

# The VASP input files are expected in the folder
VOLUME [ "/data/vasp" ]

# SSH private keys are expected in folder
VOLUME [ "/ssh" ]

# The USERNAME is used to identify the account on the machine
ENV USERNAME "noone"

# The HOSTNAME of the login node
ENV HOSTNAME "iridis5_a.soton.ac.uk"

# Common base folder for all jobs
ENV BASEDIR "workflows"

# The JOB_NAME will be used to identify the calculation
# in the queue
ENV JOB_NAME "vasp"

# An email will be send to this address when the job
# has completed or was terminated
ENV JOB_EMAIL "noreply@nowhere.com"

RUN apk --no-cache add openssh-client bash gettext
COPY --from=s3 bin/* /bin/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]