require 'time'
require 'date'
require 'ostruct'

module Lstash

  class Query

    class FormatError < StandardError; end
    class QueryMissing < StandardError; end

    LOGSTASH_PREFIX = 'cloudfront_sessions-'.freeze
    WILDCARD_QUERY  = '*'.freeze

    attr_accessor :from, :to

    def initialize(query_string = nil, arguments = {})
      @query_string = query_string

      @anchor = time_parse(arguments[:anchor], 'today')
      @from   = time_parse(arguments[:from],   'today')
      @to     = time_parse(arguments[:to],     'now')

      @to = Time.now if @to > Time.now # prevent accessing non-existing times / indices
    end

    def index_name(date)
      "#{LOGSTASH_PREFIX}#{date.strftime('%Y%m%d')}"
    end

    def search(from, size)
      {
        sort:   sort_order,
        _source: %w(clientip verb), #%w(message),
        query:  filter,
        from:   from,
        size:   size
      }
    end

    def filter
      {
        bool: {
          must:  es_query,
          filter: es_filter
        }
      }
    end

    def each_period(step, &block)
      # iterate over the whole range in blocks of the specified period
      time_iterate(@from.utc, @to.utc - 1, step) do |start_at|
        yield index_name(start_at.to_date),
              Query.new(@query_string,
                        anchor: @anchor,
                        from:   start_at,
                        to:     start_at + step)
      end
    end

    private

    def time_iterate(start_time, end_time, step, &block)
      begin
        yield(start_time)
      end while (start_time += step) < end_time
    end

    def time_parse(time_or_string, default)
      return time_or_string if time_or_string.is_a? Time
      time_string = time_or_string.strip rescue nil
      time_string ||= default
      case time_string
      when 'firstday'
        midnight_at_beginning_of_month
      when 'now'
        Time.now
      when 'today'
        midnight_today
      when 'yesterday'
        midnight_yesterday
      else
        Time.parse(time_string)
      end
    rescue ArgumentError
      raise FormatError, "Invalid time format: #{time_string}"
    end

    def query_string
      q = @query_string.dup.strip rescue ''
      q = WILDCARD_QUERY if q.empty?
      q
    end

    def sort_order
      # return results in order of ascending timestamp
      [ { timestamp: { order: 'asc' } } ]
    end

    def es_query
      [
        {
          query_string: {
            query: query_string
          }
        }
      ]
    end

    def es_filter
      {
        bool: {
          must: [
            range: {
              'timestamp' => {
                gte: to_msec(from),
                lt:  to_msec(to)
              }
            },
            # fquery: {
            #   query: {
            #     query_string: {
            #       query: query_string
            #     }
            #   }
            # }
          ],
          # must_not: [
          #   fquery: {
          #     query: {
          #       query_string: {
          #         query: query_string
          #       }
          #     }
          #   }
          # ],
          # should: [
          #   fquery: {
          #     query: {
          #       query_string: {
          #         query: query_string
          #       }
          #     }
          #   }
          # ]
        }
      }
    end

    # Return the date of the first day of date's month
    def midnight_at_beginning_of_month
      Date.new(anchor_time.year, anchor_time.month, 1).to_time
    end

    def midnight_today
      Date.today.to_time
    end

    def midnight_yesterday
      (Date.today-1).to_time
    end

    def anchor_time
      @anchor
    end

    def to_msec(time)
      time.to_i * 1000
    end

  end

end
