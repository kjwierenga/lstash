# external dependencies
require 'thor'
require 'uri'
require 'elasticsearch'

# local files we need
require 'lstash/query'
require 'lstash/client'

module Lstash

  TRANSPORT_REQUEST_TIMEOUT = 600.freeze # 10 minutes request timeout

  class CLI < Thor

    class_option :from,   :banner => 'start of time range', :aliases => '-f', :desc => "date/time, 'now', 'today', 'yesterday', or 'firstday'"
    class_option :to,     :banner => 'end of time range',   :aliases => '-t', :desc => "date/time, 'now', 'today', 'yesterday', or 'firstday'"
    class_option :anchor, :banner => 'anchor date/time',    :aliases => '-a', :desc => "used as reference date for firstday"
    class_option :es_url, :banner => 'Elasticsearch endpoint for Logstash', :aliases => '-e', :desc => "or ES_URL environment variable"
    class_option :debug,  :banner => 'debug log to stderr', :aliases => '-d', :type => :boolean

    long_desc <<-LONGDESC
      Grep log messages matching the QUERY from Logstash in ascending timestamp order
      and output to stdout. QUERY can use Apache Lucene query parser syntax.

      Example to grep HAProxy log messages from the beginning of this month upto now

        lstash grep 'program:haproxy' --from firstday --to now
    LONGDESC
    desc "grep QUERY", "grep log messages from Logstash"
    def grep(query_string)
      run_command(query_string) do |es_client, query|
        Lstash::Client.new(es_client, options).grep(query) do |message|
          puts message
        end
      end
    end

    long_desc <<-LONGDESC
      Count log messages matching the QUERY from Logstash and output this count to stdout.
      QUERY can use Apache Lucene query parser syntax.

      Example to count the number of HAProxy log messages in yesterdays month.

        lstash count 'program:haproxy' --from firstday --to today --anchor yesterday
    LONGDESC
    desc "count QUERY", "count number of log messages matching the QUERY"
    def count(query_string)
      run_command(query_string) do |es_client, query|
        count = Lstash::Client.new(es_client, options).count(query)
        puts count
      end
    end

    private

    def run_command(query_string)
      es_client = ::Elasticsearch::Client.new(
        url: options[:es_url] || ENV['ES_URL'] || 'localhost',
        log: !!ENV['DEBUG'],
        transport_options: { request: { timeout: TRANSPORT_REQUEST_TIMEOUT } }
      )
      query  = Lstash::Query.new(query_string, options)

      yield es_client, query

    rescue Exception => e
      options[:debug] ? raise(e) : raise(Thor::Error.new(e.message))
    end

    protected

    # Make sure we exit on failure with an error code
    def self.exit_on_failure?
      true
    end

  end

end
