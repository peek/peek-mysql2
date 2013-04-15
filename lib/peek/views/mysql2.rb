require 'mysql2'
require 'atomic'

# Instrument SQL time
class Mysql2::Client
  class << self
    attr_accessor :query_time, :query_count
  end
  self.query_count = Atomic.new(0)
  self.query_time = Atomic.new(0)

  def query_with_timing(*args)
    start = Time.now
    query_without_timing(*args)
  ensure
    duration = (Time.now - start)
    Mysql2::Client.query_time.update { |value| value + duration }
    Mysql2::Client.query_count.update { |value| value + 1 }
  end
  alias_method_chain :query, :timing
end

begin
  require "active_record"

  class ActiveRecord::Base
    class << self
      attr_accessor :obj_count, :obj_types, :obj_types_enabled
    end

    self.obj_count = 0
    self.obj_types = Hash.new(0)
    self.obj_types_enabled = false

    def initialize_with_stats *attributes
      initialize_without_stats *attributes
    ensure
      _update_object_stats
    end

    def init_with_with_stats coder
      init_with_without_stats coder
    ensure
      _update_object_stats
    end

    def initialize_dup_with_stats other
      intialize_dup_without_stats other
    ensure
      _update_object_stats
    end

    alias_method_chain :initialize, :stats
    alias_method_chain :init_with, :stats
    alias_method_chain :initialize_dup, :stats

    protected
    def _update_object_stats
      ActiveRecord::Base.obj_count += 1

      if ActiveRecord::Base.obj_types_enabled
        ActiveRecord::Base.obj_types[ self.class.name ] += 1
      end
    end
  end
rescue LoadError
  # oh well
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

      def context
        Hash.new.tap do |ctx|
          if track_activerecord?
            ctx[:activerecord] = Hash.new.tap do |ar|
              ar[:object_count] = ActiveRecord::Base.obj_count
              ar[:object_types] = ActiveRecord::Base.obj_types
            end
          end
        end
      end

      private

      def track_activerecord?
        defined?(ActiveRecord::Base) && ActiveRecord::Base.respond_to?(:obj_count)
      end

      def setup_subscribers
        # Reset each counter when a new request starts
        before_request do
          ::Mysql2::Client.query_time.value = 0
          ::Mysql2::Client.query_count.value = 0

          if track_activerecord?
            ::ActiveRecord::Base.tap { |ar| ar.obj_count = 0 }
          end
        end
      end
    end
  end
end
