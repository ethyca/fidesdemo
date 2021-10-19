.DEFAULT_GOAL := help
.PHONY: help install server test compose-up teardown clean black

help:
	@echo --------------------
	@echo Development Targets:
	@echo ----
	@echo install - Creates a virtual environment, installs, and initializes the project, including docker compose containers
	@echo ----
	@echo server - Runs the Flask server in development mode, including using compose-up to start all dependencies
	@echo ----
	@echo test - Runs the pytest suite, including using compose-up to start all dependencies
	@echo ----
	@echo compose-up - Uses docker compose to bring up the project dependencies including databases, Fides servers, etc.
	@echo ----
	@echo teardown - Brings down the docker compose environment
	@echo ----
	@echo clean - Runs various commands to wipe out everything: the virtual environment, temporary files, docker containers, volumes, etc.
	@echo ----
	@echo black - Auto-formats project code with Black
	@echo --------------------

####################
# Dev
####################

install: compose-up
	@echo "Creating virtual environment ./venv..."
	@python3 -m venv venv
	@echo "Installing project dependencies..."
	@./venv/bin/pip install -r requirements.txt
	@./venv/bin/pip install -e .
	@echo "Initializing Flask database..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/flask init-db
	@echo "Done! Run '. venv/bin/activate' to activate venv"

server: compose-up
	@echo "Starting Flask server..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/flask run

test: compose-up
	@echo "Running pytest..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/pytest

####################
# Utils
####################

compose-up:
	@echo "Bringing up docker containers..."
	@docker compose up -d
	@pg_isready --host localhost --port 5432 || (echo "Waiting 5s for Postgres to start..." && sleep 5)

teardown:
	@echo "Bringing down docker containers..."
	@docker compose down --remove-orphans

reset-db: teardown
	@echo "Resetting database..."
	docker volume rm fidesdemo_postgres
	@make compose-up
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/flask init-db

clean: teardown
	@echo "Cleaning project files, docker containers, volumes, etc...."
	docker system prune -a --volumes
	rm -rf instance/ venv/ __pycache__/

black:
	@echo "Auto-formatting project code with Black..."
	./venv/bin/black flaskr/ tests/
