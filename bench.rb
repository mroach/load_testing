#!/usr/bin/env ruby

require "net/http"

SYSTEM_CPUS = `sysctl -n hw.ncpu`.to_i
DEFAULT_WORKERS = [(SYSTEM_CPUS * 0.8).floor, 3].max
PORT = 7000

tests = {
  rails_w2: {
    dir: "ruby/railshost",
    env: {},
    cmd: "bundle exec puma -w 2 -p #{PORT} -e production --preload"
  },
  rails_w4: {
    dir: "ruby/railshost",
    env: {},
    cmd: "bundle exec puma -w 4 -p #{PORT} -e production --preload"
  },
  rails_w6: {
    dir: "ruby/railshost",
    env: {},
    cmd: "bundle exec puma -w 6 -p #{PORT} -e production --preload"
  },
  hanami: {
    dir: "ruby/hanamihost",
    env: {},
    cmd: "bundle exec puma -w #{DEFAULT_WORKERS} -p #{PORT} -e production --preload"
  },
  phoenix: {
    dir: "elixir/phoenixhost",
    env: {"MIX_ENV" => "prod", "PORT" => PORT.to_s},
    cmd: "mix phx.server"
  },
  amber: {
    dir: "crystal/amberhost",
    env: {"AMBER_ENV" => "production", "PORT" => PORT.to_s},
    cmd: "bin/amberhost_prod"
  }
}

def alive?
  uri = URI("http://127.0.0.1:#{PORT}/warmup")
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
  dir, env, cmd = spec[:dir], spec[:env], spec[:cmd]
  env_desc = env.map { |k,v| "#{k}=#{v}" }.join(" ")
  log_file = File.open("results/log/#{name}_server_output.log", "w+")

  puts "Starting #{name} server: #{dir}> #{env_desc} #{cmd}"
  Dir.chdir(dir) do
    return Process.spawn(env, cmd, out: log_file)
  end
end

tests.each do |name, spec|
  puts "\n---------- #{name} ----------\n\n"
  pid = start_server(name, spec)

  unless started_after_waiting?(limit: 20)
    STDERR.puts "Failed to get warmup response from #{name} server"
    next
  end

  puts "Server running at #{pid}"

  platform = Net::HTTP.get(URI("http://127.0.0.1:#{PORT}/platform"))
  puts "Platform is #{platform}"

  result_file = "results/#{name}_bench_results.json"

  Kernel.system(
    {"WRK_JSON_OUT" => result_file, "WRK_JSON_DESC" => platform},
    "wrk -c10 -d3s -s bench.lua http://127.0.0.1:#{PORT}"
  )

  puts "Shutting down server #{pid}"
  Process.kill("HUP", pid)
  puts "Waiting for #{name} server (#{pid}) to shutdown..."
  Process.wait(pid)
  puts "Done"
end
