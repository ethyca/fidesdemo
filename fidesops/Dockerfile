# Demo Dockerfile that packages the fidesops webserver, admin UI, and privacy center in a single container
FROM ethyca/fidesops:1.7.2

# Install node v16 on top of the fidesops image
RUN \
    curl -sL 'https://deb.nodesource.com/setup_16.x' | bash - \
    && apt-get install -y nodejs

# Install all the npm dependencies
WORKDIR /fidesops/clients/ops/admin-ui
RUN npm install
WORKDIR /fidesops/clients/ops/privacy-center
RUN npm install

# Build the admin UI
WORKDIR /fidesops/clients/ops/admin-ui
COPY clients/ops/admin-ui/. /fidesops/clients/ops/admin-ui/
# build error when running build
#RUN npx next build

# Build the privacy center
WORKDIR /fidesops/clients/ops/privacy-center
COPY clients/ops/privacy-center/config/. /fidesops/clients/ops/privacy-center/config/
# build error when running build
# RUN npx next build

ENV FIDESOPS__ROOT_USER__ANALYTICS_OPT_OUT=true

# Run our script to start all the services
WORKDIR /fidesops
COPY entrypoint.sh /fidesops/
CMD ./entrypoint.sh
