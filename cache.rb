#! /usr/bin/env ruby

# send this to RubyCookbook?

class Module

  def cache(*method_names)
  
    for method_name in method_names
      module_eval %{
        alias :__compute_#{method_name} :#{method_name}
        def #{method_name}
          if @#{method_name}_cached
            @#{method_name}
          else
            @#{method_name}_cached = true
            @#{method_name} = __compute_#{method_name}
          end
        end
        def uncache_#{method_name}
          @#{method_name}_cached = false
        end
      }
    end
    
  end
  alias :memoize_nullary :cache

end

=begin
---Module#cache *method_names
Simple, efficient kind of memoization, but only for nullary methods.

Defines a method (({uncache_<method_name>})) in the client module to clear the cache.

To do: specify methods which should be wrapped with another method that
clears the cache.
=end


if __FILE__ == $0

  class Rect
    attr_reader :l, :w
    def initialize l, w
      @l = l; @w = w
    end
    
    def area
      print "Thinking about it...\n"
      @l * @w
    end
    cache :area  # , :depends => [:l=, :w=]
  end
  
  r = Rect.new 3, 6
  print "First call:  r.area = #{r.area}\n" 
  print "Second call: r.area = #{r.area}\n"
  
  r.uncache_area
  print "Third call:  r.area = #{r.area}\n"
  puts "________________________________"
  
end
