require 'net/http'
require 'uri/http'
require 'json'
require 'date'

module InfluxDB
  class Point
    def initialize measurement: nil,
                   tags: { },
                   fields: { },
                   datetime: DateTime.now

      @measurement = measurement
      @tags = tags
      @fields = fields
      @datetime = datetime
    end

    def serialize
      destination =
        "#{@measurement},#{serialize_hash @tags}"

      fields = serialize_hash @fields
      timestamp = @datetime.strftime '%s%N'

      "#{destination} #{fields} #{timestamp}"
    end

    def serialize_hash hash
      hash.map do |(k, v)|
        "#{k}=#{v}"
      end.join(',')
    end
  end

  class Client
    default_host = 'localhost'
    default_port = 8086

    def initialize host: default_host,
                   port: default_port,
                   username: nil,
                   password: nil

      @host = host
      @port = port.to_i
      @username = username
      @password = password
    end

    def write points: [ ],
              database: nil,
              retention_policy: nil

      points =
        if points.is_a?(Array)
          then points
          else [ points ]
        end
      body = points.map(&:serialize).join "\n"

      query = { 'db' => database }
      if retention_policy
        query['rp'] = retention_policy
      end

      http_req path: '/write',
               method: 'POST',
               body: body,
               query: query
    end

    def http_req path: nil,
                 body: nil,
                 query: {},
                 method: 'GET'
      query_s = URI.encode_www_form(query)

      uri = URI::HTTP.build scheme: 'http',
                            host: @host,
                            port: @port,
                            path: path,
                            query: query_s

      req = Net::HTTPGenericRequest.new method,
                                        true,
                                        true,
                                        uri
      req.basic_auth @username, @password
      req.body = body

      http = Net::HTTP.new uri.host, uri.port
      response = http.request req
      if not [200, 204].include?(response.code.to_i)
        puts response.body
        raise "Invalid InfluxDB reponse code: #{response.code}!"
      end

      response
    end
  end
end

