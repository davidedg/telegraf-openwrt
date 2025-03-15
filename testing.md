Random notes on testing

The flow will be:
Collectd -> Telegraf -> InfluxDB prometheus-compatible enpoint


- create a [Grafana Cloud](https://grafana.com/auth/sign-up?refCode=gr8UNV7MqjYkQUh) account
- create a stack
- create an access policy (metrics:write should be enough)
- Under your stack, select InfluxDB connectivity and write down: Endpoint Prometheus username - no need to generate a token (see step above)
- configure /etc/telegraf.conf by customising /etc/telegraf.conf.collectdsock2influxgrcloud with the values above
- start telegraf in foreground, e.g. `/usr/bin/telegraf --config /etc/telegraf.conf --unprotected --debug`
- install luci-app-statistics + collectd - refer to [this article](https://blog.christophersmart.com/2019/09/09/monitoring-openwrt-with-collectd-influxdb-and-grafana/): 
- install/configure collectd plugins
- configure the Network plugin (in the Output plugins section) pointing to 127.0.0.1:25826 (section Server interfaces)
- Save and apply

Collectd should start collecting and then forwarding metrics to the InfluxDB listener of Telegraf, which in turn will send to Grafana Cloud.

I tested this and it works. If anyone cares to build a decent dashboard, please let me know, I am not bothered to do it...
