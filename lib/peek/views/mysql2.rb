require 'mysql2'
require 'concurrent/atomics'

# Instrument SQL time
class Mysql2::Client
  class << self
    attr_accessor :query_time, :query_count
  end
  self.query_count = Concurrent::AtomicReference.new(0)
  self.query_time = Concurrent::AtomicReference.new(0)

  if defined? Rails::VERSION::MAJOR && Rails::VERSION::MAJOR >= 5
    require 'peek-mysql2/timing'
    prepend ::Peek::Mysql2::Timing
  else
    def call_with_timing(*args, &block)
      start = Time.now
      call_without_timing(*args, &block)
    ensure
      duration = (Time.now - start)
      Mysql2::Client.query_time.update { |value| value + duration }
      Mysql2::Client.query_count.update { |value| value + 1 }
    end
    alias_method_chain :call, :timing
  end
end

module Peek
  module Views
    class Mysql2 < View
      def duration
        ::Mysql2::Client.query_time.value
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
        ::Mysql2::Client.query_count.value
      end

      def results
        { :duration => formatted_duration, :calls => calls }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          ::Mysql2::Client.query_time.value = 0
          ::Mysql2::Client.query_count.value = 0
        end
      end
    end
  end
end
