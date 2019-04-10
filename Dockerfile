FROM ubuntu:18.04

# Install basic requirements and create cardano user
RUN apt-get update && apt-get install -y build-essential bzip2 curl sudo git net-tools locales
RUN apt-get clean && rm -fr /var/lib/apt/lists/*
RUN useradd -ms /bin/bash cardano

# Install nix as cardano user
RUN mkdir /nix && chown cardano /nix
RUN mkdir -p /etc/nix
RUN echo binary-caches = https://cache.nixos.org https://hydra.iohk.io > /etc/nix/nix.conf
RUN echo binary-cache-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= >> /etc/nix/nix.conf
RUN echo sandbox = false >> /etc/nix/nix.conf

#COPY nix.conf /etc/nix/
USER cardano
# The nix install script needs USER to be set
ENV USER cardano

RUN curl -k https://nixos.org/nix/install | sh

# Clone and build cardano-sl
WORKDIR /home/cardano
RUN git clone https://github.com/input-output-hk/cardano-sl.git

WORKDIR /home/cardano/cardano-sl

RUN git checkout tags/3.0.1

RUN . /home/cardano/.nix-profile/etc/profile.d/nix.sh && \
    nix-build -A cardano-sl-node-static --cores 0 --max-jobs 2 --out-link master

RUN . /home/cardano/.nix-profile/etc/profile.d/nix.sh && \
    nix-build -A connectScripts.mainnet.wallet -o connect-to-mainnet

EXPOSE 8090

CMD ./connect-to-mainnet --runtime-args --no-tls
