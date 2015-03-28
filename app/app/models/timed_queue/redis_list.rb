# Transparent class representing a redis LinkedList
# See UserQueue for documentation
module TimedQueue
	class RedisList
		def initialize(redis_id)
			@redis_id = redis_id
		end

		# Insert value at head
		# Return length of list after operations
		# LPUSH O(1)
		def push(el)
			$redis.lpush(@redis_id, el)
		end

		# Remove value from tail
		# RPOP O(1)
		def pop
			$redis.rpop(@redis_id)
		end

		# Return length of list
		# LLEN O(1)
		def length
			$redis.llen(@redis_id)
		end

		# Remove an element by value
		# Removes at most 1
		# Looks from head to tail: an arbitrary choice but it seems most likely
		# a user would remove themselves from the queue whilst still relatively
		# close to the end of the queue
		# Returns a boolean indiciating success
		# LREM O(n)
		def remove(el)
			$redis.lrem(@redis_id, 1, el) > 0
		end

		# Return all values in the list
		# LRANGE O(n)
		def values
			$redis.lrange(@redis_id, 0, -1)
		end

		# Return all values after the given index in the list
		# where after means closer to head
		# LRANGE O(n) in n
		def values_after(index)
			$redis.lrange(@redis_id, 0, index-1)
		end

		# Get the element at position i
		# LINDEX O(m) where m is the number of elements to traverse to get to i
		def get(index)
			$redis.lindex(@redis_id, index)
		end
	end
end
