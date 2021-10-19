import pytest
from sqlalchemy import text


from flaskr.db import get_db


@pytest.mark.parametrize("path", ("/1/purchase",))
def test_login_required(client, path):
    response = client.post(path)
    assert response.headers["Location"] == "http://localhost/auth/login"


@pytest.mark.parametrize("path", ("/4/purchase",))
def test_exists_required(client, auth, path):
    auth.login()
    assert client.post(path).status_code == 404


def test_purchase(client, auth, app):
    auth.login()
    assert client.get("/1/purchase").status_code == 200
    client.post(
        "/1/purchase",
        data={
            "street_1": "234 Example St",
            "street_2": "",
            "city": "Exampleville",
            "state": "NY",
            "zip": "23456",
        },
    )

    with app.app_context():
        db = get_db()
        count = db.execute(text("SELECT COUNT(id) FROM purchases")).fetchone()[0]
        assert count == 2


@pytest.mark.parametrize("path", ("/1/purchase",))
def test_purchase_validate(client, auth, path):
    auth.login()
    response = client.post(
        path, data={"street_1": "", "street_2": "", "city": "", "state": "", "zip": ""}
    )
    assert b"Street is required." in response.data
