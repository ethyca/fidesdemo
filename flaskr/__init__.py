import os

from flask import Flask

# NOTE: Defining these constants inline for simplicity, but in a real
# application these must be loaded from ENV or similar for security!
POSTGRES_URL = "postgresql://postgres:postgres@localhost:6432/flaskr"
GOOGLE_ANALYTICS_ID = "UA-xxxxxxxxx-y"
SECRET_KEY = "dev"


def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(
        SECRET_KEY=SECRET_KEY,
        SQLALCHEMY_DATABASE_URI=POSTGRES_URL,
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        GOOGLE_ANALYTICS_ID=GOOGLE_ANALYTICS_ID,
    )

    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile("config.py", silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # a simple page that says hello
    @app.route("/hello")
    def hello():
        return "Hello, World!"

    from . import db

    db.init_app(app)

    from . import auth

    app.register_blueprint(auth.bp)

    from . import product

    app.register_blueprint(product.bp)
    app.add_url_rule("/", endpoint="index")

    from . import purchase

    app.register_blueprint(purchase.bp)

    return app
