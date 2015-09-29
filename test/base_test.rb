require_relative 'helper'

setup do 
  Mlock.domain = "test"
  Mlock.owner = nil
end

test '#owner' do

  Mlock.owner = nil
  assert_equal Mlock.owner,"#{Socket.gethostname}-#{Process.pid}"

  Mlock.owner = lambda{ "x" }
  assert_equal Mlock.owner, "x"
end

test 'cannot set same lock shared and exclusive' do
    exception = assert_raise(MlockInternalError) do 
    Mlock.set(["a","c"], ["a","d"])
  end

  assert_equal "same locks w & r", exception.message
end

test 'cannot release not set lock' do
  exception = assert_raise(MlockInternalError) do 
    Mlock.release!
  end

  assert_equal "no locks to release", exception.message
end

test 'cannot set locks twice' do
  Mlock.set(["a"], ["b"])

  exception = assert_raise(MlockInternalError) do 
    Mlock.set(["c"], ["d"])
  end

  assert_equal "owner has already a lock!", exception.message
end


test 'purge locks not purges all' do 

  Mlock.redis.set("aaa", "bbb")

  Mlock.set(["a"], ["d"])
  Mlock.purge_locks
  
  assert_raise(MlockInternalError) do 
    Mlock.release!
  end

  assert_equal Mlock.redis.get("aaa"), "bbb"
  Mlock.redis.del("aaa")
end

test 'zero timeout works' do 
  Mlock.set(["a"], ["d"], 0)
end

test 'lock timeout works' do 

  Mlock.owner = "owner1"
  Mlock.set(["a"], ["d"])

  Mlock.owner = "owner2"

  assert_raise(MlockTimeout) do 
    Mlock.set(["a"], ["d"], 0.5)
  end

end


test 'lock read by 2 owners' do 

  Mlock.owner = "owner1"
  Mlock.set(["d"])

  Mlock.owner = "owner2"
  Mlock.set(["d"], [], 0)

end


test 'lock write by 2 owners not work' do 

  Mlock.owner = "owner1"
  Mlock.set([],["a"])

  Mlock.owner = "owner2"
  assert_raise(MlockTimeout) do 
    Mlock.set([],["a"], 0)
  end

end

test 'unlock works' do 

  Mlock.set(["a"], [])
  Mlock.release!
  Mlock.set(["a"], [])

end
