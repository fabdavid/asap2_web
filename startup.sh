#!/bin/sh

echo 'Remove old pids...'
rm tmp/pids/*
echo 'Start delayed_job...'
RAILS_ENV=development /app/bin/delayed_job --pool=fast:5 --pool=medium:1 --pool=slow:1  start
echo 'Start puma...'
puma -C config/puma.rb 2>&1 > log/puma.log
echo 'Start daemon...'
rails exec_runs --trace 2>&1 > log/exec_runs.log
