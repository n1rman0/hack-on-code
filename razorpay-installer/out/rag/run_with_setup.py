import subprocess
import sys
import os
import importlib.util

SETUP_MARKER = os.path.join(os.path.dirname(__file__), ".setup_lock")

def are_requirements_installed():
    req_path = os.path.join(os.path.dirname(__file__), "requirements.txt")
    if not os.path.exists(req_path):
        print("❌ requirements.txt not found.")
        return False

    with open(req_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # Extract base module name (e.g., 'langchain' from 'langchain==0.1.0')
            module = line.split("==")[0].replace("-", "_")
            if importlib.util.find_spec(module) is None:
                print(f"📦 Missing module: {module}")
                return False

    return True

def install_requirements():
    req_path = os.path.join(os.path.dirname(__file__), "requirements.txt")
    venv_path = os.path.join(os.path.dirname(__file__), ".venv")
    pip_path = os.path.join(venv_path, "bin", "pip3") if os.name != "nt" else os.path.join(venv_path, "Scripts", "pip.exe")
    subprocess.check_call([pip_path, "install", "-r", req_path])

def get_python_and_venv():
    venv_path = os.path.join(os.path.dirname(__file__), ".venv")
    python_bin = os.path.join(venv_path, "bin", "python3") if os.name != "nt" else os.path.join(venv_path, "Scripts", "python.exe")

    if not os.path.exists(python_bin):
        subprocess.check_call([sys.executable, "-m", "venv", venv_path])

    return python_bin

def run_rag(python_bin, file_path):
    rag_path = os.path.join(os.path.dirname(__file__), "rag-server.py")
    subprocess.check_call([python_bin, rag_path, "--file", file_path])

def setup_and_run(swift_file):
    python_bin = get_python_and_venv()
    if not os.path.exists(SETUP_MARKER):
        print("📦 Installing dependencies for the first time...")
        install_requirements()
        with open(SETUP_MARKER, "w") as f:
            f.write("installed=true")
    else:
        print("✅ Dependencies already installed (using cache).")
    run_rag(python_bin, swift_file)

# ✅ MAIN block — clean and single responsibility
if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] != "--file":
        print("Usage: python run_with_setup.py --file /path/to.swift")
        sys.exit(1)

    force_reinstall = "--force-reinstall" in sys.argv
    if force_reinstall and os.path.exists(SETUP_MARKER):
        os.remove(SETUP_MARKER)

    swift_file = sys.argv[2]
    setup_and_run(swift_file)
