require 'yaml'

if RUBY_VERSION == "1.8.4"
  class Bignum
    def to_yaml( opts = {} )
      YAML::quick_emit( nil, opts ) { |out|
        out.scalar( nil, to_s, :plain )
      }
    end
  end
end

if defined?(YAML.type_tag) # old version of YAML

  class Module
    def is_complex_yaml?
      false
    end
    def to_yaml( opts = {} )
      YAML::quick_emit( nil, opts ) { |out|
        out << "!ruby/module "
        self.name.to_yaml( :Emitter => out )
      }
    end
  end
  YAML.add_ruby_type(/^module/) do |type, val|
    subtype, subclass = YAML.read_type_class(type, Module)
    val.split(/::/).inject(Object) { |p, n| p.const_get(n)}
  end

  class Class
    def to_yaml( opts = {} )
      YAML::quick_emit( nil, opts ) { |out|
        out << "!ruby/class "
        self.name.to_yaml( :Emitter => out )
      }
    end
  end
  YAML.add_ruby_type(/^class/) do |type, val|
    subtype, subclass = YAML.read_type_class(type, Class)
    val.split(/::/).inject(Object) { |p, n| p.const_get(n)}
  end

else

  class Module
    yaml_as "tag:ruby.yaml.org,2002:module"

    def Module.yaml_new( klass, tag, val )
      if String === val
        val.split(/::/).inject(Object) do |m, n|
          begin
            m.const_get(n)
          rescue NameError
            raise ArgumentError, "undefined class/module #{n} in #{val}"
          end
        end
      else
        raise YAML::TypeError, "Invalid Module: " + val.inspect
      end
    end

    def to_yaml( opts = {} )
      YAML::quick_emit( nil, opts ) { |out|
        out.scalar( "tag:ruby.yaml.org,2002:module", self.name, :plain )
      }
    end
  end

  class Class
    yaml_as "tag:ruby.yaml.org,2002:class"

    def Class.yaml_new( klass, tag, val )
      if String === val
        val.split(/::/).inject(Object) do |m, n|
          begin
            m.const_get(n)
          rescue NameError
            raise ArgumentError, "undefined class/module #{n} in #{val}"
          end
        end
      else
        raise YAML::TypeError, "Invalid Class: " + val.inspect
      end
    end

    def to_yaml( opts = {} )
      YAML::quick_emit( nil, opts ) { |out|
        out.scalar( "tag:ruby.yaml.org,2002:class", self.name, :plain )
      }
    end
  end

end

class Hash
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
#        if opts[:SortKeys] ## fails in nesting, so let's just always sort
          sorted_keys = keys
          sorted_keys = begin
            sorted_keys.sort
          rescue
            sorted_keys.sort_by {|k| k.to_s} rescue sorted_keys
          end
            
          sorted_keys.each do |k|
            map.add( k, fetch(k) )
          end
#        else
#          each do |k, v|
#            map.add( k, v )
#          end
#        end
      end
    end
  end
end

if __FILE__ == $0
  enum_y = [Enumerable, Comparable, String, File].to_yaml
  puts enum_y
  p YAML.load(enum_y)

  h = (0..9).inject({}) {|h,i| h[i] = i; h}
  puts h.to_yaml(:SortKeys => true)
  
  class Unsortable; def to_s; raise; end; end
  y({:a => 1, :b => 2})
  y({Unsortable.new => 1, Unsortable.new => 2})
end
