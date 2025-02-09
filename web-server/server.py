from flask import Flask, request, redirect, send_file, \
     jsonify, render_template, make_response
from flask_sqlalchemy import SQLAlchemy
#from io import BytesIO
#from zipfile import ZipFile
from dotenv import load_dotenv
import random, string, hashlib, json, tempfile, zipfile
import sqlite3
import os

app = Flask(__name__, static_url_path="/static", template_folder="templates")
# Redirect HTTP requests to HTTPS
#@app.before_request
#def enforce_https():
#    if request.url.startswith("http://"):
#        return redirect(request.url.replace("http://", "https://", 301))


# Load PostgreSQL environment variables from .env
load_dotenv()
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME')

# Global variables
FILE_TO_SERVE = "tuxid.py"
FINGERPRINTING_SCRIPT="../tuxid.sh"
INSTALL_ID_LENGTH = 8
SAMPLES_DIR="samples/"

# Setup PostgreSQL
app.config['SQLALCHEMY_DATABASE_URI'] = (
    f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# Initialize the DB connection
db = SQLAlchemy(app)

# Initialize DB tables
def init_db():
    with app.app_context():
        db.create_all()
    app.run(debug=True)

# Database model
class Tuxid(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    # Installation identifier
    install_id = db.Column(db.String(64), nullable=False)
    # script output (JSON)
    data = db.Column(db.Text, nullable=False)

def generate_install_id():
    alphabet = string.ascii_letters + string.digits
    random_string = ''.join(random.choice(alphabet) for i in range(INSTALL_ID_LENGTH))
    install_id = hashlib.sha256(random_string.encode()).hexdigest()
    return install_id

def save_json_files(install_id, data):
    # Save JSON files in a separate directory (one entry per install_id)
    # create auxiliary directories
    output_dir = os.path.join(SAMPLES_DIR, install_id)
    if not os.path.exists(SAMPLES_DIR):
        os.makedirs(SAMPLES_DIR)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # assign boot number as a filename (e.g. boot3)
    files = [f for f in os.listdir(output_dir) if os.path.isfile(os.path.join(output_dir, f))]
    count = len(files)
    next_number = count + 1
    filename = f'boot{next_number}.json'

    # write contents to file
    with open(os.path.join(output_dir, filename), 'w') as f:
        json.dump(data, f)


@app.route("/")
def index():
    return render_template("index.html")

@app.route("/download", methods=["GET"])
def download_file():
    return send_file(FINGERPRINTING_SCRIPT, as_attachment=True)

@app.route("/agree", methods=["GET"])
def agree():
    install_id = generate_install_id()
    zip_file_name = "tuxid-script.zip"

    return render_template("download.html", install_id=install_id, zip_file=zip_file_name)

@app.route("/send", methods=["GET"])
def send():
    # Create temporary directory to store the files
    temp_dir = tempfile.mkdtemp()

    # Generate random id
    install_id = generate_install_id()
    # Create JSON file
    install_id_data = {"install_id": install_id}
    with open(os.path.join(temp_dir, 'install_id.json'), 'w') as f:
        json.dump(install_id_data, f, indent=2)
        f.write('\n')

    # Create zip file
    zip_file_path = os.path.join(temp_dir, 'tuxid-script.zip')
    with zipfile.ZipFile(zip_file_path, 'w') as zip_file:
        # add JSON file
        zip_file.write(os.path.join(temp_dir, 'install_id.json'), 'install_id.json')
        # add tuxid.sh script
        filename = os.path.basename(FILE_TO_SERVE)
        zip_file.write(FILE_TO_SERVE, filename)

    return send_file(zip_file_path,
            mimetype = 'zip',
            download_name= 'tuxid-script.zip',
            as_attachment = True)

@app.route("/disagree", methods=["GET"])
def disagree():
    return render_template("disagree.html")

@app.route("/upload", methods=["POST"])
def upload_result():
    data = request.json
    install_id = data.get("install_id")
    if not data or not install_id:
        return jsonify({"error": "Invalid data received"}), 400

    tuxid = Tuxid(install_id=install_id, data=json.dumps(data))
    db.session.add(tuxid)
    db.session.commit()

    # Optionally save json files directly
    #save_json_files(install_id, data)
    return jsonify({"message": "Data stored successfully"})

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
    #app.run()
    #app.run(ssl_context=("/etc/ssl/certs/tuxid_app.crt", "/etc/ssl/private/tuxid_app.key"),
    #app.run(ssl_context=("tuxid_app.crt", "tuxid_app.key"), host="0.0.0.0", port=5000)

