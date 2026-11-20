import os
import sys
import subprocess
import glob

# Compatible with Python 3.6 through 3.12
if __name__ == '__main__':
    pattern = sys.argv[1] if len(sys.argv) > 1 else 'playbooks/linux/*.yml'
    files = sorted(glob.glob(pattern))
    print("Found {} playbooks matching {}".format(len(files), pattern))
    
    failed = 0
    for f in files:
        cmd = ['ansible-playbook', '-i', 'inventories/lab/hosts.yml', f, '--syntax-check']
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        if res.returncode == 0:
            print("  [PASS] {}".format(f))
        else:
            print("  [FAIL] {}".format(f))
            print(res.stderr)
            print(res.stdout)
            failed += 1
            
    print("\nTotal: {}, Passed: {}, Failed: {}".format(len(files), len(files) - failed, failed))
    sys.exit(failed)
