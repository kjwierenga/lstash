require 'logger'
require 'date'
require 'hashie'
require 'json'

class NullLogger < Logger
  def initialize(*args); end
  def add(*args, &block); end
end

module Lstash

  class Client

    class Response < Hashie::Mash
      disable_warnings
    end

    class ConnectionError < StandardError; end

    PER_PAGE = 5000.freeze # best time, lowest resource usage
    DEFAULT_COUNT_STEP = 3600.freeze # 1 hour
    DEFAULT_GREP_STEP  = 120.freeze  # 2 minutes

    def initialize(es_client, options = {})
      raise ConnectionError, "No elasticsearch client specified" if es_client.nil?

      @es_client = es_client
      @logger    = options[:logger] || (options[:debug] ? debug_logger : NullLogger.new)
    end

    def count(query, step = DEFAULT_COUNT_STEP)
      @logger.debug "count from=#{query.from} to=#{query.to}"

      count = 0
      query.each_period(step) do |index, hour_query|
        count += count_messages(index, hour_query)
      end
      @logger.debug "total count=#{count}"
      count
    end

    def grep(query, step = DEFAULT_GREP_STEP)
      @logger.debug "grep from=#{query.from} to=#{query.to}"

      count = 0
      query.each_period(step) do |index, hour_query|
        grep_messages(index, hour_query) do |message|
          count += 1
          yield message if block_given?
        end
      end

      @logger.debug "total count=#{count}"
      count
    end

    private

    def count_messages(index, query)
      result = Response.new @es_client.send(:count,
        index: index,
        body:  query.filter
      )
      @logger.debug "count index=#{index} from=#{query.from} to=#{query.to} count=#{result['count']}"
      result['count']
    end

    def grep_messages(index, query)
      messages = nil
      scroll_params = {}
      offset = 0
      method = :search

      while (messages.nil? || messages.count > 0) do
        raw_result = @es_client.send(method, {
          index:  index,
          scroll: '5m',
          body:   :search == method ? query.search(offset, PER_PAGE) :nil,
        }.merge(scroll_params))
        result = Response.new raw_result

        messages = result.hits.hits

        offset += messages.count
        scroll_params = {scroll_id: result._scroll_id}

        messages.each do |h|
          next if h._source.nil?
          puts h._source
          yield h._source.message if block_given?
        end

        method = :scroll
      end
      @logger.debug "grep index=#{index} from=#{query.from} to=#{query.to} count=#{offset}"
      Response.new @es_client.clear_scroll(scroll_params)
    end

    def debug_logger
      logger = Logger.new(STDERR)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime} #{msg}\n"
      end
      logger
    end

  end

end
