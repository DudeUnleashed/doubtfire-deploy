FROM mcr.microsoft.com/devcontainers/ruby:dev-3.3

# DEBIAN_FRONTEND=noninteractive is required to install tzdata in non interactive way
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
  && apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common librsvg2-bin \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
  && add-apt-repository "deb [arch=amd64,arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  && curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

ENV USER='vscode'
ENV NODE_VERSION 20.14.0
ENV NODE_ENV docker
ENV NPM_CONFIG_PREFIX="/home/${USER}/.npm-global"
ENV BUNDLE_PATH=/home/${USER}/.gems

COPY --chown="${USER}":"${USER}" doubtfire-api/.ci-setup/ /workspace/doubtfire-api/.ci-setup/

RUN apt-get update \
  && apt-get install -y \
    lsb-release \
    ffmpeg \
    ghostscript \
    qpdf \
    imagemagick \
    libmagic-dev \
    libmagickwand-dev \
    libmariadb-dev \
    python3-pygments \
    tzdata \
    wget \
    libc6-dev \
    mariadb-server \
    gosu \
    redis \
    inkscape \
    docker-ce \
    docker-ce-cli \
    containerd.io \
  && apt-get clean \
  && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 4ED778F539E3634C779C87C6D7062848A1AB005C \
  # Beth Griggs
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 141F07595B7B3FFE74309A937405533BE57C7D57 \
  # Bryan English
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 74F12602B6F1C4E913FAA37AD3A89613643B6201 \
  # Danielle Adams
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
  # Juan José Arboleda
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
  # Marco Ippolito
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  # Michaël Zasso
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  # Myles Borins
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
  # Rafael Gonzaga
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
  # Richard Lau
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys 108F52B48DB57BB0CC439B2997B01419BD92F80A \
  # Ruy Adorno
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys A363A499291CBBC940DD62E41F10027AF002F8B0 \
  # Ulises Gascón
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version \
  && gem install bundler -v '~> 2.5.11' \
  && /workspace/doubtfire-api/.ci-setup/texlive-install.sh \
  && rm -rf /workspace/doubtfire-api/.ci-setup/texlive-install.sh \
  && rm -rf /install-tl-* \
  && mkdir /run/mysqld

USER "${USER}"

WORKDIR /workspace

RUN mkdir -p "${NPM_CONFIG_PREFIX}/lib" \
  && npm install -g npm@10.8.1 \
  && npm install -g husky --save-dev \
  && npm install -g @angular/cli \
  && npm i -g standard-version

# Install oh-my-zsh, powerlevel10k theme, and plugins
RUN git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k \
  && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
  && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

ENV GEM_HOME /home/vscode/.gems
RUN /usr/local/rvm/bin/rvm implode --force

ENV RAILS_ENV development
ENV PATH /home/$USER/.gems/ruby/3.3.0/bin:$PATH:/tmp/texlive/bin/x86_64-linux:/tmp/texlive/bin/aarch64-linux:$PATH:/home/$USER/.npm-global/bin
ENV GEM_PATH /home/$USER/.gems/ruby/3.3.0:$GEM_PATH

# Install the web ui
WORKDIR /workspace/doubtfire-web
COPY --chown="${USER}":"${USER}" doubtfire-web/package.json /workspace/doubtfire-web

# Install web ui packages
RUN npm install -f

# Setup the folder where we will deploy the code
WORKDIR /workspace/doubtfire-api

COPY --chown="${USER}":"${USER}" doubtfire-api/Gemfile /workspace/doubtfire-api/Gemfile
COPY --chown="${USER}":"${USER}" doubtfire-api/Gemfile.lock /workspace/doubtfire-api/Gemfile.lock

RUN bundle install

WORKDIR /workspace

RUN sudo ln -s /workspace/doubtfire-api /doubtfire

EXPOSE 9876

COPY --chown="${USER}":"${USER}" .devcontainer /workspace/.devcontainer

ENV HISTFILE /workspace/tmp/.zsh_history

RUN sudo chmod +x /workspace/.devcontainer/*.sh
RUN sudo rm -rf /var/lib/mysql/* && \
    sudo chown vscode:vscode /var/lib/mysql && \
    mkdir /workspace/tmp && \
    sudo mkdir /student-work && \
    sudo chown vscode:vscode /student-work

ENTRYPOINT [ "/workspace/.devcontainer/docker-entrypoint.sh" ]
CMD [ "sleep", "infinity" ]
