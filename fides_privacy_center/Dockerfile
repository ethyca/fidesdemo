# TODO: update to stable image
FROM ethyca/fidesops:1.3.0-38-g351fb23

# Install node v16 on top of the fideops image
RUN \
    curl -sL 'https://deb.nodesource.com/setup_16.x' | bash - \
    && apt-get install -y nodejs

WORKDIR /fidesops/clients/privacy-center

RUN npm install

COPY ./config /fidesops/clients/privacy-center/config

# TODO: optimize production build?
# RUN npm run build

CMD ["npm", "run", "dev"]