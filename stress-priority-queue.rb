require 'priority-queue'

N = 10
ITER = 10000

q = PriorityQueue.new

def do_thread q, idx
  ITER.times do
    case rand
    when 0..0.60
      puts("*" * q.length)
      q.push((65 + rand(26)).chr, rand(5))
    when 0..0.63
      puts "============ CLEAR"
      q.clear
    when 0..0.85
      begin
        q.pop(true)
      rescue PriorityQueue::QueueEmptyError
      end
    when 0..0.99
      q.pop(false)
    else
      GC.start
      puts "GC "*20
    end
  end
end

threads = (0...N).map do |i|
  Thread.new(i) do |idx|
    do_thread(q, idx)
  end
end

threads.each {|t| t.join}
