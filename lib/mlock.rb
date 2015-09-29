# encoding: UTF-8

require 'socket' # for hostname
require 'nido'
require 'redis'

class MlockTimeout < StandardError ; end
class MlockInternalError < StandardError ; end

class Mlock

	Default_timeout = 5 

	def self.redis=(redis)
		@redis = redis
	end

	def self.redis
		@redis 
	end

	def self.domain= domain
		@domain = domain
	end

	def self.domain
		raise "domain not set" if @domain.nil?
		@domain 
	end

	def self.owner= owner
		@owner = owner
	end

	def self.owner 
		if @owner.nil?
			"#{Socket.gethostname}-#{Process.pid}"
		elsif @owner.kind_of?(Proc)
			@owner.call
		else
			@owner
		end
	end

	def self.retry_sleep=(retry_sleep)
		@retry_sleep = retry_sleep
	end

	def self.retry_sleep
		self.instance_variable_defined?("@retry_sleep") ? @retry_sleep : 0.5
	end

    def self.key
      Nido.new(self.domain)["mlock"]
    end

	def self.owner_locks_key(owner = Mlock.owner)
		self.key["owners"][owner]
	end

	def self.rlock_key(name)
		self.key[name]['r']
	end

	def self.wlock_key(name)
		self.key[name]['w']
	end

	def self.set(rlocks, wlocks = [], timeout = Mlock::Default_timeout)

		wlocks = [] if wlocks.nil?
		rlocks = [] if rlocks.nil?

		raise MlockInternalError.new("same locks w & r") unless (rlocks & wlocks).empty?

		x = Time.now
		first_try = true
		loop do

			raise MlockTimeout.new if (!first_try & (x + timeout < Time.now))

			first_try = false

			watch_keys = (rlocks | wlocks).map{|rl| [wlock_key(rl),rlock_key(rl)] }.flatten

			#watch all possible locks keys
			Mlock.redis.watch( watch_keys | [self.owner_locks_key] )
			
			if Mlock.redis.exists(self.owner_locks_key)
				Mlock.redis.unwatch
				raise MlockInternalError.new("owner has already a lock!")
			end

			if Mlock.redis.exists(rlocks.map{|k| wlock_key(k) } | wlocks.map{|k| [rlock_key(k), wlock_key(k)] }.flatten )
				Mlock.redis.unwatch
				#puts "another try"
				sleep(self.retry_sleep) if timeout > 0
				next
			end

			out = Mlock.redis.multi{
				wlocks.each{|k| Mlock.redis.set(wlock_key(k), self.owner) }
				rlocks.each{|k| Mlock.redis.sadd(rlock_key(k), self.owner) }
				Mlock.redis.sadd(self.owner_locks_key,  wlocks.map{|k| wlock_key(k)} | rlocks.map{|k| rlock_key(k)})
			}

			if out
				#puts "locks set!"
				return true
			else
				#puts "watch modified :D rerun"
			end
		end
	end

	def self.release!

		keys = Mlock.redis.smembers(self.owner_locks_key)
		raise MlockInternalError.new("no locks to release") if keys.empty?
		Mlock.redis.pipelined{
			keys.each{|k|
				case k
				when /:mlock:.*:w/
					Mlock.redis.del(k)
				when /:mlock:.*:r/
					Mlock.redis.srem(k, @owner)
				else 
					raise MlockInternalError.new("wrog key not read or write #{k}!")
				end
			}
			Mlock.redis.del(owner_locks_key)
		}

	end

	def self.lock(wlocks, rlocks, timeout = Mlock::Default_timeout)
		raise "no block given" unless block_given?
		lock_multi_set(wlocks, rlocks, timeout)
		begin
			ret = yield
		ensure
			lock_multi_release
		end
		return ret
	end

	def self.try_read(resource, opts = {})
		raise "not working"
		begin
		# watch resource write key
			ret = yield
		# 
		ensure
			nil
		end
		return ret
	end

	def self.purge_locks(domain = self.domain)
		# upgrade to scan
		Mlock.redis.keys(Mlock.key["*"]).each{|k| Mlock.redis.del(k) }
	end

end

