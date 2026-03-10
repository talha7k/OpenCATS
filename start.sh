#!/bin/bash

# Start Apache immediately in the background
echo "Starting Apache..."
service apache2 start

# Wait a moment for Apache to start
sleep 2

# Now run database setup in background
echo "Running database setup in background..."
/usr/local/bin/docker-entrypoint.sh &

# Keep the container running
tail -f /var/log/apache2/access.log /var/log/apache2/error.log 2>/dev/null || tail -f /dev/null
