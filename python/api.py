from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from pymongo.server_api import ServerApi
import os

app = Flask(__name__)
CORS(app)

uri = "mongodb+srv://henryliu714:hayun@cluster0.9m6an.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
# MongoDB Atlas connection string
client = MongoClient(uri, server_api=ServerApi('1'))
db = client["hackbrown"]
collection = db["users"]

try:
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
except Exception as e:
    print(e)

@app.route("/items", methods=["GET"])
def get_items():
    user_id = request.args.get("user_id")
    if not user_id:
        return jsonify({"error": "user_id parameter is required"}), 400
    items = list(collection.find({"user_id": user_id}, {"_id": 0}))  # Exclude ObjectId
    return jsonify(items)

@app.route("/items", methods=["POST"])
def add_item():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
    collection.insert_one(data)
    return jsonify({"message": "Item added successfully"}), 201

if __name__ == "__main__":
    app.run(debug=True)
