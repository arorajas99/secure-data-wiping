import time
import sys
import random

def animate_progress_bar(duration, description):
    """
    A simple console progress bar animation.
    
    Args:
        duration (int): The number of seconds the progress bar should run.
        description (str): A description of the process.
    """
    print(f"\n{description}...", end="", flush=True)
    total_steps = 50
    for i in range(total_steps):
        time.sleep(duration / total_steps)
        sys.stdout.write("█")
        sys.stdout.flush()
    sys.stdout.write(" Done!\n")

def secure_wipe_device(device_id):
    """
    Simulates the secure data wiping process for a given device ID.
    
    Args:
        device_id (str): A unique identifier for the device being wiped.
    """
    print("--- Secure Data Wiping Protocol ---")
    print(f"**Initiating secure wipe for device ID: {device_id}**\n")

    # Step 1: Device Identification
    print("[1/4] Verifying device and checking storage integrity...")
    time.sleep(2)
    print("      ✅ Device verified. Storage healthy.")

    # Step 2: Data Shredding
    print("\n[2/4] **Shredding data using DoD 5220.22-M standard...**")
    time.sleep(1)
    
    # Simulate multiple passes of data overwrite
    for i in range(1, 4):
        animate_progress_bar(3, f"Pass {i} of 3: Overwriting data with random patterns")

    # Step 3: Verification
    print("\n[3/4] Verifying data destruction...")
    animate_progress_bar(4, "Scanning for residual data")
    
    # Simulate a check for residual data
    if random.choice([True, False]): # Randomly simulate a rare verification failure
        print("      ⚠️ Verification failed. Residual data found. Retrying wipe...")
        time.sleep(2)
        secure_wipe_device(device_id) # Recursive call to retry
        return
    else:
        print("      ✅ Verification successful. No data remaining.")

    # Step 4: Final Certification
    print("\n[4/4] Generating data destruction certificate...")
    time.sleep(3)
    
    certificate_id = f"CERT-{int(time.time())}-{random.randint(100,999)}"
    
    print("\n--- Data Destruction Complete ---")
    print(f"**Device {device_id} successfully wiped.**")
    print(f"**Certificate of Destruction ID:** {certificate_id}")
    print("This device is now safe for recycling.")
    print("-----------------------------------")

if __name__ == "__main__":
    device_to_wipe = "LAPTOP-ABCD-1234"
    secure_wipe_device(device_to_wipe)