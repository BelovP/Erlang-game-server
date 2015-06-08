#!/bin/bash

echo "Navigate your browser to http://localhost:8090/"
erl  -s inets -s game_http_server -config my_server

