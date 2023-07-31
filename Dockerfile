FROM elixir:1.15.4-alpine as dev_environment

ENV LANG=C.UTF-8
ENV MIX_ENV=dev

ADD https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/x86_64_qemu-aarch64-static.tar.gz /usr/bin
RUN tar -xzf /usr/bin/x86_64_qemu-aarch64-static.tar.gz -C /usr/bin && rm /usr/bin/x86_64_qemu-aarch64-static.tar.gz

WORKDIR /app

# Install inotify-tools for live-reload during development
RUN apk add --no-cache inotify-tools build-base npm

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the application source code into the container
COPY . /app

# Install dependencies and compile the application
RUN mix deps.get && mix deps.compile && mix compile

# Start Phoenix live-reload (adjust based on your Phoenix version)
# For Phoenix 1.5 and later:
CMD ["mix", "phx.server"]
