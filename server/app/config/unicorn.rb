# Set the working application directory
working_directory "/home/holocam/holocam/server/app"

# Unicorn PID file location
pid "/home/holocam/holocam/server/app/tmp/unicorn.pid"

# Path to logs
stderr_path "/home/holocam/holocam/server/app/tmp/unicorn.err"
stdout_path "/home/holocam/holocam/server/app/tmp/unicorn.log"

# Unicorn socket
listen "/home/holocam/holocam/server/app/tmp/unicorn.sock"

# Number of processes
worker_processes 4

# Time-out
timeout 30
