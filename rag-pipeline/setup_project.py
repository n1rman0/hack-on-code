import os
import subprocess
import plistlib

def find_file(base_path, filename):
    for root, dirs, files in os.walk(base_path):
        if filename in files:
            return os.path.join(root, filename)
    return None

def find_xcodeproj(base_path):
    for root, dirs, files in os.walk(base_path):
        for d in dirs:
            if d.endswith('.xcodeproj'):
                return os.path.join(root, d)
    return None

def run_pod_install(podfile_path):
    project_dir = os.path.dirname(podfile_path)
    subprocess.run(['pod', 'install'], cwd=project_dir, check=True)

def update_info_plist(plist_path, key, value):
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)
    plist[key] = value
    with open(plist_path, 'wb') as f:
        plistlib.dump(plist, f)

# Usage
base = os.getcwd()
podfile = find_file(base, 'Podfile')
xcodeproj = find_xcodeproj(base)

if podfile and xcodeproj:
    run_pod_install(podfile)
    # Update plist
    plist_path = os.path.join(os.path.dirname(xcodeproj), 'Info.plist')
    if os.path.exists(plist_path):
        update_info_plist(plist_path, 'NSLocationWhenInUseUsageDescription', 'Needed for UPI Turbo')
else:
    print("Podfile or .xcodeproj not found.")
