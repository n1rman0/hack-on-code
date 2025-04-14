import os
import zipfile
from flask import Flask, send_file, jsonify

app = Flask(__name__)

DB_FOLDER = 'rag_db'
ZIP_FILENAME = 'rag_db.zip'
SCRIPT_FILENAME = 'setup_project.py'  # Ensure this script exists in the same dir

# 🔁 Zip rag_db folder
def zip_rag_db():
    if os.path.exists(ZIP_FILENAME):
        os.remove(ZIP_FILENAME)

    with zipfile.ZipFile(ZIP_FILENAME, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(DB_FOLDER):
            for file in files:
                full_path = os.path.join(root, file)
                arcname = os.path.relpath(full_path, DB_FOLDER)
                zipf.write(full_path, arcname)

# 🧪 JSON config (unchanged)
@app.route('/data', methods=['GET'])
def get_data():
    data = {
        "merchant_public_key": "rzp_test_1a2b3c4d5e6f7g",
        "merchant_secret": "a1b2c3d4e5f6g7h8i9j0",
        "merchant_flavours": ["Standard Checkout (iOS)", "Standard Checkout + Turbo (iOS)"], 
        "merchant_sample_order_id": "order_9A33XWu170gUtm",
        "rag_store": "url_to_rag_store",
        "integration_script": "url_to_integration_script"
    }
    return jsonify(data)

# 📦 Download zipped rag_db
@app.route('/download-rag-db', methods=['GET'])
def download_rag_db():
    zip_rag_db()
    return send_file(ZIP_FILENAME, as_attachment=True)

# 🐍 Download setup script
@app.route('/download-setup-script', methods=['GET'])
def download_setup_script():
    if not os.path.exists(SCRIPT_FILENAME):
        return jsonify({"error": "setup_project.py not found"}), 404
    return send_file(SCRIPT_FILENAME, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
