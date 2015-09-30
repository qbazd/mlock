Mlock 
=====

Multiple resource locking (shared and exclusive) library for Redis.

Description
-----------

Library is designed to work in multiprocess/multihost environment to lock many resources for shared and exclusive use at once for processing.
One resource can be locked by many processes for reading, but only one process can lock resource for writting while no other process reads.
One process can hold only one set of locks at a time. 

- Very important notes:

Many resources are locked at the same time for simple deadlock avoidence.


Config
------

	# setup redis connection
    MLock.redis = Redis.new #separate connection per process

	# set domain
	MLock.domain = "my_domain" # namespace for locks

	#set owner
	#if you require other owner identification string than: "#{Socket.gethostname}-#{Process.pid}"
	MLock.lock_owner = lambda{ } #dynamic, for example to use when forking 
	MLock.lock_owner = "owner" # or static a'ka become somebody

Usage
-----

    MLock.set(["a"], ["b"])
    #locked operation
    MLock.release!

or 

	MLock.lock(["a"], ["b"]) do 
	# locked operation
	end


TODO:
-----

- read withot a read lock, if resource is locked for a write in meantime, retry read op. Just read if have a lock.

	x = MLock.try_read(resources, time_out: 5, retries: 5){ read operation } 

- get locks if you forgoten if or what is locked

	Mlock.doihavealock? # true/false
    rlocks, wlocks = MLock.current_locks

- sanity check of write lock for resources

	MLock.can_read?(resources) #true / false / nil
	MLock.writing!(resources) (raise if has no lock) # could also postpone the locks

- implement timeout of locks

	MLock.postpone_lock! #thread lock time x ???

- Benchmark lockrate

Redis hosting connection: 
local host, remote host ETH, remote host IPoIB

Does lock rate depend on the number of resources being locked: 
for reading 1,2,4,8,...,1024; for writting 1,2,4,8,...,1024

How does lock rate depend on how many processes operate in parallel:
1,2,4,8,...,1024
Do by redis.incr by all processes, and 

