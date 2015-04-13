# Transparent class representing a redis hash
# See UserQueue for documentation
module TimedQueue
	class RedisHash
		def initialize(redis_id)
			@redis_id = redis_id
		end

		# Set value at a certain key
		# Returns boolean indicating if key is a new one
		# HSET O(1)
		def set(key, el)
			$redis.hset(@redis_id, key, el)
		end

		# Get value correspoding to a certain key
		# HGET O(1)
		def get(key)
			$redis.hget(@redis_id, key)
		end

		# Does the hash contain a certain key?
		# HGET O(1)
		def include?(key)
			not get(key).nil?
		end

		# Delete at the specified key
		# Returns boolean indicating success
		# HDEL O(1) (for removing 1 field)
		def delete(key)
			$redis.hdel(@redis_id, key) > 0
		end

		# Decrement by 1 the value of a given key
		# Returns new value
		# HINCRBY O(1)
		def decrement(key)
			$redis.hincrby(@redis_id, key, -1)
		end
	end
end
