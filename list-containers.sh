#!/bin/bash
#
# List of Docker containers, sorted alphabetically by the image names used.
#

# print header only
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}'  | head -1

# print without header and sorted by image name
docker ps -a --format '{{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}' | sort -k2 | column -t -s $'\t'
