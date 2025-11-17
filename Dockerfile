# Railway deployment Dockerfile for Ichiran
# Combines PostgreSQL, SBCL, and Node.js in a single container

FROM debian:bookworm-slim

# Install system dependencies
RUN apt update && apt -y install locales
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8
RUN locale-gen ja_JP.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install PostgreSQL, SBCL, Node.js, and other dependencies
RUN    DEBIAN_FRONTEND=noninteractive \
       apt-get update \
    && apt-get install -y \
       wget \
       postgresql \
       postgresql-client \
       git \
       sbcl \
       rlwrap \
       curl \
       supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Setup PostgreSQL
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql

# Download Ichiran database dump
ARG ICHIRAN_DB_URL="https://github.com/tshatrov/ichiran/releases/download/ichiran-250113/ichiran-250113.pgdump"
RUN wget $ICHIRAN_DB_URL --quiet -O /ichiran.pgdump && chmod o+r /ichiran.pgdump

# Install quicklisp
WORKDIR /root
RUN wget https://beta.quicklisp.org/quicklisp.lisp
RUN sbcl --load quicklisp.lisp --non-interactive \
         --eval "(quicklisp-quickstart:install)" \
         --eval "(ql-util:without-prompting (ql:add-to-init-file))" \
         --eval "(sb-ext:quit)"

# Clone JMDictDB
WORKDIR /root
RUN git clone https://gitlab.com/yamagoya/jmdictdb.git

# Copy Ichiran source code
COPY ./  /root/quicklisp/local-projects/ichiran/
WORKDIR /root/quicklisp/local-projects/ichiran

# Setup Ichiran settings
RUN cp docker/settings.lisp settings.lisp

# Load Ichiran
RUN sbcl --non-interactive --eval "(ql:quickload :ichiran)"

# Install Node.js API dependencies
WORKDIR /root/quicklisp/local-projects/ichiran/api
RUN npm install

# Add scripts to PATH
ENV PATH=/root/quicklisp/local-projects/ichiran/docker/ichiran-scripts:$PATH

# Copy supervisor configuration
COPY supervisor.conf /etc/supervisor/conf.d/ichiran.conf

# Copy startup script
WORKDIR /root/quicklisp/local-projects/ichiran
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose API port
EXPOSE 3000

# Use startup script as entrypoint
ENTRYPOINT ["/start.sh"]

