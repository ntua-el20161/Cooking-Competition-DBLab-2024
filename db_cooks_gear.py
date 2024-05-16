import mysql.connector
import random
from datetime import datetime, timedelta
from itertools import product

# Function to execute SQL queries
def execute_query(connection, query):
    cursor = connection.cursor()
    cursor.execute(query)
    connection.commit()

# Connect to your MySQL database
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    port="8887",  # Adjust the port if necessary
    password="root",
    database="cooking_show"
)

if conn.is_connected():
    print("Connected to MySQL database")


# Function to reset auto-increment ID to start from 1
def reset_auto_increment():
    query = "ALTER TABLE cook AUTO_INCREMENT = 1"
    execute_query(conn, query)

# Function to generate dummy data for cook table
def generate_dummy_cooks(num_cooks):
    # List of standard first and last names
    first_names = ['John', 'Emma', 'Michael', 'Sophia', 'William', 'Olivia', 'James', 'Amelia', 'Benjamin', 'Isabella', 'Daniel', 'Mia', 'Matthew', 'Charlotte', 'Jackson', 'Evelyn', 'Samuel', 'Harper', 'David', 'Abigail']
    last_names = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson']

    # Generate permutations of first and last names to create unique combinations
    name_combinations = list(product(first_names, last_names))

    for i in range(num_cooks):
        first_name, last_name = random.choice(name_combinations)
        phone_number = f"{random.randint(1000000000, 9999999999)}"
        birthdate = datetime.now() - timedelta(days=random.randint(20*365, 60*365))
        age = datetime.now().year - birthdate.year
        yrs_of_exp = random.randint(1, 30)
        episode_count = 0  # Set episode count to 0
        cook_rank = random.choice(['A cook', 'B cook', 'C cook', 'Chef Assistant', 'Chef'])
        query = f"INSERT INTO cook (first_name, last_name, phone_number, birthdate, age, yrs_of_exp, episode_count, cook_rank) VALUES ('{first_name}', '{last_name}', '{phone_number}', '{birthdate}', {age}, {yrs_of_exp}, {episode_count}, '{cook_rank}')"
        execute_query(conn, query)


# Reset auto-increment ID to start from 1
reset_auto_increment()

# Generate dummy data for cook table
generate_dummy_cooks(100)  # Generate 100 dummy cooks

# Define gear data
gear_data = [
    ("Chef''s Knife", "Use for chopping, slicing, and dicing."),
    ("Cutting Board", "Place ingredients on this surface for cutting."),
    ("Mixing Bowls", "Use for mixing ingredients."),
    ("Measuring Cups", "Measure liquid ingredients accurately."),
    ("Measuring Spoons", "Measure dry and liquid ingredients accurately."),
    ("Whisk", "Use for blending and mixing ingredients."),
    ("Spatula", "Use for flipping food items."),
    ("Tongs", "Use for flipping and gripping hot food items."),
    ("Grater", "Use for grating cheese, vegetables, etc."),
    ("Peeler", "Use for peeling fruits and vegetables."),
    ("Rolling Pin", "Use for rolling out dough."),
    ("Pastry Brush", "Use for applying egg wash or glaze."),
    ("Oven Mitts", "Use to handle hot dishes and pans."),
    ("Baking Sheet", "Use for baking cookies, sheet cakes, etc."),
    ("Mixing Spoon", "Use for stirring ingredients."),
    ("Strainer", "Use for draining pasta or washing vegetables."),
    ("Colander", "Use for draining pasta, rice, etc."),
    ("Chef''s Apron", "Wear to protect clothing from spills and stains."),
    ("Kitchen Timer", "Use to time cooking and baking."),
    ("Food Thermometer", "Use to check the internal temperature of cooked foods."),
    ("Kitchen Scale", "Use for precise measurement of ingredients."),
    ("Can Opener", "Use to open cans."),
    ("Kitchen Shears", "Use for cutting herbs, vegetables, and meat."),
    ("Potato Masher", "Use for mashing cooked potatoes or other vegetables.")
]

# Insert gear data into the database
for gear in gear_data:
    title, instructions = gear
    query = f"INSERT INTO gear (title, instructions) VALUES ('{title}', '{instructions}')"
    execute_query(conn, query)


# Close the connection when done
conn.close()
