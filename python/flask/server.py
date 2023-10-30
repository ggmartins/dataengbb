from flask import Flask, request, send_from_directory
from flask_cors import CORS

app = Flask(__name__)
#cors = CORS(app,  resources={r"/*": {"origins": "*"}})

#@app.after_request
#def after_request(response):
#    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
#    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS')
#    return response

@app.route("/", methods=["GET"])
def index():
    return send_from_directory('../Docker-Image/files/www/',"index.html")

@app.route("/downloading", methods=["POST"])
def upload():
    print("Downloading...")
    return "OK"

@app.route("/upload", methods=["POST"])
def download():
    print("Uploading...")
    return "OK"

@app.route('/<path:path>')
def files(path):
    return send_from_directory('../Docker-Image/files/www/', path)

@app.route("/save", methods=["POST"])
def hello_world():
  print(request.form)
  return "OK"

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=4500)
