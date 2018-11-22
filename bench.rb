#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/http"

module BenchEnv
  module_function

  def connections
    ENV.fetch("WRK_CONNECTIONS", "10").to_i
  end

  def duration
    ENV.fetch("WRK_DURATION", "5s")
  end

  def wrk_available?
    Process.spawn("wrk --help", out: File.open("/dev/null", "w"))
  rescue Errno::ENOENT
    return false
  end
end

module ServerManager
  module_function

  SYSTEM_CPUS = case RUBY_PLATFORM
    when /linux/
      `nproc`.to_i
    when /darwin/
      `sysctl -n hw.ncpu`.to_i
    else 1
  end

  # For servers that need multiple workers, a decent option is 80% of real CPUs
  DEFAULT_WORKERS = [(SYSTEM_CPUS * 0.8).floor, 3].max

  # How many seconds to wait for a server to respond to the warmup request
  # before considering it dead
  DEFAULT_WARMUP_LIMIT = 20

  # Default way to connect to the app server. PORT will also be used for starting
  # local app servers on the correct port so we know where to find them
  DEFAULT_HOST = "127.0.0.1"
  DEFAULT_PORT = 7000

  def default_workers; DEFAULT_WORKERS; end

  def start(spec)
    env = inject_vars(spec.env, spec)
    cmd = inject_vars(spec.cmd, spec)

    env_desc = env.map { |k,v| "#{k}=#{v}" }.join(" ")
    log_file = File.open("results/log/#{name}_server_output.log", "w+")

    puts "Starting server: \e[33m#{spec.dir}$ #{env_desc} #{cmd}\e[0m"

    # Process grouping was required for Amber in production.
    # Otherwise it would only shutdown the parent process but not the children.
    # The only way it shutdown properly was SIGTERM with process grouping.
    Process.spawn(env, cmd, chdir: spec.dir, out: log_file, pgroup: true)
  end

  def shutdown(pid)
    # Send pid as negative number to kill the process group
    Process.kill("TERM", -Process.getpgid(pid))
    puts "Waiting for server (#{pid}) to shutdown..."
    Process.wait(pid)
  end

  def http_responding?(spec)
    Net::HTTP.get_response(spec.endpoint + "/warmup").code == "200"
  rescue Errno::ECONNREFUSED
    false
  end

  def server_process_alive?(pid)
    Process.getpgid(pid).positive?
  rescue Errno::ESRCH
    return false
  end

  def started_after_waiting?(spec, limit: DEFAULT_WARMUP_LIMIT)
    current = 0
    print "Waiting #{limit}s for app to warmup..."
    begin
      if http_responding?(spec)
        puts "DONE (took #{current}s)"
        return true
      end

      sleep 1
      current += 1
    end until current >= limit
    puts "FAILED"
    return false
  end

  def inject_vars(input, spec)
    if input.is_a?(Hash)
      input.transform_values { |val| inject_vars(val, spec) }
    elsif input.is_a?(String)
      input % {port: spec.port, host: spec.host, default_workers: default_workers}
    else
      intput
    end
  end
end

module Nginx
  module_function

  SOCK_PATH = "/tmp/benchmark_server_socket.sock"
  STATIC_PORT = 8081
  SOCK_PROXY_PORT = 8082
  TCP_PROXY_PORT = 8083

  TCP_TARGET_PORT = 7000

  def start
    conf = File.expand_path("./nginx/bench_server.conf")
    log = File.open("results/log/nginx", "w")
    cmd = "nginx -c #{conf}"
    puts "Starting \e[36m#{cmd}\e[0m"
    Process.spawn(cmd, out: log)
  end

  def shutdown(pid)
    puts "Shutting down nginx (#{pid})"
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end

BenchTarget = Struct.new(:dir, :cmd, :env, :host, :port, :nginx?) do
  def initialize(dir: nil, cmd: nil, env: {}, host: ServerManager::DEFAULT_HOST, port: ServerManager::DEFAULT_PORT, nginx: false)
    super(dir, cmd, env, host, port, nginx)
  end

  def should_start_server?
    !(cmd.nil? || cmd.empty?)
  end

  def endpoint
    URI("http://#{host}:#{port}")
  end
end

# Detect if `wrk` is available
abort "Can't find the wrk binary. Is it installed? Aborting" unless BenchEnv.wrk_available?

tests = {
  nginx: BenchTarget.new(host: "127.0.0.1", port: Nginx::STATIC_PORT, nginx: true),

  rails_w6: BenchTarget.new(
    dir: "ruby/railshost",
    cmd: "bundle exec puma -w %{default_workers} -p %{port} -e production --preload"),

  rails_puma_nginx: BenchTarget.new(
    dir: "ruby/railshost",
    cmd: "bundle exec puma -w %{default_workers} --preload -e production -b unix:#{Nginx::SOCK_PATH}",
    nginx: true,
    port: Nginx::SOCK_PROXY_PORT),

  hanami: BenchTarget.new(
    dir: "ruby/hanamihost",
    cmd: "bundle exec puma -w %{default_workers} -p %{port} -e production --preload"),

  hanami_puma_nginx: BenchTarget.new(
    dir: "ruby/hanamihost",
    cmd: "bundle exec puma -w %{default_workers} --preload -e production -b unix:#{Nginx::SOCK_PATH}",
    nginx: true,
    port: Nginx::SOCK_PROXY_PORT),

  phoenix: BenchTarget.new(
    dir: "elixir/phoenixhost",
    cmd: "mix phx.server",
    env: {"MIX_ENV" => "prod", "PORT" => "%{port}"}),

  phoenix_nginx: BenchTarget.new(
    dir: "elixir/phoenixhost",
    cmd: "mix phx.server",
    env: {"MIX_ENV" => "prod", "PORT" => Nginx::TCP_TARGET_PORT.to_s},
    nginx: true,
    port: Nginx::TCP_PROXY_PORT),

  amber: BenchTarget.new(
    dir: "crystal/amberhost",
    cmd: "bin/amberhost_prod",
    env: {"AMBER_ENV" => "production", "PORT" => "%{port}"}),

  amber_nginx: BenchTarget.new(
    dir: "crystal/amberhost",
    cmd: "bin/amberhost_prod",
    nginx: true,
    port: Nginx::TCP_PROXY_PORT,
    env: {"AMBER_ENV" => "production", "PORT" => Nginx::TCP_TARGET_PORT.to_s})
}

def with_dependencies(spec)
  server_pid = nil
  nginx_pid = nil

  nginx_pid = Nginx.start() if spec.nginx?

  if spec.should_start_server?
    server_pid = ServerManager.start(spec)
    puts "Server started at #{server_pid}"
  else
    puts "Server is expected to be already running at #{spec.endpoint}"
  end

  unless ServerManager.started_after_waiting?(spec)
    raise "Failed to get warmup response from server"
  end

  yield
ensure
  ServerManager.shutdown(server_pid) unless server_pid.nil?
  Nginx.shutdown(nginx_pid) unless nginx_pid.nil?
end

tests.each do |name, spec|
  puts "\n---------- #{name} ----------\n\n"

  with_dependencies(spec) do
    platform = Net::HTTP.get(spec.endpoint + "/platform")
    puts "Platform is \e[36m#{platform}\e[0m"

    result_file = "results/#{name}_bench_results.json"
    wrk_log_file = File.open("results/log/#{name}_wrk_output.log", "w+")
    cmd = "wrk -c #{BenchEnv.connections} -d #{BenchEnv.duration} -s bench.lua #{spec.endpoint}"

    puts "$ \e[33m#{cmd}\e[0m"
    Kernel.system({"WRK_JSON_OUT" => result_file, "WRK_JSON_DESC" => platform}, cmd, out: wrk_log_file)
  end

  puts "Done"
end
