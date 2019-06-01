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

RUN apk add --no-cache python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools six && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

COPY --from=py /work/vasp-driver.pyz /assets/vasp-driver.pyz
COPY build/docker/vasp-collect/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "python3", "/assets/vasp-driver.pyz", "properties" ]