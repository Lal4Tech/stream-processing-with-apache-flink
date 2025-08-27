SHOW CATALOGS;

-- Create a new Database
CREATE DATABASE bank;

SHOW DATABASES;

-- Use the newly created database.
USE bank;


SHOW TABLES;

SHOW VIEWS;

-- Set the Flink client result mode to Tableau
SET sql-client.execution.result-mode = 'tableau';

-- Create the transactions table.
CREATE TABLE transactions (
	transactionId STRING,
	accountId STRING,
	customerId STRING,
	eventTime BIGINT,
	eventTime_ltz AS TO_TIMESTAMP_LTZ(eventTime, 3),
	eventTimeFormatted STRING,
	type STRING,
	operation STRING,
	amount DOUBLE,
	balance DOUBLE,
    // `ts` TIMESTAMP(3) METADATA FROM 'timestamp'
	WATERMARK FOR eventTime_ltz AS eventTime_ltz
) WITH (
	'connector' = 'kafka',
	'topic' = 'transactions',
	'properties.bootstrap.servers' = 'redpanda:9092',
	'properties.group.id' = 'group.transactions',
	'format' = 'json',
	'scan.startup.mode' = 'earliest-offset'
);
-- More info: https://nightlies.apache.org/flink/flink-docs-master/docs/dev/table/sql/create/#create-table

-- Select data from the transactions table
SELECT
	transactionId,
	eventTime_ltz,
	type,
	amount,
	balance
FROM transactions;

-- Create the customers table.
CREATE TABLE customers (
	customerId STRING,
	sex STRING,
	social STRING,
	fullName STRING,
	phone STRING,
	email STRING,
	address1 STRING,
	address2 STRING,
	city STRING,
	state STRING,
	zipcode STRING,
	districtId STRING,
	birthDate STRING,
	updateTime BIGINT,
	eventTime_ltz AS TO_TIMESTAMP_LTZ(updateTime, 3),
	WATERMARK FOR eventTime_ltz AS eventTime_ltz,
	PRIMARY KEY (customerId) NOT ENFORCED
) WITH (
	'connector' = 'upsert-kafka',
	'topic' = 'customers',
	'properties.bootstrap.servers' = 'redpanda:9092',
	'key.format' = 'raw',
	'value.format' = 'json',
	'properties.group.id' = 'group.customers'
);

-- Select data from the customers table
SELECT
	customerId,
	fullName,
	social,
	birthDate,
	updateTime
FROM customers;

-- Create the accounts table.
CREATE TABLE accounts (
	accountId STRING,
	districtId INT,
	frequency STRING,
	creationDate STRING,
	updateTime BIGINT,
	eventTime_ltz AS TO_TIMESTAMP_LTZ(updateTime, 3),
	WATERMARK FOR eventTime_ltz AS eventTime_ltz,
	PRIMARY KEY (accountId) NOT ENFORCED
) WITH (
	'connector' = 'upsert-kafka',
	'topic' = 'accounts',
	'properties.bootstrap.servers' = 'redpanda:9092',
	'key.format' = 'raw',
	'value.format' = 'json',
	'properties.group.id' = 'group.accounts'
);

-- Select data from the accounts table
SELECT 
    *
FROM 
    accounts;

-- Stateless Operators

-- Find all the debit transactions with an amount > 180.000
SELECT
	transactionId,
	eventTime_ltz,
	type,
	amount,
	balance
FROM transactions
WHERE amount > 180000
  AND type = 'Credit'
ORDER BY eventTime_ltz;

-- Temporary Views
CREATE TEMPORARY VIEW temp_premium AS
SELECT
	transactionId,
	eventTime_ltz,
	type,
	amount,
	balance
FROM transactions
WHERE amount > 180000
  AND type = 'Credit'
ORDER BY eventTime_ltz;

SELECT * FROM temp_premium;

SHOW VIEWS;

-- Materializing Operators
-- Find the total transactions per customer
SELECT
	customerId,
	COUNT(transactionId) AS txnCount
FROM transactions
GROUP BY customerId
LIMIT 10;

-- Which customers made more than 1000 transactions?
SELECT *
FROM (
	SELECT customerId, COUNT(transactionId) AS txnPerCustomer
	FROM transactions
	GROUP BY customerId
) AS e
WHERE txnPerCustomer > 500;

-- Temporal Operators
-- Records and computations are associated with a temporal condition.

-- Built-in functions
SELECT
	transactionId,
	eventTime_ltz,
	convert_tz(
		cast(eventTime_ltz as string),
		'Europe/London', 'UTC'
	) AS eventTime_ltz_utc,
	type,
	amount,
	balance
FROM transactions
WHERE amount > 180000
  AND type = 'Credit';

-- Running SQL Queries with Code


SELECT 
	transactionId, rowNum
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (
			PARTITION BY transactionId
	 		ORDER BY eventTime_ltz
		) AS rowNum
	 	FROM transactions
)
WHERE 
	rowNum = 1;