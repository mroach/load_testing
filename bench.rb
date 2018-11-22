#!/usr/bin/env ruby

require "net/http"

SYSTEM_CPUS = case RUBY_PLATFORM
when /linux/
  `nproc`.to_i
when /darwin/
  `sysctl -n hw.ncpu`.to_i
else 1
end

# Detect if `wrk` is available
begin
  Process.wait(Process.spawn("wrk --help", out: File.open("/dev/null", "w")))
rescue Errno::ENOENT
  abort "Can't find the wrk binary. Is it installed? Aborting"
end

DEFAULT_WORKERS = [(SYSTEM_CPUS * 0.8).floor, 3].max

# Default way to connect to the app server. PORT will also be used for starting
# local app servers on the correct port so we know where to find them
HOST = "127.0.0.1"
PORT = 7000

WRK_CONNECTIONS = ENV.fetch("WRK_CONNECTIONS", "10").to_i
WRK_DURATION = ENV.fetch("WRK_DURATION", "5s")

puts "System has #{SYSTEM_CPUS} CPUs. Default workers: #{DEFAULT_WORKERS}"

Test = Struct.new(:dir, :cmd, :env, :host, :port) do
  def initialize(dir: nil, cmd: nil, env: {}, host: HOST, port: PORT)
    super(dir, cmd, env, host, port)
  end
end

tests = {
  rails_w2: Test.new(
    dir: "ruby/railshost",
    cmd: "bundle exec puma -w 2 -p #{PORT} -e production --preload"),

  rails_w4: Test.new(
    dir: "ruby/railshost",
    cmd: "bundle exec puma -w 4 -p #{PORT} -e production --preload"),

  rails_w6: Test.new(
    dir: "ruby/railshost",
    cmd: "bundle exec puma -w 6 -p #{PORT} -e production --preload"),

  hanami: Test.new(
    dir: "ruby/hanamihost",
    cmd: "bundle exec puma -w #{DEFAULT_WORKERS} -p #{PORT} -e production --preload"),

  phoenix: Test.new(
    dir: "elixir/phoenixhost",
    cmd: "mix phx.server",
    env: {"MIX_ENV" => "prod", "PORT" => PORT.to_s}),

  amber: Test.new(
    dir: "crystal/amberhost",
    cmd: "bin/amberhost_prod",
    env: {"AMBER_ENV" => "production", "PORT" => PORT.to_s})
}

def alive?
  uri = URI("http://#{HOST}:#{PORT}/warmup")
  Net::HTTP.get_response(uri).code == "200"
rescue Errno::ECONNREFUSED
  false
end

def started_after_waiting?(limit:)
  current = 0
  begin
    return true if alive?
    puts "Waiting for app to warmup... (#{current}/#{limit})"
    sleep 1
    current += 1
  end until current >= limit
  return false
end

def start_server(name, spec)
  env_desc = spec.env.map { |k,v| "#{k}=#{v}" }.join(" ")
  log_file = File.open("results/log/#{name}_server_output.log", "w+")

  puts "Starting server: #{spec.dir} $ #{env_desc} #{spec.cmd}"

  # Process grouping was required for Amber in production.
  # Otherwise it would only shutdown the parent process but not the children.
  # The only way it shutdown properly was SIGTERM with process grouping.
  # Return the pid as a negative number to indicate it's a process group
  -Process.spawn(spec.env, spec.cmd, chdir: spec.dir, out: log_file, pgroup: true)
end

def shutdown_server(pid)
  pid_type = pid < 0 ? "process group" : "process"
  Process.kill("TERM", pid)
  puts "Waiting for server #{pid_type} (#{pid}) to shutdown..."
  Process.wait(pid)
end

tests.each do |name, spec|
  puts "\n---------- #{name} ----------\n\n"

  if spec.cmd.present?
    pid = start_server(name, spec)
    unless started_after_waiting?(limit: 20)
      STDERR.puts "Failed to get warmup response from #{name} server"
      next
    end

    puts "Server running at #{pid}"
  else
    pid = nil
  end

  platform = Net::HTTP.get(URI("http://#{HOST}:#{PORT}/platform"))
  puts "Platform is #{platform}"

  result_file = "results/#{name}_bench_results.json"

  Kernel.system(
    {"WRK_JSON_OUT" => result_file, "WRK_JSON_DESC" => platform},
    "wrk -c #{WRK_CONNECTIONS} -d #{WRK_DURATION} -s bench.lua http://#{HOST}:#{PORT}"
  )

  shutdown_server(pid) unless pid.nil?

  puts "Done"
end
