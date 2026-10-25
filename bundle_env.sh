# Put the PREFIRE_ATM sibling packages on PYTHONPATH (the PYTHONPATH method in PREFIRE_ATM/README.md)
# and keep Python from rewriting tracked bytecode in the submodules.
# Usage, from anywhere: source /path/to/prefire-atm-bundle/bundle_env.sh
_bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# PREFIRE_tools is used only by the PREFIRE_PRD_GEN finalization step.
export PYTHONPATH="${_bundle_root}/PREFIRE_PRD_GEN/source:${_bundle_root}/PREFIRE_sim_tools:${_bundle_root}/PREFIRE_pyPCRTM:${_bundle_root}/PREFIRE_tools/source/python${PYTHONPATH:+:${PYTHONPATH}}"
# PREFIRE_tools tracks two .pyc files; without this, importing it rewrites them and the product provenance says "(modified)"
export PYTHONDONTWRITEBYTECODE=1
unset _bundle_root
