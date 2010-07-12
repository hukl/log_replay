require 'time'
require 'uri/generic'
require 'ipaddr'


module LogReplay

  class Request

    attr_reader :time, :path, :params, :request_id, :client_ip, :location, :log_entry, :status

    METHOD    = /\[(GET|POST|PUT|DELETE)\]/
    TIME      = /\s(\d\d\d\d\-\d\d\-\d\d\s\d\d\:\d\d\:\d\d)\)/
    PARAMS    = /Parameters\:\s(.+)/
    LOCATION  = /Location\:\s.+\/([a-f0-9]+)\r\n/
    ERROR     = /.+Error\s\(/
    IPV4      = /\(for\s([0-9\.]+)\sat/
    RESPONSE  = /\s\|\s(\d\d\d)\s(.+)\s\[(.+)\]/


    def initialize options
      @log_entry  = options[:log_entry]
      @time       = Time.parse( options[:time] )
      @method     = options[:method]
      @client_ip  = options[:client_ip]
      @status     = options[:status]
      @message    = options[:message]
      @url        = options[:url]
      @path       = URI.parse( options[:url] ).path
      @request_id = options[:params].delete("id") rescue ""
      @params     = options[:params]
      @location   = options[:location]

      if @method == "PUT" && @params["upload[attachment]"]
        @params["upload[attachment]"] = File.open("file1.png")
      end

    end

    def self.each logfile_path, &block

      unless File.exist?(logfile_path)
        raise ArgumentError, "Logfile does not exist"
      end

      File.open( logfile_path, "r" ) do |file|
        file.each("\n\n") do |request|
          next unless options = parse_request( request )

          yield Request.new( options )
        end
      end

    end

    def self.each_with_timing logfile_path, &block
      previous_timestamp = nil

      each( logfile_path ) do |request|
        previous_timestamp ||= request.time

        time_to_sleep = request.time - previous_timestamp
        sleep time_to_sleep

        yield request

        previous_timestamp = request.time
      end
    end

    def self.parse_request request
      begin
       #puts request
       # puts

        request.gsub!(/\#\<File.+\>\}/, "\"fileupload\"}")

        request_params  = {}

        request_params[:log_entry]= request
        request_params[:client_ip]= request.match(IPV4)[1]
        request_params[:time]     = request.match(TIME)[1]
        request_params[:method]   = request.match(METHOD)[1]

        params_hash = eval( (request.match(PARAMS)[1] rescue "") )
        request_params[:params]   = resolve_params( params_hash )

        request_info = request.match(RESPONSE)
        request_params[:status]   = request_info[1]
        request_params[:message]  = request_info[2]
        request_params[:url]      = request_info[3]

        if ( request_params[:method] == "POST" ) && ( request =~ /Redirected/ )
          request_params[:location] = request.match(/Redirected\sto\s(.+)\n/)[1]
        end

        request_params
      rescue => exception
        puts exception
        nil
      end
    end

    def self.resolve_params params_hash
      params_hash ||= {}

      params_hash.inject({}) do |options, (key, value)|

        if value.is_a?(Hash)
          value.each do |k,v|
            options["#{key}[#{k}]"] = v
          end
        else
          options[key] = value
        end

        options
      end
    end

    def request_method
      @method
    end

  end
end
