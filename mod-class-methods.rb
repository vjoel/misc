class Module
private
  def when_included_provide_class_methods(&bl)
    unless @__class_methods_module
      @__class_methods_module = Module.new

      def self.append_features(base)
        super
        base.extend(@__class_methods_module)
      end
    end
    
    @__class_methods_module.class_eval(&bl)
  end
end

if __FILE__ == $0

  module MyModule
    when_included_provide_class_methods {
      def a_class_method
          puts 'class'
      end
    }
  end

  class MyClass
    include MyModule
  end

  MyClass.a_class_method # => 'class' 

end
