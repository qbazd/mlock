Mlock 
=====

Multiple resource locking (shared and exclusive) library for Redis.

Description
-----------

Library is designed to work in multiprocess/multihost environment to lock many resources for shared and exclusive use at once for processing.
One resource can be locked by many processes for reading, but only one process can lock resource for writting while no other process reads.
One process can hold only one set of locks at a time.

Config
------

	# setup redis connection
    MLock.redis = Redis.new #separate connection per process

	# set domain
	MLock.domain = "my_domain" # namespace for locks

	#set owner
	#if you require other owner identification string than: "#{Socket.gethostname}-#{Process.pid}"
	MLock.lock_owner = lambda{ } #dynamic, for example when forking 
	MLock.lock_owner = "owner" # or static

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

    rlocks, wlocks = MLock.get_locks
	MLock.can_read?(resource) #true / false / nil
	MLock.writing!(resource) (raise if has no lock) # postpones the lock

	# if resource written or locked for write in meantime, retry op
	x = MLock.try_read(resource, time_out: 5, retries: 5){ read operation } 

	# implement timeout of locks
	MLock.postpone_lock! #thread update lock time x ???
