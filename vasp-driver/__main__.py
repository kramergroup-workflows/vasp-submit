#!/usr/bin/env python

import sys
import math
import os

from casm.vasp import Relax, run
from casm.vasp.io import job_complete

def factor_int(n):
  '''
  Find two integers as close to squares as possible
  
  Source: https://stackoverflow.com/questions/39248245/factor-an-integer-to-something-as-close-to-a-square-as-possible
  '''
  nsqrt = math.ceil(math.sqrt(n))
  solution = False
  val = nsqrt
  while not solution:
    val2 = int(n/val)
    if val2 * val == float(n):
      solution = True
    else:
      val-=1
  return val, val2


def parallelisation_pattern(ncpus):
  '''
  Determine the parallelisation pattern. 

  On a machine like Iridis with a large number of cores per CPU, 
  running too many bands on the same node can lead to memory issues. 

  Experience has shown that NCORE=10 is a sensible option for Iridis5.
  Parallesation across bands and k-points will be balanced as much as 
  possible to get to the total number of MPI processes.
  '''

  if ncpus is None:
    if "PBS_NP" in os.environ:
      ncpus = int(os.environ["PBS_NP"])
    elif "SLURM_NTASKS" in os.environ:
      ncpus = int(os.environ["SLURM_NTASKS"])
    else:
      ncpus = 1
  
  # Try to balance parallelisation over 
  # bands and k-points to be roughly even
  ncore = min(10,ncpus)
  if ncpus > 10:
    npar,kpar = factor_int(ncpus/ncore)
  else:
    npar = 1
    kpar = 1
    
  return ncore,npar,kpar




def run_simple(ncpus=None):
  '''
  Start vasp as is without any complex reruns or substantial
  editing of the vasp input files.

  There is an option to change some platform-dependent things like NCORE,KPAR, etc.
  We will operate with NCORE=10 (which seems to be a reasonable value on Iridis5)
  '''

  ncore,npar,kpar = parallelisation_pattern(ncpus) 

  run(ncpus=ncpus,ncore=ncore,kpar=kpar,npar=npar)

def run_relax(ncpus=None):
  '''
  Do a complex relaxation run with mutliple relax iterations and a final static 
  calculation.

  There is an option to change some platform-dependent things like NCORE,KPAR, etc.
  We will operate with NCORE=10 (which seems to be a reasonable value on Iridis5)
  '''

  ncore,npar,kpar = parallelisation_pattern(ncpus)
  relaxation = Relax(settings={
    "ncore": ncore,
    "npar": npar,
    "kpar": kpar
  })

  relaxation.run()

def run_converge():
  '''
  Converges a property
  '''
  raise Exception('Not yet implemented.')

def run_check():
  '''
  Checks if a VASP run run has finished 
  '''

  ## Look for a 'final' directory from relaxation runs and check
  if os.path.exists('run.final') and job_complete('run.final'):
      exit(0)
  
  ## Seems to be a simple job. Check current directory
  if job_complete():
    exit(0)

  # Does not seem to be a completed vasp run
  exit(1)
  



##################################################################################
# MAIN
##################################################################################

if __name__ == '__main__':
  # Select the operation mode
  mode = "simple"
  if len(sys.argv) > 1:
    mode = sys.argv[1]

  modes = {
    "simple": run_simple,
    "relax": run_relax,
    "converge": run_converge,
    "check": run_check
  }

  run_func = modes.get(mode, lambda: "Invalid mode")
  run_func()


