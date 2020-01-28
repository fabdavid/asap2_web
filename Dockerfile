FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev bash emacs docker shadow wget git openssh mailx netcat-openbsd pigz sqlite postgresql
RUN apk add openjdk8-jre #default-jre default-jdk
#RUN echo "relayhost = mail.epfl.ch" >> /etc/postfix/main.cf
#RUN /etc/init.d/postfix start

WORKDIR /app

COPY Gemfile Gemfile.lock ./
#RUN bundle update
RUN bundle install --binstubs
COPY . ./

#RUN apk-install sudo
#### add dockerroot group
RUN groupdel docker
RUN groupadd --gid 995 docker

ENV USER=rvmuser USER_ID=1006 USER_GID=1006

# now creating user
RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --shell /bin/bash \
${USER}

RUN usermod -a -G docker "${USER}"

USER ${USER}

#COPY user_mapping.sh /
#RUN chmod a+x /user_mapping.sh
#ENTRYPOINT ["/user_mapping.sh"]

LABEL maintainer="Fabrice David <fabrice.david@epfl.ch>"

COPY startup.sh /
CMD sh -c /startup.sh