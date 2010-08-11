module GoalAttemptor
  class Block
    def initialize(attempt_goal_block)
      instance_eval(&attempt_goal_block)
      
      raise "no goal defined" unless @goal_block
      
      until @goal_block.call
        a = @attempt_blocks.shift
        raise "nothing left to attempt" unless a
        a.call
      end
    end
    
    def goal(&goal_block)
      @goal_block = goal_block
    end

    def attempt(&attempt_block)
      (@attempt_blocks ||= []) << attempt_block
    end
  end
  
  def attempt_goal(&attempt_goal_block)
    Block.new(attempt_goal_block)
  end
  module_function :attempt_goal
end

if __FILE__ == $0

  x = 2

  include GoalAttemptor

  attempt_goal do

    goal {x > 5}

    attempt do
      x += 1
    end

    attempt do
      x += 1
    end

    attempt do
      x += 1
    end

    attempt do
      x += 1
    end

  end

  p x   # ==> 6

end
