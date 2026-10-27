# PREFIRE_ATM bundle

The PREFIRE 2B-ATM product retrieves temperature and water vapor profiles, surface temperature and column water vapor for clear polar footprints of the PREFIRE TIRS spectrometers, by optimal estimation with the PCRTM radiative transfer model. The code is split across six repositories from the PREFIRE mission team (UW-PREFIRE). This repository holds them side by side as git submodules, each at its `R01` release (PREFIRE_sim_tools as a fixed copy of R01, see below), so the whole algorithm can be cloned in one step:

```sh
git clone --recurse-submodules https://github.com/gchang/prefire-atm-bundle.git
```

## PREFIRE_sim_tools is a fixed copy of R01

The `PREFIRE_sim_tools` submodule is https://github.com/gchang/prefire-sim-tools, a copy of UW-PREFIRE's R01 (`9cf1bec`) with one line removed: `PREFIRE_sim_tools/utils/__init__.py` no longer imports `hsremis` when the package loads. `hsremis.py` opens `UWiremis_labeigvects.nc` as soon as it is imported, and that file is not public (the repository's `.gitignore` excludes `*.nc`, and it is not in the R01 code archive on Zenodo, record 17088937). With the upstream R01, `PREFIRE_ATM/dist/produce_L2.py` therefore stopped at import with `FileNotFoundError` before reading any input, although 2B-ATM never calls `hsremis`. With the copy it runs, the file is not needed, and the results do not change. The copy's `MAAP_CHANGES.md` describes the change.

| Submodule | Repository | Commit | Role |
|---|---|---|---|
| `PREFIRE_ATM` | https://github.com/UW-PREFIRE/PREFIRE_ATM | 75981c4f9c8c3561bedd2aeead6601c007999474 (R01) | the 2B-ATM product code (`dist/produce_L2.py`) |
| `PREFIRE_pyPCRTM` | https://github.com/UW-PREFIRE/PREFIRE_pyPCRTM | f19294e232af20dbd496c10f868e843b2f83b2a6 (R01) | Python wrapper and Fortran adapter for PCRTM |
| `PREFIRE_PCRTM_V3.4` | https://github.com/UW-PREFIRE/PREFIRE_PCRTM_V3.4 | 046b309756ed7a2831346f5a1aa180e2206486b9 (R01) | the PCRTM v3.4 radiative transfer model (Fortran) |
| `PREFIRE_sim_tools` | https://github.com/gchang/prefire-sim-tools (copy of https://github.com/UW-PREFIRE/PREFIRE_sim_tools R01) | bcbdd0b5e4d87090f505c4627b7b06d9f6f766b3 (R01.post1) | spectral response functions and emissivity mapping |
| `PREFIRE_PRD_GEN` | https://github.com/UW-PREFIRE/PREFIRE_PRD_GEN | e3933a389894d1af081b3d0bbac4aa0eb27019bc (R01) | NetCDF read and write helpers, and the finalization step |
| `PREFIRE_tools` | https://github.com/UW-PREFIRE/PREFIRE_tools | 3b590a6eba09ce596e193ad1e04f636a8b7c3d58 (R01) | utilities used by the finalization step |

Apart from that one line in PREFIRE_sim_tools, nothing inside the submodules is changed. All six are MIT-licensed by the PREFIRE Mission Team; see each submodule's LICENSE. The official ASDC R01 2B-ATM products report `PREFIRE_ATM 1.0.1`, the version in `PREFIRE_ATM/VERSION.txt` at this commit.

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
- `UWiremis_labeigvects.nc` is not needed (see above).
- PCRTM coefficient tables: `PREFIRE_PCRTM_V3.4-large_ancillary_data-1.zip` (3.5 GB, MIT) from Zenodo record 16694725 (https://zenodo.org/records/16694725). 2B-ATM uses only four of its members (205 MB), the tables for PCRTM sensor 2. Extract them into a folder whose path, with a trailing `/`, is **shorter than 120 characters**: PCRTM keeps the path in a 120-character Fortran string and silently cuts off anything longer, and the run then stops with "Cannot open file" on a mangled path. In a deep job folder (on NASA MAAP, for example, job paths are long), extract the tables into, or symlink them from, a short folder such as `/tmp/pcrtm` (for example `mkdir -p /tmp/pcrtm && ln -s /deep/job/folder/INPUTDIR /tmp/pcrtm/INPUTDIR`) and set `PCRTM_INPUT_DIR=/tmp/pcrtm/INPUTDIR/`. Only this path is limited: the bundle itself can sit in a folder of any depth.
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

Optional check of the build, PREFIRE_pyPCRTM's own tests (each prints "Success!"):

```sh
source bundle_env.sh
cd PREFIRE_pyPCRTM/test
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_forward_run.py
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_jacobian_run.py
cd ../..
```

`test_forward_run.py` now and then fails with "non-finite values detected in krad_esurf" (or `kbt_esurf`): it also checks the Jacobian arrays, which it does not request, so they hold leftover memory (`PCRTM_fwrappers.py` allocates them with `np.empty`). That is a test problem, not a build problem; run it again.

## Running one orbit

The mission makes 2B-ATM in two steps: `PREFIRE_ATM` writes a raw file for the orbit, then `PREFIRE_PRD_GEN` finalizes it into the archived product (polar frames only, with the archive's metadata). From the bundle root:

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

`PCRTM_INPUT_DIR` must end with `/`. The run is single-threaded by design and takes about 50 CPU-minutes per orbit. To finish sooner, run several frame ranges at once, each with its own `ATRACK_IDX_RANGE_0BI` (for example `...:0:5722`, `...:5723:5899`, `...:5900:6082` and `...:6083:END` for this orbit, balanced by the number of retrievals); step 2 then merges every raw file that starts with the `INPUT_FPATH_OR_FPREFIX` prefix. Each process needs about 0.6 GB of memory on Linux (1.0 to 1.3 GB was measured on macOS).

Checked on 2026-10-27 from a fresh `git clone --recurse-submodules` on x86-64 Linux, without `UWiremis_labeigvects.nc`, following this README exactly. The clone sat in a 215-character folder, as in a deep job folder, with the PCRTM tables in a deep folder symlinked from `/tmp/pcrtm/INPUTDIR`. Step 1 ran SAT2 orbit 02040 as the four frame ranges above at once (13.7 minutes, 49 CPU-minutes in all, at most 0.63 GB per process), and step 2 took 6 seconds. The final file matches the official ASDC R01 2B-ATM granule: the same structure and attributes apart from the creation time and provenance, the same 5,444 footprints retrieved, identical quality flags, QC bit flags, iteration counts, priors, pressure and altitude profiles, `T_profile` within 3.05e-5 K, `surface_T` within 6.1e-5 K, `wv_profile` within 3.3e-5 g/kg (8.5e-6 relative) and `cwv` within 6.1e-5 mm, the size of float32 rounding. PREFIRE_pyPCRTM's tests passed with the short path (the forward test after a rerun, see above); its forward test with `PCRTM_INPUT_DIR` set to the deep tables folder itself (219 characters) stopped with "Cannot open file" on a cut-off path, as described above.

The author's own test, `PREFIRE_ATM/test/run.sh`, runs step 1 on frames 6000 to 6020 of the SAT2 orbit above. It expects PCRTM and its tables under `PREFIRE_ATM/dist/subpackages/`, reads its inputs from `PREFIRE_ATM/test/inputs/`, and calls `determine_prdgit.py` itself.
