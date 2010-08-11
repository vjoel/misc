require 'rbtree'

# Priority queue based on RBTree and the old ruby Queue (before fastthread).
class PriorityQueue
  module MakeMultiRBTreeLikePriorityQueue
    # Push object with priority specified by +pri+.
    def push(obj, pri)
      store(pri, obj)
    end
    
    # Return oldest item among those with highest key.
    def shift
      last && delete(last[0])
    end
  end
  
  def initialize
    @waiting = []
    @que = MultiRBTree.new
    @que.extend MakeMultiRBTreeLikePriorityQueue
  end

  # Push +obj+ with priority equal to +pri+ if given or, otherwise,
  # the result of sending #queue_priority to +obj+. Objects are
  # dequeued in priority order, and first-in-first-out among objects
  # with equal priorities. Implementation is the same as the std lib,
  # except for the priority arg.
  def push(obj, pri = obj.queue_priority)
    Thread.critical = true
    @que.push obj, pri
    begin
      t = @waiting.shift
      t.wakeup if t
    rescue ThreadError
      retry
    ensure
      Thread.critical = false
    end
    begin
      t.run if t
    rescue ThreadError
    end
  end
  alias << push
  alias enq push

  class QueueEmptyError < ThreadError; end
  
  #
  # Retrieves data from the queue.  If the queue is empty, the calling thread is
  # suspended until data is pushed onto the queue.  If +non_block+ is true, the
  # thread isn't suspended, and an exception is raised.
  #
  def pop(non_block=false)
    while (Thread.critical = true; @que.empty?)
      raise QueueEmptyError, "queue empty" if non_block
      @waiting.push Thread.current
      Thread.stop
    end
    @que.shift
  ensure
    Thread.critical = false
  end
  alias shift pop
  alias deq pop

  #
  # Returns +true+ is the queue is empty.
  #
  def empty?
    @que.empty?
  end

  #
  # Removes all objects from the queue.
  #
  def clear
    @que.clear
  end

  #
  # Returns the length of the queue.
  #
  def length
    @que.length
  end
  alias size length

  #
  # Returns the number of threads waiting on the queue.
  #
  def num_waiting
    @waiting.size
  end
end

__END__

Thread.abort_on_exception = true

pq = PriorityQueue.new

n = 100

t1 = Thread.new do
  n.times do |i|
    pri = rand(5)
    pq.push([pri, i], pri)
  end
end

result = []

t2 = Thread.new do
  n.times do
    result << pq.pop
  end
end

t1.join
t2.join

#puts result.map {|a| a.inspect}.join("\n")

sorted_result = result.sort do |(pri1,i1),(pri2,i2)|
  [pri2,i1] <=> [pri1,i2]
end

#puts sorted_result.map {|a| a.inspect}.join("\n")

raise unless result == sorted_result
