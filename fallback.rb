# Include this module in your class or module to give it a #fallback method
# that uses the @fallback instance variable to remember state.
module Fallback
  # Yield to the associated block, if any. If the block raises an exception
  # that matches +excep+ (which may be one or more Exception classes, then
  # resumes execution at the previous successful fallback block. Uses a stack
  # to remember history of successful fallbacks, so a fallback can itself fall
  # back.
  #
  def fallback(*excep)
    excep << StandardError if excep.empty?
    @fallback ||= [] # stack of fallbacks
    cont = nil
    prev_fallback = callcc {|cont|}
    result = block_given? ? yield : nil
    @fallback.push cont # if it worked, remember what we did
    result
  rescue *excep
    fallback = @fallback.pop
    fallback.call if fallback
    raise
  end
end

if __FILE__ == $0

  include Fallback

  first_time_C = true
  first_time_E = true
  
  puts "A"

  fallback do
    puts "B"
  end

  fallback do
    puts "C"
    puts first_time_C
    if first_time_C
      first_time_C = false 
      raise
    end
  end

#  fallback do
#    puts "D"
#  end
  
  fallback do
    puts "E"
    if first_time_E
      first_time_C = true ###
      first_time_E = false 
      raise
    end
  end

  fallback do
    puts "F"
  end
  
end

__END__

Output is:

A
B
C
B
C
D
E
D
E
F
