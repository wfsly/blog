#!/bin/bash

# start blog container
docker run --name blog -d -p 4000:4000 -v $HOME/blog:/blog blog
