#! /usr/bin/env ruby
#
#   metrics-influx.rb
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: influxdb
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright (C) 2015, Sensu Plugins
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require_relative '../lib/sensu-plugins-influxdb'
require 'sensu-handler'
require 'date'

#
# Sensu To Influxdb
#
class SensuToInfluxDB < Sensu::Handler
  def filter; end

  def handle
    influxdb_server = settings['influxdb']['server']
    influxdb_port   = settings['influxdb']['port']
    influxdb_user   = settings['influxdb']['username']
    influxdb_pass   = settings['influxdb']['password']
    influxdb_db     = settings['influxdb']['database']
    influxdb_rp     = settings['influxdb']['retention_policy']

    influxdb_client = InfluxDB::Client.new host: influxdb_server,
                                           port: influxdb_port,
                                           username: influxdb_user,
                                           password: influxdb_pass

    client_name = @event['client']['name']
    metric_name = @event['check']['name']

    metric_raw = @event['check']['output']
    metrics = metric_raw.split("\n")
      .map(&:split)
      .select { |(*x)| x.length == 3 }
      .map do |(k, v, time)|
        InfluxDB::Point.new measurement: k.gsub(client_name + '.', ''),
                            tags: { host: client_name, metric: metric_name },
                            fields: { value: v.to_f },
                            datetime: DateTime.strptime(time.to_s, '%s')
      end

    influxdb_client.write points: metrics,
                          database: influxdb_db,
                          retention_policy: influxdb_rp
  end
end
