# Changes in this bundle

This repository bundles the PREFIRE 2B-ATM retrieval (temperature and water vapor profiles, surface temperature and column water vapor) from six PREFIRE mission team (UW-PREFIRE) repositories, held as git submodules at their `R01` release: PREFIRE_ATM, PREFIRE_pyPCRTM, PREFIRE_PCRTM_V3.4, PREFIRE_sim_tools, PREFIRE_PRD_GEN and PREFIRE_tools. The bundle itself adds only `README.md`, `bundle_env.sh` (puts the sibling packages on `PYTHONPATH`), `environment.yml` and this file. Each submodule keeps its own license (MIT, PREFIRE Mission Team).

Up to tag `R01.2` every submodule was the unchanged upstream `R01` commit, and the bundle could not run from public sources (see below). This file lists the changes since `R01.2`.

## 2026-10-27: PREFIRE_sim_tools comes from a fixed copy of R01

**What was wrong.** `PREFIRE_ATM/source/ATM_retrieval.py` imports `PREFIRE_sim_tools.utils`. In upstream R01 (`9cf1becfbd4ffab850766bcf828c3ec0364d2ef0`), `PREFIRE_sim_tools/utils/__init__.py` line 4 imports `hsremis`, and `hsremis.py` line 20 opens `UWiremis_labeigvects.nc` as soon as it is imported. That file is not public: PREFIRE_sim_tools' `.gitignore` excludes `*.nc`, it is in none of the repository's public commits, and it is not in the R01 code archive on Zenodo (record 17088937). So `PREFIRE_ATM/dist/produce_L2.py` stopped with `FileNotFoundError` before reading any input. 2B-ATM never calls anything in `hsremis`.

**What changed.** The `PREFIRE_sim_tools` submodule now points to https://github.com/gchang/prefire-sim-tools at `bcbdd0b5e4d87090f505c4627b7b06d9f6f766b3` (tag `R01.post1`): upstream R01's file tree with the single line `from . import hsremis` removed from `utils/__init__.py`, plus that copy's own `MAAP_CHANGES.md`. The README's section on the missing file is replaced by a short note on the copy. The other five submodules are unchanged.

**Results.** Unchanged. The product's provenance attribute now names `PREFIRE_sim_tools bcbdd0b5` where it named `9cf1becf`; nothing else in the product depends on the change.

**Who asked for it.** Our own change, made at the lead's request on 2026-10-27. We found the failure in our own check of this bundle on 2026-10-25. The registration wizard's draft for this bundle was parked over the non-public `UWiremis_labeigvects.nc` (the lead, 2026-10-27), and the wizard proposed no code fix. Its own record of that review says its analysis of the bundle had no finding that the code opens a file the repository does not have, and lists that as a miss on its side (wizard `docs/dry-runs/guided-fixes-2026-10-27.md`, gap G12).

## 2026-10-27: how to keep PCRTM's table path short in a deep job folder

**What was wrong.** PCRTM reads `PCRTM_INPUT_DIR` into a 120-character Fortran string and silently cuts off anything longer, so a run whose tables sit in a deep folder stops with "Cannot open file" on a mangled path. The README already gave the limit, but not what to do when the job itself runs in a deep folder, as jobs on NASA MAAP do.

**What changed.** README only: in a deep job folder, extract the tables into, or symlink them from, a short folder such as `/tmp/pcrtm`, and set `PCRTM_INPUT_DIR=/tmp/pcrtm/INPUTDIR/`. The PCRTM Fortran (the 120-character buffers in PREFIRE_PCRTM_V3.4 and PREFIRE_pyPCRTM) is unchanged.

**Results.** Unchanged.

**Who asked for it.** Our own note. We found the limit in our first test of PREFIRE_ATM (2026-10-23 to 2026-10-24). The registration wizard never reported it: its documents mention the limit only in its list of the scientist's own fixes, where a message that long paths are cut off is listed as something the wizard owes the scientist (wizard `docs/dry-runs/guided-fixes-2026-10-27.md`).

## Check

2026-10-27, x86-64 Linux, a fresh `git clone --recurse-submodules` with both changes, set up exactly as the README says (conda environment from `environment.yml`, PCRTM build, ancillary data, both `determine_prdgit.py` steps), with no `UWiremis_labeigvects.nc` anywhere. The clone sat in a 215-character folder; the PCRTM tables sat in a deep folder, symlinked from `/tmp/pcrtm/INPUTDIR`.

- SAT2 orbit 02040 (inputs from NASA LaRC ASDC, R01), step 1 as four frame ranges at once, then step 2: 13.7 minutes in all (784 to 821 seconds per range, 49 CPU-minutes together), at most 0.63 GB per process; step 2 took 6 seconds and 0.64 GB.
- Compared with the official ASDC R01 2B-ATM granule for that orbit: the same file structure and attributes apart from the creation time and provenance; the same 5,444 footprints retrieved; identical quality flags, QC bit flags, iteration counts, priors, pressure and altitude profiles; `T_profile` within 3.05e-5 K, `surface_T` within 6.1e-5 K, `wv_profile` within 3.3e-5 g/kg and `cwv` within 6.1e-5 mm, the size of float32 rounding. This is the same agreement as the first test, which disabled the import by hand.
- PREFIRE_pyPCRTM's forward test with `PCRTM_INPUT_DIR` set to the deep folder itself (219 characters) stopped with "Cannot open file" on a path cut off at 120 characters, which is why the README's short folder matters.
