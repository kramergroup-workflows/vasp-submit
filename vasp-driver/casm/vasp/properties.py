from casm.vasp.io import Vasprun, Oszicar, Outcar, Poscar,species_settings

import os
from casm.misc import noindent 

def properties(vaspdir, super_poscarfile = None, speciesfile = None):
  """Report results to properties.calc.json file in configuration directory, after checking for electronic convergence."""

  output = dict()
  vrun = Vasprun( os.path.join(vaspdir, "vasprun.xml") )

    # load the final OSZICAR, OUTCAR, and INCAR
  zcar = Oszicar( os.path.join(vaspdir, "OSZICAR") )
  ocar = Outcar( os.path.join(vaspdir, "OUTCAR") )

  # the calculation is run on the 'sorted' POSCAR, need to report results 'unsorted'

  if (super_poscarfile is not None) and (speciesfile is not None):
      species_settings = species_settings(speciesfile)
      super = Poscar(super_poscarfile, species_settings)
      unsort_dict = super.unsort_dict()
  else:
      # fake unsort_dict (unsort_dict[i] == i)
      unsort_dict = dict(zip(range(0,len(vrun.basis)),range(0,len(vrun.basis))))
      super = Poscar(os.path.join(vaspdir,"POSCAR"))

  # unsort_dict:
  #   Returns 'unsort_dict', for which: unsorted_dict[orig_index] == sorted_index;
  #   unsorted_dict[sorted_index] == orig_index
  #   For example:
  #     'unsort_dict[0]' returns the index into the unsorted POSCAR of the first atom in the sorted POSCAR


  output["atom_type"] = super.type_atoms
  output["atoms_per_type"] = super.num_atoms
  output["coord_mode"] = vrun.coord_mode

  # as lists
  output["relaxed_forces"] = [ None for i in range(len(vrun.forces))]
  for i, v in enumerate(vrun.forces):
      output["relaxed_forces"][unsort_dict[i] ] = noindent.NoIndent(vrun.forces[i])

  output["relaxed_lattice"] = [noindent.NoIndent(v) for v in vrun.lattice]

  output["relaxed_basis"] = [ None for i in range(len(vrun.basis))]
  for i, v in enumerate(vrun.basis):
      output["relaxed_basis"][unsort_dict[i] ] = noindent.NoIndent(vrun.basis[i])

  output["relaxed_energy"] = vrun.total_energy

  # output["relaxed_mag_basis"] = [ None for i in range(len(vrun.basis))]
  # output["relaxed_magmom"] = None
  if ocar.ispin == 2:
      output["relaxed_magmom"] = zcar.mag[-1]
      if ocar.lorbit in [1, 2, 11, 12]:
          output["relaxed_mag_basis"] = [ None for i in range(len(vrun.basis))]
          for i, v in enumerate(vrun.basis):
              output["relaxed_mag_basis"][unsort_dict[i]] = noindent.NoIndent(ocar.mag[i])
  # if output["relaxed_magmom"] is None:
  #     output.pop("relaxed_magmom", None)
  # if output["relaxed_mag_basis"][0] is None:
  #     output.pop("relaxed_mag_basis", None)

  return output