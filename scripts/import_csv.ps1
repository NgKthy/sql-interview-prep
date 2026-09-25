# scripts/import_csv.ps1
# Script import dữ liệu từ CSV vào MySQL

mysql --local-infile=1 -u root -p -e "
USE sql_interview_prep;

LOAD DATA LOCAL INFILE 'datasets/employees.csv'
INTO TABLE Employee
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'datasets/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
"
