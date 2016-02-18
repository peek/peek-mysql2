module Peek
  module Mysql2
    module Timing
      def query(*args)
        start = Time.now
        super(*args)
      ensure
        duration = (Time.now - start)
        ::Mysql2::Client.query_time.update { |value| value + duration }
        ::Mysql2::Client.query_count.update { |value| value + 1 }
      end
    end
  end
end

