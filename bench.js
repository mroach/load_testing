import { check, fail } from "k6";
import http from "k6/http";

export let options = {
  hosts: {
    localhost: "127.0.0.1"
  },
  vus: 10,
  duration: "10s"
}

export function setup() {
  let config = {
    scheme: __ENV.SCHEME || "http",
    host: __ENV.HOST || "localhost",
    port: __ENV.PORT || fail("Need to specify HTTP port")
  }
  config.endpoint = `${config.scheme}://${config.host}:${config.port}`

  // Hit the warmup endpoint to give the app a chance to get running. It should
  // respond with a simple JSON object: { "status": "running" }
  let res = http.get(`${config.endpoint}/warmup`)
  if (res.json().status != "running") {
    fail("Invalid warmup response: " + res.body)
  }

  return {config: config}
}

export default function(data) {
  let url = `${data.config.endpoint}/login`;
  let payload = JSON.stringify({ user: "admin", pass: "letmein" });
  let params = { headers: { "Content-Type": "application/json" } }

  let res = http.post(url, payload, params);

  check(res, {
    "is status 200": (r) => r.status === 200,
    "rt time is ok": (r) => r.timings.duration < 50
  });
}
