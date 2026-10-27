# PREFIRE_ATM bundle

The PREFIRE 2B-ATM product retrieves temperature and water vapor profiles, surface temperature and column water vapor for clear polar footprints of the PREFIRE TIRS spectrometers, by optimal estimation with the PCRTM radiative transfer model. The code is split across six repositories from the PREFIRE mission team (UW-PREFIRE). This repository holds them side by side as git submodules, each pinned to its `R01` release, so the whole algorithm can be cloned in one step:

```sh
git clone --recurse-submodules https://github.com/gchang/prefire-atm-bundle.git
```

## A required file is not public

**`PREFIRE_sim_tools/PREFIRE_sim_tools/utils/UWiremis_labeigvects.nc` is required and is not publicly available.** `PREFIRE_ATM` imports `PREFIRE_sim_tools.utils`, whose `__init__.py` (line 4) imports `hsremis`, and `hsremis.py` (line 20) opens this file as soon as it is imported. The file is left out of the PREFIRE_sim_tools repository by its own `.gitignore` (`*.nc`, line 79), it is in none of that repository's public commits, it is not in the R01 public code archive on Zenodo (record 17088937), and we found no other source. Without it, `dist/produce_L2.py` stops at the import with `FileNotFoundError` before reading any input. 2B-ATM never calls the code in `hsremis.py`, so the file does not affect the results; it is needed only because the import happens at load time.

The check run behind this bundle never had the file either: it got past the import only by disabling that one import line in a local copy of PREFIRE_sim_tools, which this bundle does not do. To run the bundle as it stands, get `UWiremis_labeigvects.nc` from the PREFIRE mission team (UW-PREFIRE) and put it in `PREFIRE_sim_tools/PREFIRE_sim_tools/utils/`, where the `*.nc` rule in `.gitignore` keeps the submodule clean. This bundle does not include or redistribute the file.

| Submodule | Upstream | R01 commit | Role |
|---|---|---|---|
| `PREFIRE_ATM` | https://github.com/UW-PREFIRE/PREFIRE_ATM | 75981c4f9c8c3561bedd2aeead6601c007999474 | the 2B-ATM product code (`dist/produce_L2.py`) |
| `PREFIRE_pyPCRTM` | https://github.com/UW-PREFIRE/PREFIRE_pyPCRTM | f19294e232af20dbd496c10f868e843b2f83b2a6 | Python wrapper and Fortran adapter for PCRTM |
| `PREFIRE_PCRTM_V3.4` | https://github.com/UW-PREFIRE/PREFIRE_PCRTM_V3.4 | 046b309756ed7a2831346f5a1aa180e2206486b9 | the PCRTM v3.4 radiative transfer model (Fortran) |
| `PREFIRE_sim_tools` | https://github.com/UW-PREFIRE/PREFIRE_sim_tools | 9cf1becfbd4ffab850766bcf828c3ec0364d2ef0 | spectral response functions and emissivity mapping (needs the file above) |
| `PREFIRE_PRD_GEN` | https://github.com/UW-PREFIRE/PREFIRE_PRD_GEN | e3933a389894d1af081b3d0bbac4aa0eb27019bc | NetCDF read and write helpers, and the finalization step |
| `PREFIRE_tools` | https://github.com/UW-PREFIRE/PREFIRE_tools | 3b590a6eba09ce596e193ad1e04f636a8b7c3d58 | utilities used by the finalization step |

Nothing inside the submodules is changed. All six are MIT-licensed by the PREFIRE Mission Team; see each submodule's LICENSE. The official ASDC R01 2B-ATM products report `PREFIRE_ATM 1.0.1`, the version in `PREFIRE_ATM/VERSION.txt` at this commit.

## Finding the sibling packages

`PREFIRE_ATM`'s README offers two ways to find its siblings: symbolic links in `PREFIRE_ATM/source/`, or adding each sibling's Python source directory to `PYTHONPATH`. This bundle uses `PYTHONPATH` for the Python packages:

```sh
source bundle_env.sh    # from the bundle root; sets PYTHONPATH to the sibling source directories
```

The one link the code still needs is to the built PCRTM, which `PREFIRE_ATM/dist/determine_prdgit.py` reads from `PREFIRE_ATM/source/PREFIRE_PCRTM_V3.4` (see the build below). The link is covered by `PREFIRE_ATM`'s `.gitignore`, so the submodule stays clean.

## Software and data

- Python 3.10 with numpy 1.26, scipy 1.11, netcdf4 1.6 and h5py 3.10 from conda-forge (the versions in `PREFIRE_ATM/conda_env.list`), git (to record the code versions in the product), gfortran, make and binutils (to build PCRTM; its makefile calls a bare `ar`, which conda-forge's gfortran does not provide) and unzip. `environment.yml` at the bundle root lists exactly this set; from the bundle root:

  ```sh
  conda env create -f environment.yml    # creates the conda env prefire_atm
  conda activate prefire_atm
  ```

  `pyhdf`, also in `conda_env.list`, is not imported by the run and is left out.
- The Makefiles of `PREFIRE_PCRTM_V3.4` and `PREFIRE_pyPCRTM` use x86-64-v3 instruction flags (AVX2, FMA). They build as they are on a current x86-64 CPU. On other CPUs (for example arm64), those flags must be removed, as the comments in both Makefiles say.
- `UWiremis_labeigvects.nc`: see above. Not public.
- PCRTM coefficient tables: `PREFIRE_PCRTM_V3.4-large_ancillary_data-1.zip` (3.5 GB, MIT) from Zenodo record 16694725 (https://zenodo.org/records/16694725). 2B-ATM uses only four of its members (205 MB), the tables for PCRTM sensor 2. Extract them into a folder whose path, with a trailing `/`, is **shorter than 120 characters**: PCRTM keeps the path in a 120-character Fortran string and silently cuts off anything longer, and the run then stops with "Cannot open file" on a mangled path.
- Spectral response functions: `PREFIRE_SRFs-v13_2024-09-15.zip` (11.6 MB, MIT) from Zenodo record 16638853 (https://zenodo.org/records/16638853), unzipped inside `PREFIRE_ATM/dist/`, which puts the two SRF files in `PREFIRE_ATM/dist/ancillary/` (the code reads them from there).
- Inputs per orbit, from NASA LaRC ASDC (Earthdata login): the PREFIRE 1B-RAD granule, the matching AUX-MET granule, and the matching **final** 2B-MSK and 2B-SFC granules (the archived products), about 99 MB together. Collections `PREFIRE_SAT2_1B-RAD`, `PREFIRE_SAT2_AUX-MET`, `PREFIRE_SAT2_2B-MSK`, `PREFIRE_SAT2_2B-SFC` (and the same for SAT1), version R01.
- The final product needs nothing more. The optional browse image and Worldview images of the finalization step need matplotlib, cartopy, shapely, geopandas, pandas and geocube, plus network access for cartopy's Natural Earth coastlines; set `PRD_GEN_BASIC_ONLY=1` to skip the images and the CMR metadata file and run offline.

## Building PCRTM and its Python adapter (once)

From the bundle root. The build records these absolute paths, and `determine_prdgit.py` checks that the two records agree, so build in the place the bundle will run from (rebuild after moving it):

```sh
# determine_prdgit.py looks for a .git folder in each package, but git gives submodules a .git file, and the
# product would then record "unknown" code versions. Move each submodule's git folder into the submodule:
git submodule foreach -q 'd=$(git rev-parse --absolute-git-dir); git config --unset core.worktree; rm .git; mv "$d" .git'

unset MAKEFLAGS    # build serially: PCRTM's makefiles break under parallel make (see below)
B=$PWD
cd $B/PREFIRE_PCRTM_V3.4/GENERIC
make gfortran LIBRARY_DIR=$B/PREFIRE_PCRTM_V3.4/lib INCLUDE_DIR=$B/PREFIRE_PCRTM_V3.4/include
make install  LIBRARY_DIR=$B/PREFIRE_PCRTM_V3.4/lib INCLUDE_DIR=$B/PREFIRE_PCRTM_V3.4/include
cd $B/PREFIRE_pyPCRTM/pyPCRTM
PCRTM_HOME=$B/PREFIRE_PCRTM_V3.4 make gfortran
cd $B
ln -s ../../PREFIRE_PCRTM_V3.4 PREFIRE_ATM/source/PREFIRE_PCRTM_V3.4

# ancillary data (zip paths are where you downloaded them; /path/to/pcrtm must be short, see above)
(cd /path/to/pcrtm && unzip /path/to/PREFIRE_PCRTM_V3.4-large_ancillary_data-1.zip \
    INPUTDIR/ABS_COEF/clarreo_abscoef_0.5 INPUTDIR/CLD_LUT/ice_clarreo_0.5.dat \
    INPUTDIR/CLD_LUT/wat_clarreo_0.5.dat INPUTDIR/EOF_COEF/clarreo_0.5_pccoef)
(cd PREFIRE_ATM/dist && unzip /path/to/PREFIRE_SRFs-v13_2024-09-15.zip)
```

Pass `LIBRARY_DIR` and `INCLUDE_DIR` on the command line as shown: their defaults in `GENERIC/makefile` point into the home folder. Build serially: `GENERIC/SRC/make.dependencies` does not match the object names in `GENERIC/SRC/Makefile`, so with `make -j` (or `-j` in `MAKEFLAGS`) Fortran modules can be compiled before the modules they use. `GENERIC/makefile` does not pass such a failure on, so it shows up only later, when the pyPCRTM build stops with "Cannot open module file 'init_pcrtm.mod'". A good build leaves 23 `.mod` files and `build_provenance.txt` in `PREFIRE_PCRTM_V3.4/include`. The first `make gfortran` prints a series of "Error 127 (ignored)" lines before the real compile; they are harmless. The build gives `PREFIRE_PCRTM_V3.4/lib/libPCRTM.a` and `PREFIRE_pyPCRTM/pyPCRTM/PCRTM_wrapper_module.so`, all ignored by the submodules' `.gitignore` files.

Optional check of the build, PREFIRE_pyPCRTM's own tests (each prints "Success!"; they do not need the missing file):

```sh
source bundle_env.sh
cd PREFIRE_pyPCRTM/test
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_forward_run.py
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_jacobian_run.py
cd ../..
```

`test_forward_run.py` now and then fails with "non-finite values detected in krad_esurf" (or `kbt_esurf`): it also checks the Jacobian arrays, which it does not request, so they hold leftover memory (`PCRTM_fwrappers.py` allocates them with `np.empty`). That is a test problem, not a build problem; run it again.

## Running one orbit

The mission makes 2B-ATM in two steps: `PREFIRE_ATM` writes a raw file for the orbit, then `PREFIRE_PRD_GEN` finalizes it into the archived product (polar frames only, with the archive's metadata). From the bundle root, once `UWiremis_labeigvects.nc` is in place:

```sh
source bundle_env.sh
python PREFIRE_ATM/dist/determine_prdgit.py        # records the code versions; produce_L2.py needs it
python PREFIRE_PRD_GEN/dist/determine_prdgit.py    # the same for the finalization step
export MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OPENBLAS_NUM_THREADS=1

# Step 1: atmosphere retrieval (writes raw-PREFIRE_SAT2_2B-ATM_R01_P00_20241007071543_02040-atrack_00000_07878_of_07879f.nc)
mkdir -p /path/to/raw
export PACKAGE_TOP_DIR=$PWD/PREFIRE_ATM ANCILLARY_DATA_DIR=$PWD/PREFIRE_ATM/dist/ancillary \
       PCRTM_DIR=$PWD/PREFIRE_PCRTM_V3.4 PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ \
       OUTPUT_DIR=/path/to/raw PRODUCT_FULLVER=R01_P00 \
       ATRACK_IDX_RANGE_0BI=ATRACK_IDXRANGE_0BASED_INCLUSIVE:0:END \
       L1B_RAD_FILE=/path/to/PREFIRE_SAT2_1B-RAD_R01_P00_20241007071543_02040.nc \
       AUX_MET_FILE=/path/to/PREFIRE_SAT2_AUX-MET_R01_P00_20241007071543_02040.nc \
       L2B_MSK_FILE=/path/to/PREFIRE_SAT2_2B-MSK_R01_P00_20241007071543_02040.nc \
       L2B_SFC_FILE=/path/to/PREFIRE_SAT2_2B-SFC_R01_P00_20241007071543_02040.nc
python PREFIRE_ATM/dist/produce_L2.py

# Step 2: finalization into the archived product (the output folder must exist)
mkdir -p /path/to/final
export PACKAGE_TOP_DIR=$PWD/PREFIRE_PRD_GEN ANCILLARY_DATA_DIR=$PWD/PREFIRE_PRD_GEN/dist/ancillary \
       OUTPUT_PRODUCT_DIR=/path/to/final OUTPUT_OPTIONS="" PRD_GEN_BASIC_ONLY=1 \
       INPUT_FPATH_OR_FPREFIX=/path/to/raw/raw-PREFIRE_SAT2_2B-ATM_R01_P00_20241007071543_02040
python PREFIRE_PRD_GEN/dist/produce_PRD.py
```

`PCRTM_INPUT_DIR` must end with `/`. The run is single-threaded by design and takes about 50 CPU-minutes per orbit. To finish sooner, run several frame ranges at once, each with its own `ATRACK_IDX_RANGE_0BI` (for example `...:0:5722`, `...:5723:5899`, `...:5900:6082` and `...:6083:END` for this orbit, balanced by the number of retrievals); step 2 then merges every raw file that starts with the `INPUT_FPATH_OR_FPREFIX` prefix. Each process needs about 1.0 to 1.3 GB of memory.

Checked on 2026-10-25 from a fresh `git clone --recurse-submodules` on x86-64 Linux, without `UWiremis_labeigvects.nc`: the build, PREFIRE_pyPCRTM's tests and both `determine_prdgit.py` steps work, and `produce_L2.py` then stops at the import of `hsremis` with `FileNotFoundError` for the missing file, so no product could be made or compared. An earlier test of the same R01 code, with that one import disabled, reproduced the official ASDC R01 2B-ATM granule for SAT2 orbit 02040: the same 5,444 footprints retrieved, identical quality flags, and temperatures within 3.05e-5 K.

The author's own test, `PREFIRE_ATM/test/run.sh`, runs step 1 on frames 6000 to 6020 of the SAT2 orbit above. It expects PCRTM and its tables under `PREFIRE_ATM/dist/subpackages/`, reads its inputs from `PREFIRE_ATM/test/inputs/`, and calls `determine_prdgit.py` itself.
