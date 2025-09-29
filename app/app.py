from flask import Flask, jsonify, render_template, request
import pymysql
import os

app = Flask(__name__)

# Database connection settings from environment variables
DB_HOST = os.environ.get("DB_HOST", "mysql")  # Service name in namespace
DB_USER = os.environ.get("DB_USER")           # Must come from Secret
DB_PASSWORD = os.environ.get("DB_PASSWORD")   # Must come from Secret
DB_NAME = os.environ.get("DB_NAME")           # Must come from Secret

def get_db_connection():
    if not all([DB_HOST, DB_USER, DB_PASSWORD, DB_NAME]):
        raise Exception("Database configuration environment variables are missing")

    connection = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    return connection

@app.route('/health')
def health():
    return "Up & Running"

@app.route('/create_table')
def create_table():
    connection = get_db_connection()
    cursor = connection.cursor()
    create_table_query = """
        CREATE TABLE IF NOT EXISTS example_table (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL
        )
    """
    cursor.execute(create_table_query)
    connection.commit()
    connection.close()
    return "Table created successfully"

@app.route('/insert_record', methods=['POST'])
def insert_record():
    data = request.get_json()
    name = data.get('name')

    if not name:
        return jsonify({"error": "Missing 'name' in request body"}), 400

    connection = get_db_connection()
    cursor = connection.cursor()
    insert_query = "INSERT INTO example_table (name) VALUES (%s)"
    cursor.execute(insert_query, (name,))
    connection.commit()
    connection.close()
    return "Record inserted successfully"

@app.route('/data')
def data():
    connection = get_db_connection()
    cursor = connection.cursor()
    cursor.execute('SELECT * FROM example_table')
    result = cursor.fetchall()
    connection.close()
    return jsonify(result)

# UI route
@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    # Debug disabled for production; host/port set for Docker/Kubernetes
    app.run(debug=False, host='0.0.0.0', port=5000)
