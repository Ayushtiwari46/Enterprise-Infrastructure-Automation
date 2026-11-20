import os
import sys
import glob
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '..', '..'))

patterns = [
    'playbooks/*/*.yml',
    'playbooks/*/*/*.yml',
    'incident-collection/*/*.yml',
    'operations/*/*.yml',
    'operations/changes/*/*.yml'
]

files = []
for p in patterns:
    full_pattern = os.path.join(REPO_ROOT, p)
    files.extend(glob.glob(full_pattern))

files = sorted(list(set(files)))
print(f"Total Enterprise Playbooks Discovered: {len(files)}")

passed = []
failed = []

for idx, f in enumerate(files, 1):
    rel_path = os.path.relpath(f, REPO_ROOT)
    res = subprocess.run(
        ['ansible-playbook', '--syntax-check', rel_path],
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True
    )
    if res.returncode == 0:
        passed.append(rel_path)
        print(f"  [{idx:02d}/{len(files):02d}] PASS: {rel_path}")
    else:
        failed.append(rel_path)
        print(f"  [{idx:02d}/{len(files):02d}] FAIL: {rel_path}")
        if res.stderr:
            print("        " + res.stderr.strip().replace("\n", "\n        "))

print("\n" + "=" * 78)
print("ENTERPRISE INFRASTRUCTURE AUTOMATION SYNTAX AUDIT SUMMARY")
print("=" * 78)
print(f"Total Discovered Playbooks : {len(files)}")
print(f"Successfully Validated     : {len(passed)}")
print(f"Failed Validation          : {len(failed)}")
print(f"Audit Status               : {'PASSED (100%)' if len(failed) == 0 else 'FAILED'}")
print("=" * 78)

# Write summary to reports/validation/PROJECT_VALIDATION_REPORT.md
report_path = os.path.join(REPO_ROOT, 'reports', 'validation', 'PROJECT_VALIDATION_REPORT.md')
os.makedirs(os.path.dirname(report_path), exist_ok=True)
with open(report_path, 'w', encoding='utf-8') as rp:
    rp.write("# Enterprise Infrastructure Automation Repository Validation Report\n\n")
    rp.write(f"**Audit Status:** {'PASSED (100%)' if len(failed) == 0 else 'FAILED'}\n")
    rp.write(f"**Total Playbooks Validated:** {len(files)}\n")
    rp.write(f"**Passed:** {len(passed)}\n")
    rp.write(f"**Failed:** {len(failed)}\n\n")
    rp.write("## Validated Playbook Registry\n\n")
    rp.write("| Index | Category | Playbook Path | Syntax Status |\n")
    rp.write("| :--- | :--- | :--- | :--- |\n")
    for idx, p in enumerate(passed, 1):
        cat = p.split('/')[0] if '/' in p else 'root'
        rp.write(f"| {idx:02d} | `{cat}` | `{p}` | **PASSED** |\n")

sys.exit(len(failed))
