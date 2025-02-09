import requests
import subprocess
import os
import json, string, random, hashlib
from pathlib import Path

INSTALL_ID_LENGTH=8
SERVER_URL = "http://localhost:5000"
SERVER_SCRIPT_PATH = "tuxid.sh"
#RESULT_PATH = "/etc/tuxid-script/output.json"
RESULT_PATH = "output.json"
INSTALL_ID_PATH = "install_id.json"

def get_install_id(file_path):
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
            return data.get("install_id")
    except Exception as e:
        return None

def download_script(server_url, save_path):
    response = requests.get(f"{server_url}/download")
    if response.status_code == 200:
        with open(save_path, "wb") as f:
            f.write(response.content)
        print("Script downloaded successfully.")
    else:
        print("Failed to download script.")
        exit(1)

def execute_script(script_path):
    try:
        #subprocess.run(["sh", script_path], check=True)
        subprocess.run(f"sh {script_path} > {RESULT_PATH}", shell=True, check=True)
        print("Script executed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error executing script: {e}")
        exit(1)

def upload_results(server_url, result_path, install_id):
    try:
        with open(result_path, "r") as f:
            result_data = json.load(f)
        payload = {"install_id": install_id, "data": result_data}
        response = requests.post(f"{server_url}/upload", json=payload)
        if response.status_code == 200:
            print("Results uploaded successfully.")
            os.remove(result_path)
            print("Local result file deleted.")
            print("-----------------------------------------------------------")
            print("Next Steps:\t")
            print("\t* Reboot you machine and execute the script again")
            print("\t (if you have not done it already)")
            print("-----------------------------------------------------------")
            print("Note: Thank you for participating in the research study!!.")
        else:
            print("Failed to upload results.")
    except Exception as e:
        print(f"Error uploading results: {e}")
        exit(1)

def create_install_id(file_path):
    # Calculate install id
    alphabet = string.ascii_letters + string.digits
    random_string = ''.join(random.choice(alphabet) for i in range(INSTALL_ID_LENGTH))
    install_id = hashlib.sha256(random_string.encode()).hexdigest()

    # create folder if it does not exists
    #install_file = Path(file_path)
    #install_file.parent.mkdir(exist_ok=True, parents=True)

    # Create JSON file
    #install_id_data = {"install_id": install_id}
    #with open(os.path.join(folder_path, file_name), 'w') as f:
    #with open(file_path, 'w') as f:
    #    json.dump(install_id_data, f, indent=2)
    #    f.write('\n')


if __name__ == "__main__":
    download_script(SERVER_URL, SERVER_SCRIPT_PATH)
    install_id = get_install_id(INSTALL_ID_PATH)
    if not install_id:
        create_install_id(INSTALL_ID_PATH)
        exit(1)

    execute_script(SERVER_SCRIPT_PATH)
    upload_results(SERVER_URL, RESULT_PATH, install_id)

