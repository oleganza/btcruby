module BTC
  class Diagnostics

    # Instance unique for this thread.
    def self.current
      Thread.current[:BTCRubyDiagnosticsCurrentInstance] ||= self.new
    end

    attr_accessor :last_message
    attr_accessor :last_info
    attr_accessor :last_item

    # Begins recording of series of messages and returns all recorded events.
    # If there is no record block on any level, messages are not accumulated,
    # but only last_message is updated.
    # Returns a list of all recorded messages.
    def record(&block)
      recording_groups << Array.new
      last_group = nil
      begin
        yield
      ensure
        last_group = recording_groups.pop
      end
      last_group
    end

    # Prints out every message to a stream.
    # Default stream is $stderr.
    # You can nest these calls with different streams and each of them will
    # receive logged messages.
    def trace(stream = $stderr, &block)
      @trace_streams << stream
      # Use uniq list internally so when nested we don't write the same thing twice.
      @uniq_trace_streams = @trace_streams.uniq
      begin
        yield
      ensure
        @trace_streams.pop
        @uniq_trace_streams = @trace_streams.uniq
      end
      self
    end

    # Adds a diagnostic message.
    # Use it to record warnings and reasons for errors.
    # Do not use when the input is nil - code that have produced that nil
    # could have already recorded a specific message for that.
    def add_message(message, info: nil)
      self.last_message = message
      self.last_info = info
      self.last_item = Item.new(message, info)

      # add to each recording group
      recording_groups.each do |group|
        group << Item.new(message, info)
      end

      @uniq_trace_streams.each do |stream|
        stream.puts message
      end

      return self
    end

    private

    # Array of arrays
    attr_accessor :recording_groups

    def initialize
      @trace_streams = []
      @uniq_trace_streams = []
      @recording_groups = []
    end

    class Item
      attr_accessor :message
      attr_accessor :info

      def initialize(message, info)
        @message = message
        @info = info
      end

      def to_s
        message.to_s
      end
    end

  end
end