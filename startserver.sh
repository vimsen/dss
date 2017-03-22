#!/bin/bash
sudo -H -u dss bash -l << 'EOF'
. /home/dss/.bashrc
cd /home/dss/dashboard
bundle exec puma
EOF

