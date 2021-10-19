import click
from flask import current_app, g
from flask.cli import with_appcontext
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text

_db = SQLAlchemy()


def get_db():
    return _db.session


def init_db():
    db = get_db()

    # Initialize our schema, one statement at a time (SQLAlchemy doesn't play
    # nice with multi-statement SQL)
    statements = [
        "DROP TABLE IF EXISTS purchases;",
        "DROP TABLE IF EXISTS products;",
        "DROP TABLE IF EXISTS users;",
        """
        CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL
        );
        """,
        """
        CREATE TABLE products (
            id SERIAL PRIMARY KEY,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            seller_id INTEGER NOT NULL,
            name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            FOREIGN KEY (seller_id) REFERENCES users (id)
        );
        """,
        """
        CREATE TABLE purchases (
            id SERIAL PRIMARY KEY,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            product_id INTEGER NOT NULL,
            buyer_id INTEGER NOT NULL,
            street_1 TEXT,
            street_2 TEXT,
            city TEXT,
            state TEXT,
            zip TEXT,
            FOREIGN KEY (product_id) REFERENCES products (id),
            FOREIGN KEY (buyer_id) REFERENCES users (id)
        );
        """,
        """
        INSERT INTO users (created_at, email, password, first_name, last_name)
        VALUES
            ('2020-01-01 00:00:00', 'admin@example.com', 'pbkdf2:sha256:260000$O87nanbSklOZOMKh$f297bf9daa9f5e2d84c3792c75800204edd2f5a5934bd23988ca840333642321', 'Admin', 'User'),
            ('2020-01-03 00:00:00', 'user@example.com', 'pbkdf2:sha256:260000$PGcBy5NzZeDdlu0b$a91ee29eefad98920fe47a6ef4d53b5abffe593300f766f02de041af93ae51f8', 'Example', 'User')
        ;
        """,
        """
        INSERT INTO products (created_at, seller_id, name, description, price)
        VALUES
            ('2020-01-01 12:00:00', 1, 'Example Product 1', 'A description for example product #1', '10.00'),
            ('2020-01-02 12:00:00', 1, 'Example Product 2', 'A description for example product #2', '20.00'),
            ('2020-01-03 12:00:00', 2, 'Example Product 3', 'A description for example product #3', '50.00')
        ;
        """,
        """
        INSERT INTO purchases (created_at, product_id, buyer_id, street_1, street_2, city, state, zip)
        VALUES
            ('2020-01-04 12:00:00', 1, 2, '123 Example St', 'Apt 123', 'Exampletown', 'NY', '12345')
        ;
        """,
    ]
    for statement in statements:
        db.execute(text(statement))
    db.commit()


@click.command("init-db")
@with_appcontext
def init_db_command():
    """Clear the existing data and create new tables."""
    init_db()
    click.echo("Initialized the database.")


def init_app(app):
    _db.init_app(app)
    app.cli.add_command(init_db_command)
