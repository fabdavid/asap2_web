#!/bin/sh

echo 'Remove old pids...'
rm tmp/pids/*
echo 'Start delayed_job...'
RAILS_ENV=development /app/bin/delayed_job --pool=fast:1 --pool=medium:1 --pool=slow:1  start
echo 'Start puma...'
puma -C config/puma.rb 2>&1 > log/puma.log
