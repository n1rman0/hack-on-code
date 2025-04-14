from flask import Flask, jsonify

app = Flask(__name__)

# Sample JSON data
data = {
    "merchant_public_key": "rzp_test_1a2b3c4d5e6f7g",
    "merchant_secret": "a1b2c3d4e5f6g7h8i9j0",
    "merchant_flavour": "standard",
    "merchant_sample_order_id": "order_9A33XWu170gUtm"
}

@app.route('/data', methods=['GET'])
def get_data():
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
