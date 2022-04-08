FROM ethyca/fidesops:1.4.0

# Install node v16 on top of the fideops image
RUN \
    curl -sL 'https://deb.nodesource.com/setup_16.x' | bash - \
    && apt-get install -y nodejs

WORKDIR /fidesops/clients/admin-ui

RUN npm install

COPY ./.env.development /fidesops/clients/admin-ui/

CMD ["npm", "run", "dev"]