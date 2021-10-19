import pytest
from flask import g, session
from sqlalchemy import text


from flaskr.db import get_db


def test_register(client, app):
    assert client.get("/auth/register").status_code == 200
    response = client.post(
        "/auth/register",
        data={"email": "a", "password": "a", "first_name": "a", "last_name": "a"},
    )
    assert "http://localhost/auth/login" == response.headers["Location"]

    with app.app_context():
        assert (
            get_db()
            .execute(
                text("SELECT * FROM users WHERE email = 'a'"),
            )
            .fetchone()
            is not None
        )


@pytest.mark.parametrize(
    ("email", "password", "first_name", "last_name", "message"),
    (
        ("", "", "a", "a", b"Email is required."),
        ("a", "", "a", "a", b"Password is required."),
        ("admin@example.com", "admin", "a", "a", b"already registered"),
    ),
)
def test_register_validate_input(
    client, email, password, first_name, last_name, message
):
    response = client.post(
        "/auth/register",
        data={
            "email": email,
            "password": password,
            "first_name": first_name,
            "last_name": last_name,
        },
    )
    assert message in response.data


def test_login(client, auth):
    assert client.get("/auth/login").status_code == 200
    response = auth.login()
    assert response.headers["Location"] == "http://localhost/"

    with client:
        client.get("/")
        assert session["user_id"] == 1
        assert g.user["email"] == "admin@example.com"


@pytest.mark.parametrize(
    ("email", "password", "message"),
    (
        ("a", "admin", b"Incorrect email."),
        ("admin@example.com", "a", b"Incorrect password."),
    ),
)
def test_login_validate_input(auth, email, password, message):
    response = auth.login(email, password)
    assert message in response.data
