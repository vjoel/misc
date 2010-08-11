# Extend a class by SubclassKeeper to record all subclasses (including itself)
# and make the list available with the #subclasses method.
module SubclassKeeper
  def inherited(sub)
    super
    add_subclass(sub)
  end
  def add_subclass(sub)
    superclass.add_subclass(sub) if superclass.respond_to? :add_subclass
    (@proper_subclasses ||= []) << sub
  end
  protected :add_subclass
  def proper_subclasses
    (@proper_subclasses ||= []).dup
  end
  def subclasses
    proper_subclasses.unshift(self)
  end
end

if __FILE__ == $0
  class Base
    extend SubclassKeeper
  end

  class Sub1 < Base; end
  class Sub2 < Sub1; end

  p Base.subclasses
  p Sub1.subclasses
  p Sub2.subclasses
end
