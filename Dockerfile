FROM elixir:1.15.4-alpine as dev_environment

ENV LANG=C.UTF-8
ENV MIX_ENV=dev

WORKDIR /app

# Install inotify-tools for live-reload during development
RUN apk add --no-cache inotify-tools build-base npm git

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the application source code into the container
COPY . /app/

# Copy the entrypoint script into the container and make it executable
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose port 4000 from the container to the host:
EXPOSE 4000

# Fetch dependencies and compile the application
RUN mix deps.get && mix deps.compile

# Set the default command to run when starting the container
CMD ["/app/entrypoint.sh"]

