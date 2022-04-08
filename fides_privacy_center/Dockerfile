FROM ethyca/fidesops:1.4.0

# Install node v16 on top of the fideops image
RUN \
    curl -sL 'https://deb.nodesource.com/setup_16.x' | bash - \
    && apt-get install -y nodejs

WORKDIR /fidesops/clients/privacy-center

RUN npm install

COPY ./config /fidesops/clients/privacy-center/config

CMD ["npm", "run", "dev"]