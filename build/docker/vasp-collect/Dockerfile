# Create Vasp Wapper script
# -----------------------------
# The CASM python library contains a useful wapper that does multiple runs etc. 
# We will repackage that and distribute as driver for Vasp calculations.
FROM rackspacedot/python37 as py

WORKDIR /work
COPY vasp-driver /work/vasp-driver

RUN python -m zipapp -p "/usr/bin/env python" vasp-driver

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

# Common base folder for all jobs
ENV BASEDIR "workflows"

# The JOB_NAME will be used to identify the calculation
# in the queue
ENV JOB_NAME "vasp"

# Job files will be removed after collection from the host
# if REMOVE is set to 'yes'
ENV REMOVE "yes"

RUN apk add --no-cache python3 openssh-client && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools six && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

COPY --from=py /work/vasp-driver.pyz /assets/vasp-driver.pyz
COPY build/docker/vasp-collect/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]