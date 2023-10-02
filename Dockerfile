FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev bash emacs docker shadow wget git openssh mailx netcat-openbsd pigz sqlite postgresql boost boost-dev
RUN apk add openjdk8-jre curl #default-jre default-jdk
#RUN echo "relayhost = mail.epfl.ch" >> /etc/postfix/main.cf
#RUN /etc/init.d/postfix start

ARG BOOST_VERSION=1.75.0
ARG BOOST_DIR=boost_1_75_0
ENV BOOST_VERSION ${BOOST_VERSION}

#install HDF5
RUN wget -O hdf5.tar.gz http://gecftools.epfl.ch/share/fab/hdf5-1.10.6-linux-centos7-x86_64-shared.tar.gz; tar -zxf hdf5.tar.gz
#RUN tar -zxf hdf5.tar.gz
ENV LD_LIBRARY_PATH=/hdf5-1.10.6-linux-centos7-x86_64-gcc485-shared/lib/
ENV PATH=$PATH:/hdf5-1.10.6-linux-centos7-x86_64-gcc485-shared/bin
RUN cd /hdf5-1.10.6-linux-centos7-x86_64-shared/bin && ./h5redeploy -force && cd / && rm hdf5.tar.gz && rm -rf hdf5-1.10.6-linux-centos7-x86_64-shared


RUN apk add --no-cache --virtual .build-dependencies \
    linux-headers \
    && wget http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_DIR}.tar.bz2 \
    && tar --bzip2 -xf ${BOOST_DIR}.tar.bz2 \
    && cd ${BOOST_DIR} \
    && ./bootstrap.sh \
    && ./b2 --without-python --prefix=/usr -j 4 link=shared runtime-link=shared install \
   # && cd .. && rm -rf ${BOOST_DIR} ${BOOST_DIR}.tar.bz2 \
    && apk del .build-dependencies

WORKDIR /app

COPY Gemfile Gemfile.lock ./
#RUN bundle update
RUN touch /mimetypes
ENV FREEDESKTOP_MIME_TYPES_PATH=/mimetypes
RUN bundle install --binstubs
COPY . ./

RUN wget http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_DIR}.tar.bz2

RUN mkdir /var/log/nginx

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