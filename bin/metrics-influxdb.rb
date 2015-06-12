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
    timestamp = DateTime.strptime(@event['check']['executed'].to_s, '%s')

    metric_raw = @event['check']['output']
    metrics = metric_raw.split("\n")
      .map(&:split)
      .select { |(k, v, *_)| k != nil and v.length != 0 }
      .map { |(k, v, *_)| [ k.gsub(client_name + '.', ''), v.to_f ] }

    point = InfluxDB::Point.new measurement: metric_name,
                                tags: { host: client_name },
                                fields: Hash[metrics],
                                datetime: timestamp

    influxdb_client.write points: [point],
                          database: influxdb_db,
                          retention_policy: influxdb_rp
  end
end
