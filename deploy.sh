#!/bin/bash
# deploy.sh – runs on EC2

# Navigate and restart
cd "$(dirname "$0")" || exit
# e.g., if it’s a Node app:
# pm2 stop myapp || true
# pm2 start app.js --name myapp

echo "Deployed at $(date)" >> deploy.log
