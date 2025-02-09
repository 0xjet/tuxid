# Tuxid Web Application
A fingerprinting web application based on Flask and PostgreSQL.
## Usage
- Install required software: `pip install -r requirements.txt`
- Make sure the PostgreSQL Database is up and running
- Export PostgreSQL configuration variables, either directly or through a
.env file, such as the one provided as a example
    * `source .env`
- Define web server global variables as needed, by editing the server.py file.
Especially the path of the fingerprinting script to be used (FINGERPRINTING_SCRIPT)
- Run web server: `python3 server.py`

