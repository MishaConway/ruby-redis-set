require "redis"

class Redis
  class Set
    attr_reader :name

    VERSION = "0.0.2"

    class InvalidNameException < StandardError; end;
    class InvalidRedisConfigException < StandardError; end;

    def initialize(name, redis_or_options = {})
      name = name.to_s if name.kind_of? Symbol
      
      raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
      @name  = name
      @redis = if redis_or_options.kind_of? Redis
                 redis_or_options
               elsif redis_or_options.kind_of? Hash
                 Redis.new redis_or_options
               else
                 raise InvalidRedisConfigException.new
               end
    end

    def add value
      @redis.sadd name, value
    end

    alias push add

    def add_multi *values
      if values.size > 0
        values = values.first if 1 == values.size && values.first.kind_of?(Array)
        @redis.sadd name, values
      end
    end

    alias push_multi add_multi

    def add_with_count value
      block_on_atomic_attempt{ attempt_atomic_add_read_count value }
    end

    alias push_with_count add_with_count

    def remove value
      @redis.srem name, value
    end

    def remove_multi *values
      if values.size > 0
        values = values.first if 1 == values.size && values.first.kind_of?(Array)
        @redis.srem name, values
      end
    end

    def pop
      @redis.pop name, 1
    end

    def pop_multi amount
      @redis.pop name, amount
    end

    def include? value
      @redis.sismember(name, value)
    end

    def size
      @redis.scard name
    end

    alias count size

    def all
      @redis.smembers name
    end

    def scan cursor = 0, amount=10, match = "*"
      @redis.sscan name, cursor, :count => amount, :match => match
    end

    def enumerator(slice_size = 10)
      cursor = 0
      Enumerator.new do |yielder|
        loop do
          cursor, items = scan cursor, slice_size
          items.each do |item|
            yielder << item
          end
          raise StopIteration if cursor.to_i.zero?
        end
      end
    end

    def clear
      @redis.del name
      []
    end

    alias flush clear

    def expire seconds
      @redis.expire name, seconds
    end

private

    def attempt_atomic_add_read_count value
      attempt_atomic_write_read lambda{ add value }, lambda{ |multi, read_result| multi.scard name}
    end

    def block_on_atomic_attempt
      begin
        success, result = yield
        #puts "success is #{success} and result is #{result}"
      end while !success && result
      result.value
    end

    def attempt_atomic_write_read write_op, read_op

      write_result, read_result  = nil, nil
      success = @redis.watch(name) do
        write_result = write_op.call
        #if write_result
          @redis.multi do |multi|
            read_result = read_op.call multi, write_result
          end
        #end
      end

      [success, read_result]
    end


  end
end
