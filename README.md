# Cooking Competition DB Lab 2024

## Overview

This project is a database lab exercise designed to manage a cooking competition using MySQL and Python. The repository includes SQL scripts for database setup and Python scripts for data population. Written as views, various complex queries regarding the competition are implemented. 

## Installation & Configuration

### Prerequisites

- Installed **MySQL**
- Installed **Python 3**
- Installed **MySQL Connector for Python**. To install it, run the following command in the terminal:
  ```sh
  pip3 install mysql-connector-python
  ```

### Setup Instructions

1. Navigate to your desired folder and initialize a Git repository:
   ```sh
   git init
   ```
2. Clone the repository from GitHub and navigate into it:
   ```sh
   git clone https://github.com/ntua-el20161/Cooking-Competition-DBLab-2024.git
   cd Cooking-Competition-DBLab-2024
   ```
3. Connect to MySQL and create a database for the application:
   ```sh
   mysql -u root -p
   ```
   Then, inside the MySQL shell, run:
   ```sql
   CREATE DATABASE cooking_show;
   USE cooking_show;
   ```
4. Load the database schema from the `ddl.sql` script:
   ```sql
   SOURCE ddl.sql;
   ```
5. Before exiting MySQL, check the port where your database is running:
   ```sql
   SHOW VARIABLES LIKE 'port';
   EXIT;
   ```
6. Open the `db_data.py` file using a text editor and update the database connection details on **line 18**, setting the correct port, password, and database name:
   ```sh
   vim db_data.py
   ```
7. Save and close the file.
8. Run the `db_data.py` script to populate the database with sample data:
   ```sh
   python3 db_data.py
   ```
9. Wait for the script to complete. If successful, you should see the message:
   ```
   Dummy data inserted successfully into all tables.
   ```
10. You can now reconnect to MySQL and check your data.

## License

This project is for educational purposes and follows an open-source license.

