FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev bash emacs docker shadow

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs
COPY . ./

#RUN apk-install sudo
#### add dockerroot group
RUN groupadd --gid 987 dockerroot

ENV USER=rvmuser USER_ID=60000 USER_GID=1001

# now creating user
RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
${USER}

RUN usermod -G dockerroot "${USER}"

USER ${USER}

#COPY user_mapping.sh /
#RUN chmod a+x /user_mapping.sh
#ENTRYPOINT ["/user_mapping.sh"]

LABEL maintainer="Fabrice David <fabrice.david@epfl.ch>"

COPY startup.sh /
CMD sh -c /startup.sh