.DEFAULT_GOAL := help
.PHONY: help install server test fidesctl-evaluate fidesops-request fidesops-test compose-up teardown reset-db clean black

help:
	@echo --------------------
	@echo Development Targets:
	@echo ----
	@echo preinstall - Checks versions of dependencies for Python, Docker, etc.
	@echo ----
	@echo install - Creates a virtual environment, installs, and initializes the project, including docker compose containers
	@echo ----
	@echo server - Runs the Flask server in development mode, including using compose-up to start all dependencies
	@echo ----
	@echo test - Runs the pytest suite, including using compose-up to start all dependencies
	@echo ----
	@echo fidesctl-evaluate - Uses fidesctl to perform a dry policy evaluation of the project manifests in .fides/
	@echo ----
	@echo fidesctl-generate-dataset - Uses fidesctl to generate an example dataset from the Postgres schema
	@echo ----
	@echo fidesops-request - Uses fidesops to interactively configure policy and execute privacy requests
	@echo ----
	@echo fidesops-test - Runs fidesops-request in test mode with additional logging and pauses
	@echo ----
	@echo compose-up - Uses docker compose to bring up the project dependencies including databases, Fides servers, etc.
	@echo ----
	@echo teardown - Brings down the docker compose environment
	@echo ----
	@echo reset-db - Removes the Postgres database and reinitializes it
	@echo ----
	@echo clean - Runs various commands to wipe out everything: the virtual environment, temporary files, docker containers, volumes, etc.
	@echo ----
	@echo black - Auto-formats project code with Black
	@echo --------------------

####################
# Dev
####################

preinstall:
	@echo "*************************************************"
	@echo "*                  FIDES DEMO                   *"
	@echo "*************************************************"
	@echo "Checking versions of fidesdemo dependencies:"
	@python3 --version
	@docker --version
	@docker-compose --version
	@pg_config --version

install: preinstall compose-up
	@echo "Creating virtual environment ./venv..."
	@python3 -m venv venv
	@echo "Installing project dependencies using pip version:"
	@./venv/bin/pip --version
	./venv/bin/pip install -r requirements.txt
	./venv/bin/pip install -e .
	@echo "Initializing Flask & Fidesops..."
	@make flaskr-init
	@make fidesops-init
	@make teardown
	@echo "Done! Run '. venv/bin/activate' to activate venv"
	@echo "Run 'make demo' to bring up all services"
	@echo "****************************************"
	@echo "* TODO: Remove these manual steps!     *"
	@echo "****************************************"
	@echo "To use 'fidesctl generate system aws' set the following:"
	@echo "export AWS_ACCESS_KEY_ID=..."
	@echo "export AWS_SECRET_ACCESS_KEY=..."
	@echo "export AWS_DEFAULT_REGION=..."
	@echo "To use Mailchimp for fidesops set the following:"
	@echo "export MAILCHIMP_DOMAIN..."
	@echo "export MAILCHIMP_USERNAME..."
	@echo "export MAILCHIMP_API_KEY=..."
	@echo "To use fidesops admin UI run the following:"
	@echo "sudo -- sh -c -e \"echo '127.0.0.1 fidesops' >> /etc/hosts\""
	@echo "Don't forget to remove this line from /etc/hosts afterwards!"


demo:
	@echo "*************************************************"
	@echo "*                  FIDES DEMO                   *"
	@echo "*                                               *"
	@echo "*       (use 'make teardown' to shutdown)       *"
	@echo "*       (use 'make reset-db' to reset db)       *"
	@echo "* (use 'make fidesops-watch' to reload config)  *"
	@echo "*************************************************"
	@make compose-up
	@echo "Example eCommerce demo app running at http://localhost:2000 (user: exampleuser@ethyca.com, pass: exampleuser)"
	@echo "Opening in browser in 5 seconds..."
	@sleep 5 && open http://localhost:8080/docs &
	@sleep 5 && open http://localhost:9090/docs &
	@sleep 5 && open http://localhost:4000 &
	@sleep 5 && open http://localhost:3000/login &
	@sleep 5 && open http://localhost:2000 &
	@sleep 6 && open fides_uploads &
	@FLASK_APP=flaskr FLASK_ENV=development FLASK_RUN_PORT=2000 ./venv/bin/flask run


server: compose-up
	@echo "Starting Flask server... (user: user@example.com, pass: user)"
	FLASK_APP=flaskr FLASK_ENV=development FLASK_RUN_PORT=2000 ./venv/bin/flask run

test: compose-up
	@echo "Running pytest..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/pytest

####################
# fidesctl
####################

fidesctl-evaluate: compose-up
	@echo "Evaluating policy with fidesctl..."
	./venv/bin/fidesctl evaluate --dry .fides

fidesctl-export-datamap: compose-up
	@echo "Exporting datamap from fidesctl..."
	rm -f .fides/*.xlsx
	./venv/bin/fidesctl apply
	./venv/bin/fidesctl export datamap
	open .fides/*.xlsx

fidesctl-generate-dataset: compose-up
	@echo "Generating dataset with fidesctl..."
	./venv/bin/fidesctl generate dataset postgresql://postgres:postgres@localhost:6432/flaskr .fides/generated_dataset.yml

fidesctl-generate-system: compose-up
	@echo "Generating systems with fidesctl..."
	./venv/bin/fidesctl generate system aws .fides/generated_aws_systems.yml

fidesctl-scan-system: compose-up
	@echo "Scanning system coverage with fidesctl..."
	./venv/bin/fidesctl scan system aws

####################
# fidesops
####################

fidesops-request: export FIDESOPS__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL=False
fidesops-request: compose-up
	@echo "Configuring fidesops and running an example request..."
	./venv/bin/python flaskr/fidesops.py

fidesops-test: compose-up
	@echo "Configuring fidesops in test mode to run an example request..."
	./venv/bin/python flaskr/fidesops.py --test

fidesops-watch:
	@make fidesops-init
	@echo "Setting up watchdog on .fides/ directory to re-initialize fidesops..."
	@./venv/bin/watchmedo shell-command \
	  --command="make fidesops-init" \
	  --drop \
	  .fides/

####################
# Utils
####################

compose-up:
	@echo "Bringing up docker containers..."
	@docker-compose up -d
	@pg_isready --host localhost --port 6432 || (echo "Waiting 5s for Postgres to start..." && sleep 5)
	@echo "Fidesops running at http://localhost:8080/docs"
	@echo "Fidesctl running at http://localhost:9090/docs"
	@echo "Fidesops Privacy Center running at http://localhost:4000"
	@echo "Fidesops Admin UI running at http://localhost:3000/login (user: fidesopsuser, pass: fidesops1A!)"

teardown:
	@echo "Bringing down docker containers..."
	@docker-compose down --remove-orphans

reset-db: teardown
	@echo "Removing database..."
	docker volume rm fidesdemo_postgres
	@make compose-up
	@make flaskr-init
	@make fidesops-init
	@make teardown

flaskr-init:
	@echo "Initializing Flask database..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/flask init-db

fidesops-init:
	@echo "Initializing fidesops..."
	./venv/bin/python flaskr/fidesops.py --setup-only

clean: teardown
	@echo "Cleaning project files, docker containers, volumes, etc...."
	docker-compose down --remove-orphans --volumes --rmi all
	docker system prune --force
	rm -rf instance/ venv/ __pycache__/
	rm -f fides_uploads/*.json
	rm -f .fides/*.xlsx
	@echo For a deeper clean, use "docker system prune -a --volumes"

black:
	@echo "Auto-formatting project code with Black..."
	./venv/bin/black flaskr/ tests/
