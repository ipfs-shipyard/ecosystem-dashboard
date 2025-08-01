FROM ruby:3.4.5-alpine

ENV APP_ROOT=/usr/src/app
ENV DATABASE_PORT=5432
WORKDIR $APP_ROOT

# =============================================
# System layer

# Will invalidate cache as soon as the Gemfile changes
COPY Gemfile Gemfile.lock $APP_ROOT/

# * Setup system
# * Install Ruby dependencies
RUN apk add --update \
    build-base \
    netcat-openbsd \
    git \
    nodejs \
    postgresql-dev \
    tzdata \
    curl-dev \
    openssl-dev \
    cmake \
    libffi-dev \
    yaml-dev \
    linux-headers \
 && rm -rf /var/cache/apk/* \
 && gem update --system \
 && gem install bundler foreman \
 && bundle config --global frozen 1 \
 && bundle config set without 'test' \
 && bundle config set force_ruby_platform true \
 && bundle install --jobs 2

# ========================================================
# Application layer

# Copy application code
COPY . $APP_ROOT

RUN bundle install --jobs 2

# Precompile assets for a production environment.
# This is done to include assets in production images on Dockerhub.
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bundle exec rake assets:precompile

# Startup
CMD ["bin/docker-start"]
