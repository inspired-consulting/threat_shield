FROM elixir:1.15.4-alpine as dev_environment

ENV LANG=C.UTF-8
ENV MIX_ENV=dev

WORKDIR /app

# Install inotify-tools for live-reload during development
RUN apk add --no-cache inotify-tools build-base npm

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the application source code into the container
COPY . /app/

# Install dependencies and compile the application
RUN mix deps.get && mix deps.compile && mix compile

# Expose port 4000 from the container to the host:
EXPOSE 4000

# run the phoenix server with inotify-tools:
CMD ["mix", "phx.server"]