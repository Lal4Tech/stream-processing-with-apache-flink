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