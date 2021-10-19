import pytest
from sqlalchemy import text

from flaskr.db import get_db


def test_index(client, auth):
    response = client.get("/")
    assert b"Log In" in response.data
    assert b"Register" in response.data

    auth.login()
    response = client.get("/")
    print(response.data)
    assert b"Log Out" in response.data
    assert b"Example Product 1" in response.data
    assert b"by Admin on 2020-01-01" in response.data
    assert b"A description for example product #1" in response.data
    assert b'href="/1/update"' in response.data


@pytest.mark.parametrize(
    "path",
    (
        "/create",
        "/1/update",
        "/1/delete",
    ),
)
def test_login_required(client, path):
    response = client.post(path)
    assert response.headers["Location"] == "http://localhost/auth/login"


def test_seller_required(app, client, auth):
    # change the product seller to another user
    with app.app_context():
        db = get_db()
        db.execute(text("UPDATE products SET seller_id = 2 WHERE id = 1"))
        db.commit()

    auth.login()
    # current user can't modify other user's product
    assert client.post("/1/update").status_code == 403
    assert client.post("/1/delete").status_code == 403
    # current user doesn't see edit link
    assert b'href="/1/update"' not in client.get("/").data


@pytest.mark.parametrize(
    "path",
    (
        "/4/update",
        "/4/delete",
    ),
)
def test_exists_required(client, auth, path):
    auth.login()
    assert client.post(path).status_code == 404


def test_create(client, auth, app):
    auth.login()
    assert client.get("/create").status_code == 200
    client.post(
        "/create",
        data={
            "name": "created",
            "description": "created description",
            "price": "50.00",
        },
    )

    with app.app_context():
        db = get_db()
        count = db.execute(text("SELECT COUNT(id) FROM products")).fetchone()[0]
        assert count == 4


def test_update(client, auth, app):
    auth.login()
    assert client.get("/1/update").status_code == 200
    client.post(
        "/1/update",
        data={
            "name": "updated",
            "description": "updated description",
            "price": "100.00",
        },
    )

    with app.app_context():
        db = get_db()
        product = db.execute(text("SELECT * FROM products WHERE id = 1")).fetchone()
        assert product["name"] == "updated"
        assert product["price"] == 100.00


@pytest.mark.parametrize(
    "path",
    (
        "/create",
        "/1/update",
    ),
)
def test_create_update_validate(client, auth, path):
    auth.login()
    response = client.post(path, data={"name": "", "description": "", "price": ""})
    assert b"Name is required." in response.data


def test_delete(client, auth, app):
    auth.login()
    response = client.post("/2/delete")
    assert response.headers["Location"] == "http://localhost/"

    with app.app_context():
        db = get_db()
        product = db.execute(text("SELECT * FROM products WHERE id = 2")).fetchone()
        assert product is None
