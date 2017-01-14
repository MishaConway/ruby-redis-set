require "redis"

class Redis
  class Set
    attr_reader :name

    VERSION = "0.0.1"

    class InvalidNameException < StandardError; end;
    class InvalidRedisConfigException < StandardError; end;

    def initialize(name, redis_or_options = {})
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

    def add_multi *values
      if values.size > 0
        values = values.first if 1 == values.size && values.first.kind_of?(Array)
        @redis.sadd name, values
      end
    end

    def remove value
      @redis.srem name, value
    end

    def remove_multi *values
      if values.size > 0
        values = values.first if 1 == values.size && values.first.kind_of?(Array)
        @redis.srem name, values
      end
    end

    def include? value
      @redis.sismember(name, value)
    end

    def size
      @redis.scard name
    end

    def all
      @redis.smembers name
    end

    def clear
      @redis.del name
      []
    end

    def expire seconds
      @redis.expire name, seconds
    end
  end
end
