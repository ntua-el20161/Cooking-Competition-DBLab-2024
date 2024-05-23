import mysql.connector

# Function to execute SQL queries
def execute_query(connection, query, data=None):
    cursor = connection.cursor()
    if data:
        cursor.execute(query, data)
    else:
        cursor.execute(query)
    connection.commit()


# Connect to your MySQL database
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    port="3306",  # Adjust the port if necessary
    password="root",
    database="cooking_show"
)

if conn.is_connected():
    print("Connected to MySQL database")


