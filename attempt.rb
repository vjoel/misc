class Attempt
  attr_reader :attempts, :label
  def initialize label
    @label = "__attempt__#{label}__".intern
    @attempts = 0
  end
  
  TRY_AGAIN = :try_again
  GIVE_UP = :give_up

  def try_again
    @attempts += 1
    throw @label, TRY_AGAIN
  end

  def give_up
    throw @label, GIVE_UP
  end
end

def attempt label
  att = Attempt.new(label)
  ret = nil
  op = Attempt::TRY_AGAIN
  
  while op == Attempt::TRY_AGAIN
    op = catch att.label do
      ret = yield(att)
    end
  end

  ret
end

if __FILE__ == $0

  x = 0
  r = attempt 'add' do |add|
    begin
      x += 1
      if x < 10
        raise ArgumentError
      end
    rescue ArgumentError
      add.try_again if add.attempts < 15
    end
    x
  end

  p r

end
