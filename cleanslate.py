#!/usr/bin/env python3
import subprocess
import json
import datetime
import hashlib
import os
import sys

def list_drives():
    """List drives using lsblk command (Linux only)."""
    result = subprocess.run(["lsblk", "-o", "NAME,SIZE,MOUNTPOINT,TYPE"], 
                            capture_output=True, text=True)
    print("Available drives:\n")
    print(result.stdout)

def wipe_target(target, passes=3):
    """
    Wipe a target device or file securely using shred.
    - target: file, folder, or device (/dev/sdb)
    - passes: overwrite count
    """
    print(f"[+] Wiping {target} with {passes} passes...")
    try:
        subprocess.run(["shred", "-v", "-n", str(passes), "-z", target], check=True)
        print("[+] Wipe complete.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[!] Error wiping {target}: {e}")
        return False

def generate_report(target, passes=3):
    """Generate a JSON certificate for the wipe."""
    report = {
        "tool": "CleanSlate CLI",
        "target": target,
        "method": f"shred overwrite ({passes} passes + final zero pass)",
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }
    report["report_hash"] = hashlib.sha256(json.dumps(report).encode()).hexdigest()

    fname = f"wipe_report_{os.path.basename(target).replace('/', '_')}.json"
    with open(fname, "w") as f:
        json.dump(report, f, indent=4)

    print(f"[+] Report saved as {fname}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 cleanslate.py <target> [passes]")
        print("Examples:")
        print("  python3 cleanslate.py /dev/sdb 3   # wipe USB drive")
        print("  python3 cleanslate.py secret.txt   # wipe single file")
        print("\nListing available drives...\n")
        list_drives()
        sys.exit(1)

    target = sys.argv[1]
    passes = int(sys.argv[2]) if len(sys.argv) > 2 else 3

    if not os.path.exists(target) and not target.startswith("/dev/"):
        print(f"[!] Target not found: {target}")
        sys.exit(1)

    if wipe_target(target, passes):
        generate_report(target, passes)

if __name__ == "__main__":
    main()
