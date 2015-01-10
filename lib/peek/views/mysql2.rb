require 'mysql2'
require 'atomic'

# Instrument SQL time
class Mysql2::Client
  class << self
    attr_accessor :query_time, :query_count, :query_list
  end
  self.query_count = Atomic.new(0)
  self.query_time = Atomic.new(0)
	self.query_list = Atomic.new('')

  def query_with_timing(*args)
    start = Time.now
    query_without_timing(*args)
  ensure
    duration = (Time.now - start)
    Mysql2::Client.query_time.update { |value| value + duration }
    Mysql2::Client.query_count.update { |value| value + 1 }
		Mysql2::Client.query_list.update { |value|
			ms = duration * 1000
			value + args.first + '(' + ms.to_s + ' ms)<br>'
		}
  end
  alias_method_chain :query, :timing
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

			def queries 
				::Mysql2::Client.query_list.value
			end

      def results
        { :duration => formatted_duration, :calls => calls, :queries => queries }
      end

      private

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          ::Mysql2::Client.query_time.value = 0
          ::Mysql2::Client.query_count.value = 0
					::Mysql2::Client.query_list.value = ''
        end
      end
    end
  end
end
