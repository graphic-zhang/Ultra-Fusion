#!/usr/bin/env bash
#
# Initialize the machine-guide skill in $CODEX_HOME/skills.
#
set -euo pipefail

SKILLS_ROOT="/mnt/c/Users/12050/.codex/skills"
INIT="/mnt/c/Users/12050/.codex/skills/.system/skill-creator/scripts/init_skill.py"

python3 "${INIT}" machine-guide \
    --path "${SKILLS_ROOT}" \
    --resources references,scripts \
    --interface 'display_name=机器环境指南' \
    --interface 'short_description=本机 Windows/WSL 系统环境、网络代理偏好与开发资源速查，供新项目开工参考' \
    --interface 'default_prompt=Use $machine-guide to review this machine environment before starting a new project.'

echo "== generated =="
find "${SKILLS_ROOT}/machine-guide" -maxdepth 2 -type f | sort
