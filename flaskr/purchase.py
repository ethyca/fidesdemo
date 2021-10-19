from flask import Blueprint, flash, g, redirect, render_template, request, url_for
from sqlalchemy import text

from flaskr.auth import login_required
from flaskr.db import get_db
from flaskr.product import get_product

bp = Blueprint("purchase", __name__)


@bp.route("/<int:product_id>/purchase", methods=("GET", "POST"))
@login_required
def create(product_id):
    product = get_product(product_id, check_seller=False)

    if request.method == "POST":
        street_1 = request.form["street_1"]
        street_2 = request.form["street_2"]
        city = request.form["city"]
        state = request.form["state"]
        zip = request.form["zip"]
        error = None

        if not product_id:
            error = "Product ID is required."
        elif not street_1:
            error = "Street is required."
        elif not city:
            error = "City is required."
        elif not state:
            error = "State is required."
        elif not zip:
            error = "Zip is required."

        if error is not None:
            flash(error)
        else:
            db = get_db()
            db.execute(
                text(
                    "INSERT INTO purchases (product_id, street_1, street_2, city, state, zip, buyer_id)"
                    " VALUES (:product_id, :street_1, :street_2, :city, :state, :zip, :buyer_id)"
                ),
                {
                    "product_id": product_id,
                    "street_1": street_1,
                    "street_2": street_2,
                    "city": city,
                    "state": state,
                    "zip": zip,
                    "buyer_id": g.user["id"],
                },
            )
            db.commit()
            return redirect(url_for("product.index"))

    return render_template("purchase/create.html", product=product)
