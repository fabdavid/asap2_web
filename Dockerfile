FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .
COPY db/asap2.dump /dumps/asap2.dump
LABEL maintainer="Fabrice David <fabrice.david@epfl.ch>"

CMD puma -C config/puma.rb

