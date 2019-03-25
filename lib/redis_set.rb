require "redis"

class RedisSet
	attr_reader :name

	VERSION = "0.0.4"

	class InvalidNameException < StandardError; end;
	class InvalidRedisConfigException < StandardError; end;

	def initialize(name, redis_or_options = {}, more_options = {})
		name = name.to_s if name.kind_of? Symbol

		raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
		@name = name
		@redis = if redis_or_options.kind_of?(Redis)
			         redis_or_options
			       elsif redis_or_options.kind_of? Hash
				       ::Redis.new redis_or_options
			       elsif defined?(ActiveSupport::Cache::RedisStore) && redis_or_options.kind_of?(ActiveSupport::Cache::RedisStore)
				       @pooled = redis_or_options.data.kind_of?(ConnectionPool)
				       redis_or_options.data
			       elsif defined?(ConnectionPool) && redis_or_options.kind_of?(ConnectionPool)
				       @pooled = true
				       redis_or_options
			       else
				       raise InvalidRedisConfigException.new
		         end

		if more_options.kind_of?(Hash) && more_options[:expire]
			@redis.expire more_options[:expire]
		end
	end

	def add *values
		values = [values].flatten
		with{|redis| redis.sadd name, values} if values.size > 0
	end

	alias push add

	def add_with_count value
		block_on_atomic_attempt { attempt_atomic_add_read_count value }
	end

	alias push_with_count add_with_count

	def remove *values
		values = [values].flatten
		with{|redis|redis.srem name, values} if values.size > 0
	end

	def pop(amount = 1)
		with{|redis| redis.spop name, amount}
	end

	def include? value
		with{|redis| redis.sismember(name, value)}
	end

	def size
		with{|redis| redis.scard name}
	end

	alias count size

	def all
		with{|redis| redis.smembers name}
	end

	def intersection *sets
		sets = [sets].flatten
		sets = sets.map do |s|
			if s.kind_of?(self.class)
				s.name
			else
				s
			end
		end

		with{|redis| redis.sinter *sets }
	end

	def scan cursor = 0, amount = 10, match = "*"
		with{|redis| redis.sscan name, cursor, :count => amount, :match => match}
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
		with{|redis| redis.del name}
		[]
	end

	alias flush clear

	def expire seconds
		with{|redis| redis.expire name, seconds.to_i}
	end

	private

	def attempt_atomic_add_read_count value
		attempt_atomic_write_read lambda { add value }, lambda { |multi, read_result| multi.scard name }
	end

	def block_on_atomic_attempt
		begin
			success, result = yield
			#puts "success is #{success} and result is #{result}"
		end while !success && result
		result.value
	end

	def attempt_atomic_write_read write_op, read_op
		success, write_result, read_result = false, nil, nil

		with do |redis|
			success = redis.watch(name) do
				write_result = write_op.call
				#if write_result
				redis.multi do |multi|
					read_result = read_op.call multi, write_result
				end
				#end
			end
		end

		[success, read_result]
	end

	def with(&block)
		if pooled?
			@redis.with(&block)
		else
			block.call(@redis)
		end
	end

	def pooled?
		!!@pooled
	end
end
