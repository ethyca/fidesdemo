# Fides Demo Project

This is a basic Flask app that demonstrates the use of [`fidesctl`](https://github.com/ethyca/fides) and [`fidesops`](https://github.com/ethyca/fidesops) as part of a "real" project that uses:

* Flask to run a web server simulating a basic e-commerce application
* PostgreSQL as an application database
* SQLAlchemy to connect to the database
* `fidesctl` to declare privacy manifests and evaluate policies
* `fidesops` to execute privacy requests against the Flaskr database

The Flask app itself is simply the [Flask tutorial app](https://flask.palletsprojects.com/en/2.0.x/tutorial/) modified to simulate an e-commerce marketplace, in order to highlight some basic examples of data categories that might be stored in a "real" user-facing application.

![](fidesdemo.png)

## Requirements

This demo project is currently only supported on Mac OS, as the Makefile uses shell commands that aren't available on Windows.

To run this project, first ensure you have the following requirements installed and running on your machine:

* Docker 12+
* Python 3.7+
* Make
* `pg_config` (on Mac, install via `brew install libpq` or `brew install postgres`)

## Getting Started

To create the project `venv` and install requirements, run:
```
make install
```

Once installed you can run the full demo environment with:
```
make demo
```

After a few seconds, this will open several browser tabs to the various
services. Read the terminal output for more information!


Run an example fidesops privacy request with:
```
make fidesops-request
```

Run an example fidesctl privacy evaluation with:
```
make fidesctl-evaluate
```

## Example Application: "Flaskr"

This example application is meant to simulate a basic e-commerce marketplace where users can register and purchase products from each other. Using the website you can:
* Register a new user
* Login as a user
* Post a "product"
* Delete/update products you posted
* Submit a purchase to a product

The schema itself is designed to highlight a few *very* simple examples of how identifiable data might get stored in even a trivial web application like this. The sample data below shows what this looks like:
```
flaskr=# SELECT * FROM users;
 id |     created_at      |       email       |              password              | first_name | last_name 
----+---------------------+-------------------+------------------------------------+------------+-----------
  1 | 2020-01-01 00:00:00 | admin@example.com | pbkdf2:sha256:260000$O87nanbSkl... | Admin      | User
  2 | 2020-01-03 00:00:00 | user@example.com  | pbkdf2:sha256:260000$PGcBy5NzZe... | Example    | User
(2 rows)

flaskr=# SELECT * FROM products;
 id |     created_at      | seller_id |       name        |             description              | price 
----+---------------------+-----------+-------------------+--------------------------------------+-------
  1 | 2020-01-01 12:00:00 |         1 | Example Product 1 | A description for example product #1 |    10
  2 | 2020-01-02 12:00:00 |         1 | Example Product 2 | A description for example product #2 |    20
  3 | 2020-01-03 12:00:00 |         2 | Example Product 3 | A description for example product #3 |    50
(3 rows)

flaskr=# SELECT * FROM purchases;
 id |     created_at      | product_id | buyer_id |    street_1    | street_2 |    city     | state |  zip  
----+---------------------+------------+----------+----------------+----------+-------------+-------+-------
  1 | 2020-01-04 12:00:00 |          1 |        2 | 123 Example St | Apt 123  | Exampletown | NY    | 12345
(1 row)
```
## License

This project is licensed under the Apache Software License Version 2.0.
