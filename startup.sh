#!/bin/sh

echo 'Remove old pids...'
rm tmp/pids/*
echo 'print env'
env
echo 'Start delayed_job...'
#RAILS_ENV=development /app/bin/delayed_job --pool=fast:5 --pool=medium:1 --pool=slow:1  start
RAILS_ENV=development /app/bin/delayed_job --pool=fast:10  start

echo 'Start sunspot'
bundle exec rake sunspot:solr:start

echo 'Start puma and daemon...'
puma -C config/puma.rb 2>&1 > log/puma.log & #&& rails exec_runs --trace 2>&1 > log/exec_runs.log

#echo 'Start puma in the background...'
#puma -C config/puma.rb > log/puma.log 2>&1 &

#echo 'Start rails exec_runs as a background task...'
#rails exec_runs --trace > log/exec_runs.log 2>&1 &

# Keep the script running to ensure container does not stop
# Optionally block here if needed, but no `wait` if processes run forever
#echo 'Both processes started. Startup script completed.'
