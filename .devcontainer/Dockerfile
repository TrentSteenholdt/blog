# Choose Debian OS version (bookworm, bullseye, or buster)
ARG VARIANT=3.2-bookworm
FROM mcr.microsoft.com/devcontainers/ruby:${VARIANT}

USER root

# Set environment variables for Jekyll
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US \
    TZ=Etc/UTC \
    LC_ALL=en_US.UTF-8

# Update system packages and install dependencies
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends build-essential libffi-dev libyaml-dev libgdbm-dev

# Ruby
RUN apt-get update && apt-get install -y \ 
    ruby \
    ruby-bundler \
    ruby-dev 

# Update RubyGems & install Bundler, Jekyll, and GitHub Pages
RUN gem update --system \
    && gem install bundler jekyll

# Set correct permissions for RVM
RUN chown -R vscode:rvm /usr/local/rvm/ && \
    chmod -R g+r+w /usr/local/rvm/ && \
    find /usr/local/rvm/ -type d -exec chmod g+s {} +

# Copy post-create script (if required)
COPY post-create.sh /usr/local/post-create.sh
RUN chmod +x /usr/local/post-create.sh