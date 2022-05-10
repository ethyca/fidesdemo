import functools

from flask import (
    Blueprint,
    flash,
    g,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from sqlalchemy import text
from sqlalchemy import exc
from werkzeug.security import check_password_hash, generate_password_hash

from flaskr.db import get_db

bp = Blueprint("auth", __name__, url_prefix="/auth")


@bp.route("/register", methods=("GET", "POST"))
def register():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]
        first_name = request.form["first_name"]
        last_name = request.form["last_name"]
        db = get_db()
        error = None

        if not email:
            error = "Email is required. "
        elif not password:
            error = "Password is required. "
        elif not first_name:
            error = "First Name is required. "
        elif not last_name:
            error = "Last Name is required. "

        if error is None:
            try:
                db.execute(
                    text(
                        "INSERT INTO users (email, password, first_name, last_name)"
                        " VALUES (:email, :password, :first_name, :last_name)"
                    ),
                    {
                        "email": email,
                        "password": generate_password_hash(password),
                        "first_name": first_name,
                        "last_name": last_name,
                    },
                )
                db.commit()
            except exc.IntegrityError:
                error = f"Email {email} is already registered."
            else:
                return redirect(url_for("auth.login"))

        flash(error)

    return render_template("auth/register.html")


@bp.route("/login", methods=("GET", "POST"))
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]
        db = get_db()
        error = None
        user = db.execute(
            text("SELECT * FROM users WHERE email = :email"),
            {"email": email},
        ).fetchone()

        if user is None:
            error = "Incorrect email."
        elif not check_password_hash(user["password"], password):
            error = "Incorrect password."

        if error is None:
            session.clear()
            session["user_id"] = user["id"]
            return redirect(url_for("index"))

        flash(error)

    return render_template("auth/login.html")


@bp.before_app_request
def load_logged_in_user():
    user_id = session.get("user_id")

    if user_id is None:
        g.user = None
    else:
        g.user = (
            get_db()
            .execute(
                text("SELECT * FROM users WHERE id = :user_id"),
                {"user_id": user_id},
            )
            .fetchone()
        )


@bp.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if g.user is None:
            return redirect(url_for("auth.login"))

        return view(**kwargs)

    return wrapped_view
