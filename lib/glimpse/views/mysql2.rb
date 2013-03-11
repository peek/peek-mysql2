require 'mysql2'

# Instrument SQL time
class Mysql2::Client
  class << self
    attr_accessor :query_time, :query_count
  end
  self.query_count = 0
  self.query_time = 0

  def query_with_timing(*args)
    start = Time.now
    query_without_timing(*args)
  ensure
    Mysql2::Client.query_time += (Time.now - start)
    Mysql2::Client.query_count += 1
  end
  alias_method_chain :query, :timing
end

module Glimpse
  module Views
    class Mysql2 < View
      def duration
        ::Mysql2::Client.query_time
      end

      def formatted_duration
        ms = duration * 1000
        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end

      def calls
        ::Mysql2::Client.query_count
      end

      def results
        { :duration => formatted_duration, :calls => calls }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          ::Mysql2::Client.query_time = 0
          ::Mysql2::Client.query_count = 0
        end
      end
    end
  end
end
