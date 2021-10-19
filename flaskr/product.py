from flask import Blueprint, flash, g, redirect, render_template, request, url_for
from sqlalchemy import text
from werkzeug.exceptions import abort

from flaskr.auth import login_required
from flaskr.db import get_db

bp = Blueprint("product", __name__)


@bp.route("/")
def index():
    db = get_db()
    products = db.execute(
        text(
            "SELECT p.id, p.name, p.description, p.price, p.created_at, p.seller_id, u.first_name"
            " FROM products p JOIN users u ON p.seller_id = u.id"
            " ORDER BY p.created_at DESC"
        )
    ).fetchall()
    return render_template("product/index.html", products=products)


@bp.route("/create", methods=("GET", "POST"))
@login_required
def create():
    if request.method == "POST":
        name = request.form["name"]
        description = request.form["description"]
        price = request.form["price"]
        error = None

        if not name:
            error = "Name is required."
        elif not description:
            error = "Description is required."
        elif not price:
            error = "Price is required."

        if error is not None:
            flash(error)
        else:
            db = get_db()
            db.execute(
                text(
                    "INSERT INTO products (name, description, price, seller_id)"
                    " VALUES (:name, :description, :price, :seller_id)"
                ),
                {
                    "name": name,
                    "description": description,
                    "price": price,
                    "seller_id": g.user["id"],
                },
            )
            db.commit()
            return redirect(url_for("product.index"))

    return render_template("product/create.html")


def get_product(id, check_seller=True):
    product = (
        get_db()
        .execute(
            text(
                "SELECT p.id, p.name, p.description, p.price, p.created_at, p.seller_id, u.first_name"
                " FROM products p JOIN users u ON p.seller_id = u.id"
                " WHERE p.id = :id"
            ),
            {"id": id},
        )
        .fetchone()
    )

    if product is None:
        abort(404, f"Product id {id} doesn't exist.")

    if check_seller and product["seller_id"] != g.user["id"]:
        abort(403)

    return product


@bp.route("/<int:id>/update", methods=("GET", "POST"))
@login_required
def update(id):
    product = get_product(id)

    if request.method == "POST":
        name = request.form["name"]
        description = request.form["description"]
        price = request.form["price"]
        error = None

        if not name:
            error = "Name is required."
        elif not description:
            error = "Description is required."
        elif not price:
            error = "Price is required."

        if error is not None:
            flash(error)
        else:
            db = get_db()
            db.execute(
                text(
                    "UPDATE products SET name = :name, description = :description, price = :price"
                    " WHERE id = :id",
                ),
                {"name": name, "description": description, "price": price, "id": id},
            )
            db.commit()
            return redirect(url_for("product.index"))

    return render_template("product/update.html", product=product)


@bp.route("/<int:id>/delete", methods=("POST",))
@login_required
def delete(id):
    get_product(id)
    db = get_db()
    db.execute(text("DELETE FROM products WHERE id = :id"), {"id": id})
    db.commit()
    return redirect(url_for("product.index"))
