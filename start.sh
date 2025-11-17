#!/bin/bash
set -e

echo "=========================================="
echo "Starting Ichiran Railway Deployment"
echo "=========================================="

# Initialize PostgreSQL data directory if needed
if [ ! -d "/var/lib/postgresql/data/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/data -E UTF8 --locale=ja_JP.UTF-8"
fi

# Start PostgreSQL
echo "Starting PostgreSQL..."
su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data -l /var/log/postgresql/postgresql.log start"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if su - postgres -c "psql -l" > /dev/null 2>&1; then
        echo "PostgreSQL is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: PostgreSQL failed to start"
        exit 1
    fi
    sleep 1
done

# Check if database exists
DB_EXISTS=$(su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -w jmdict | wc -l")

if [ "$DB_EXISTS" -eq "0" ]; then
    echo "Creating Ichiran database..."
    su - postgres -c "createdb -E 'UTF8' -l 'ja_JP.UTF-8' -T template0 jmdict"
    
    echo "Restoring database from dump..."
    su - postgres -c "pg_restore -d jmdict /ichiran.pgdump --no-owner --no-privileges" || true
    echo "Database restoration completed (some warnings are normal)"
else
    echo "Database already exists, skipping initialization"
fi

# Initialize Ichiran if not already done
if [ ! -e /root/.ichiran-initialized ]; then
    echo "Initializing Ichiran..."
    cd /root/quicklisp/local-projects/ichiran
    
    # Set connection string environment variable
    export ICHIRAN_CONNECTION='("jmdict" "postgres" "" "localhost")'
    
    # Initialize SBCL core and CLI
    echo "Building Ichiran SBCL core..."
    /root/quicklisp/local-projects/ichiran/docker/ichiran-scripts/init-sbcl
    
    echo "Building Ichiran CLI..."
    /root/quicklisp/local-projects/ichiran/docker/ichiran-scripts/init-cli
    
    touch /root/.ichiran-initialized
    echo "Ichiran initialization complete!"
else
    echo "Ichiran already initialized"
fi

# Set environment variables for API server
export ICHIRAN_CONNECTION='("jmdict" "postgres" "" "localhost")'
export PORT=${PORT:-3000}

# Start API server
echo "Starting Ichiran API server on port $PORT..."
cd /root/quicklisp/local-projects/ichiran/api
exec node server.js

