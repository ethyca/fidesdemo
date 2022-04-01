FROM node:16

# TODO: update to stable image
RUN git clone https://github.com/elliotbonneville/fidesops.git /home/node/fidesops

WORKDIR /home/node/fidesops/clients/admin-ui

RUN npm install

COPY ./.env.development /home/node/fidesops/clients/admin-ui/

# TODO: optimize production build?
# RUN npm run build

CMD ["npm", "run", "dev"]
