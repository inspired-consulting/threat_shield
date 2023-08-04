#!/bin/sh

cd /app
mix deps.get
mix compile
mix phx.server