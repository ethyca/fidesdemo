#!/bin/bash

# Run the fidesops webserver as a background task
fidesops webserver &

# Start the fidesops admin UI
cd clients/admin-ui && npx next start -p 3000 &

# Start the fidesops privacy center
# TODO: Enable a production build once this issue is fixed: https://github.com/ethyca/fidesops/issues/492
cd clients/privacy-center && npx next dev -p 4000 &

# Wait for all processes to exit
wait -n
exit $?