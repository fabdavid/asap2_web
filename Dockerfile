FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev bash emacs docker

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .
LABEL maintainer="Fabrice David <fabrice.david@epfl.ch>"

CMD puma -C config/puma.rb

