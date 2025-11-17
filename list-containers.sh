#!/bin/bash
#
# List of Docker containers, sorted alphabetically by the image names used.
#

# print header only
# \t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}
docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}'  | head -1

# print without header and sorted by image name
docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}' | sort -k2 | column -t -s $'\t'
