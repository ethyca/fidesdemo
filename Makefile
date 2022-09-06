.DEFAULT_GOAL := help

# Load in an .env file, if present
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help
help:
	@echo "--------------------"
	@echo "Demo targets:"
	@echo "----"
	@echo "help - Show this help"
	@echo "install - Creates a virtual environment, installs, and initializes the project, including docker compose containers"
	@echo "demo - Runs all Fides tools and the Flask server to demonstrate end-to-end usage"
	@echo "clean - Runs various commands to wipe out everything: the virtual environment, temporary files, docker containers, volumes, etc."
	@echo "reset-db - Removes the Postgres database used for Fides tools and Flask server, then reinitializes it"
	@echo "teardown - Brings down the docker compose environment"
	@echo "--------------------"
	@echo ""
	@echo "--------------------"
	@echo "Fidesops demo targets:"
	@echo "--------------------"
	@echo "fidesops-init - Initialize the fidesops server with default policies and the latest datasets from .fides/"
	@echo "fidesops-watch - Watch the .fides/ folder and automatically reinitializes fidesops when files are changed"
	@echo "fidesops-request - Uses fidesops to interactively configure policy and execute privacy requests"
	@echo "--------------------"
	@echo ""
	@echo "--------------------"
	@echo "Fidesctl demo targets:"
	@echo "--------------------"
	@echo "fidesctl-evaluate - Perform a dry policy evaluation of the project manifests in .fides/"
	@echo "fidesctl-apply - Apply the latest project manifests in .fides/ to the fidesctl server"
	@echo "fidesctl-export-datamap - Exports the fidesctl server's current state to a datamap XLSX (use 'fidesctl-apply' to update this)"
	@echo "fidesctl-generate-dataset-db - Automatically generates a dataset YAML by connecting to the Flask server's database locally"
	@echo "fidesctl-generate-system-aws - Automatically generates a system YAML by connecting to an AWS account (requires AWS credentials)"
	@echo "fidesctl-scan-system-aws - Generates a coverage report by comparing the fidesctl server's current systems to an AWS account (requires AWS credentials)"
	@echo "--------------------"
	@echo ""
	@echo "--------------------"
	@echo "Flaskr example webserver targets:"
	@echo "--------------------"
	@echo "server - Runs the Flask server in development mode, including using compose-up to start all dependencies"
	@echo "test - Runs the pytest suite, including using compose-up to start all dependencies"
	@echo "flaskr-init - Initializes the Flask servers database schema and test data"
	@echo "black - Auto-formats project code with Black"
	@echo "--------------------"

####################
# Demo
####################

.PHONY: preinstall
preinstall:
	@echo "Checking versions of fidesdemo dependencies:"
	@python3 --version
	@python3 -m platform
	@docker --version
	@docker-compose --version
	@pg_config --version

.PHONY: install
install: preinstall compose-up
	@echo "Creating virtual environment ./venv..."
	@python3 -m venv venv
	@echo "Installing project dependencies using pip version:"
	@./venv/bin/pip --version
	./venv/bin/pip install -r requirements.txt
	./venv/bin/pip install -e .
	@echo "Initializing Flask server..."
	@make flaskr-init
	@make teardown
	@echo "Done!"
	@echo "Run 'make demo' to bring up all services"
	@echo "Copy '.env.template' to create a '.env' file for secrets, if needed"

.PHONY: demo
demo: preinstall
	@make compose-up
	@make fidesops-init
	@echo ""
	@echo "*************************************************"
	@echo "*                  FIDES DEMO                   *"
	@echo "*                                               *"
	@echo "*       (use 'make teardown' to shutdown)       *"
	@echo "*       (use 'make reset-db' to reset db)       *"
	@echo "* (use 'make fidesops-watch' to reload config)  *"
	@echo "*      (edit '.env' to set ENV variables)       *"
	@echo "*     (see 'make help' for other commands)      *"
	@echo "*************************************************"
	@echo "Fidesops webserver running at http://localhost:8080/docs"
	@echo "Fidesctl webserver running at http://localhost:9090/docs"
	@echo "Fidesops Privacy Center running at http://localhost:4000"
	@echo "Fidesops Admin UI running at http://localhost:3000/login (user: fidesopsuser, pass: fidesops1A!)"
	@echo "Example eCommerce demo app running at http://localhost:2000 (user: user@example.com, pass: user)"
	@echo ""
	@echo "Opening in browser in 5 seconds..."
	@sleep 5 && open demo.html &
	@FLASK_APP=flaskr FLASK_ENV=development FLASK_RUN_PORT=2000 FLASK_SKIP_DOTENV=true ./venv/bin/flask run


####################
# Flaskr server
####################

.PHONY: server
server: compose-up
	@echo ""
	@echo "Starting Flask server... (user: user@example.com, pass: user)"
	FLASK_APP=flaskr FLASK_ENV=development FLASK_RUN_PORT=2000 ./venv/bin/flask run

.PHONY: test
test: compose-up
	@echo ""
	@echo "Running pytest..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/pytest

.PHONY: flaskr-init
flaskr-init:
	@echo ""
	@echo "Initializing Flask database..."
	FLASK_APP=flaskr FLASK_ENV=development ./venv/bin/flask init-db

.PHONY: black
black:
	@echo ""
	@echo "Auto-formatting project code with Black..."
	./venv/bin/black flaskr/ tests/

####################
# fidesctl
####################

.PHONY: fidesctl-evaluate
fidesctl-evaluate: compose-up
	@echo ""
	@echo "Evaluating policy with fidesctl..."
	./venv/bin/fidesctl evaluate --dry .fides

.PHONY: fidesctl-apply
fidesctl-apply: compose-up
	@echo ""
	@echo "Applying latest resources from .fides with fidesctl..."
	./venv/bin/fidesctl apply .fides

.PHONY: fidesctl-export-datamap
fidesctl-export-datamap: compose-up
	@echo ""
	@echo "Exporting datamap from fidesctl..."
	rm -f fides_tmp/*.xlsx
	rm -f .fides/*.xlsx
	./venv/bin/fidesctl apply
	./venv/bin/fidesctl export datamap
	mv .fides/*.xlsx fides_tmp/
	open fides_tmp/*.xlsx

.PHONY: fidesctl-generate-dataset-db
fidesctl-generate-dataset-db: compose-up
	@echo ""
	@echo "Generating dataset with fidesctl..."
	./venv/bin/fidesctl generate dataset db --connection-string postgresql://postgres:postgres@localhost:6432/flaskr .fides/generated_dataset.yml

.PHONY: fidesctl-aws-check-env
fidesctl-aws-check-env:
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_DEFAULT_REGION" ]; then\
		echo "ERROR: must set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_DEFAULT_REGION environment variables!";\
		exit 1;\
	fi

.PHONY: fidesctl-generate-system-aws
fidesctl-generate-system-aws: fidesctl-aws-check-env compose-up
	@echo ""
	@echo "Generating systems with fidesctl..."
	./venv/bin/fidesctl generate system aws .fides/generated_aws_systems.yml
	@echo "Done! To apply these systems to the fidesctl webserver, run 'make fidesctl-apply'"

.PHONY: fidesctl-scan-system-aws
fidesctl-scan-system-aws: fidesctl-aws-check-env compose-up
	@echo ""
	@echo "Scanning system coverage with fidesctl..."
	./venv/bin/fidesctl scan system aws || echo "Missing coverage! Use 'make fidesctl-generate-system-aws' to generate"

####################
# fidesops
####################

.PHONY: fidesops-request
fidesops-request:  export FIDESOPS__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL=False
# fixes issue with endless waiting for fidesops to be healthy (similar steps we do for make demo)
fidesops-request: preinstall
	@make compose-up
	@echo ""
	@echo "Configuring fidesops and running an example request..."
	./venv/bin/python flaskr/fidesops.py

.PHONY: fidesops-init
fidesops-init:
	@echo ""
	@echo "Initializing fidesops..."
	@./venv/bin/python flaskr/fidesops.py --setup-only

.PHONY: fidesops-watch
fidesops-watch:
	@make fidesops-init
	@echo ""
	@echo "Setting up watchdog on .fides/ directory to re-initialize fidesops..."
	@./venv/bin/watchmedo shell-command \
	  --command="make fidesops-init" \
	  --drop \
	  .fides/

####################
# Utils
####################

.PHONY: compose-up
compose-up:
	@echo "Rebuilding docker images as needed..."
	@docker-compose build
	@echo "Bringing up docker containers..."
	@docker-compose up -d
	@pg_isready --host localhost --port 6432 || (echo "Waiting 5s for Postgres to start..." && sleep 5)

.PHONY: teardown
teardown:
	@echo "Bringing down docker containers..."
	@docker-compose down --remove-orphans

.PHONY: reset-db
reset-db: teardown
	@echo "Removing database..."
	docker volume rm fidesdemo_postgres
	@make compose-up
	@make flaskr-init
	@make fidesops-init
	@make teardown

.PHONY: clean
clean: teardown
	@echo ""
	@echo "Cleaning project files, docker containers, volumes, etc...."
	docker-compose down --remove-orphans --volumes --rmi all
	docker system prune --force
	rm -rf instance/ venv/ __pycache__/
	rm -f fides_tmp/*.json
	rm -f fides_tmp/*.yml
	rm -f fides_tmp/*.xlsx
	rm -f .fides/generated*.yml
	@echo For a deeper clean, use "docker system prune -a --volumes"
