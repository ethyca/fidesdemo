# Demo Dockerfile that packages the fidesops webserver, admin UI, and privacy center in a single container
FROM ethyca/fidesops:1.4.1

# Install node v16 on top of the fideops image
RUN \
    curl -sL 'https://deb.nodesource.com/setup_16.x' | bash - \
    && apt-get install -y nodejs

# Install all the npm dependencies
WORKDIR /fidesops/clients/admin-ui
RUN npm install
WORKDIR /fidesops/clients/privacy-center
RUN npm install

# Build the admin UI
WORKDIR /fidesops/clients/admin-ui
COPY clients/admin-ui/. /fidesops/clients/admin-ui/
RUN npx next build

# Build the privacy center
WORKDIR /fidesops/clients/privacy-center
COPY clients/privacy-center/config/. /fidesops/clients/privacy-center/config/
# TODO: Enable a production build once this issue is fixed: https://github.com/ethyca/fidesops/issues/492
# RUN npx next build

# Run our script to start all the services
WORKDIR /fidesops
COPY entrypoint.sh /fidesops/
CMD ./entrypoint.sh