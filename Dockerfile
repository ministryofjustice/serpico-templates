# Originally author, https://github.com/ncolyer-r7
FROM ubuntu:16.04
MAINTAINER MoJ-SET

# Packages & Environment Variables
ENV SRP_ROOT /Serpico
ENV GEM /usr/local/rvm/rubies/ruby-2.3.3/bin/gem
ENV BUILD_PACKAGES bash sudo curl vim git gawk g++ gcc make libc6-dev libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgmp-dev libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev

# Install Packages
RUN apt-get update && \
    apt-get install -y $BUILD_PACKAGES
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Pull Down Serpico
RUN git clone https://github.com/SerpicoProject/Serpico.git
WORKDIR Serpico
#RUN git reset --hard 5f8828bcb4499a1c70277c26e4e3d6624d62285d
WORKDIR $SRP_ROOT

# Install Ruby
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
RUN /bin/bash -l -c rvm requirements
RUN /bin/bash --login -c "source /usr/local/rvm/scripts/rvm"
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN rvm install 2.3.3 && rvm use 2.3.3
RUN rvm all do gem install bundler

# Install Required Gems
RUN /bin/bash --login -c "bundle install"

# Expose TCP:443
RUN sed -i -e 's/"port":"8443",/"port":"443",/g' $SRP_ROOT/config.json
EXPOSE 443

# Run the first time script to build the DB, this can be removed
RUN /bin/bash --login -c "echo -e \"\n\n\" | ruby scripts/first_time.rb"
