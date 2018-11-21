init = function(args)
  wrk.headers["Content-Type"] = "application/json"
  wrk.headers["Accept"] = "application/json"

  local r = {}

  local login_payload = [[
    { "user": "admin", "pass": "letmein" }
  ]]
  r[1] = wrk.format("POST", "/login", nil, login_payload)

  req = table.concat(r)
end

request = function()
  return req
end

done = function(summary, latency, requests)
  local error_count = summary.errors.connect + summary.errors.read + summary.errors.write + summary.errors.status + summary.errors.timeout

  json_out_path = os.getenv("WRK_JSON_OUT")
  json_desc = os.getenv("WRK_JSON_DESC")
  if json_out_path then
    io.write("\nJSON Output to " .. json_out_path .. "\n")
    file = io.open(json_out_path, "w")
    io.output(file)
  end

  io.write("{\n")
  io.write(string.format("\t\"description\": \"%s\",\n", json_desc))
  io.write(string.format("\t\"requests\": %d,\n", summary.requests))
  io.write(string.format("\t\"requests_per_sec\": %0.2f,\n", (summary.requests/summary.duration)*1e6))
  io.write(string.format("\t\"duration_in_microseconds\": %0.2f,\n", summary.duration))
  io.write(string.format("\t\"total_errors\": %d,\n", error_count))
  io.write(string.format("\t\"bytes\": %d,\n", summary.bytes))
  io.write(string.format("\t\"bytes_transfer_per_sec\": %0.2f,\n", (summary.bytes/summary.duration)*1e6))
  io.write(string.format("\t\"latency_min\": %0.2f,\n", latency.min))
  io.write(string.format("\t\"latency_max\": %0.2f,\n", latency.max))
  io.write(string.format("\t\"latency_mean\": %0.2f,\n", latency.mean))
  io.write(string.format("\t\"latency_stdev\": %0.2f,\n", latency.stdev))

  io.write("\t\"latency_distribution\": [\n")
  for _, p in pairs({ 50, 75, 90, 99, 99.9, 99.99, 99.999, 100 }) do
     io.write("\t\t{\n")
     n = latency:percentile(p)
     io.write(string.format("\t\t\t\"percentile\": %g,\n\t\t\t\"latency_in_microseconds\": %d\n", p, n))
     if p == 100 then
         io.write("\t\t}\n")
     else
         io.write("\t\t},\n")
     end
  end
  io.write("\t]\n}\n")
end
