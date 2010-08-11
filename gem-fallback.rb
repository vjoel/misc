module Kernel
  req = method :require
  define_method :require do |*args|
    begin
      req.call(*args)
    rescue LoadError => ex
      Kernel.module_eval do
        define_method(:require, &req)
      end
      require 'rubygems'
      if args.grep(/sinatra/).any?
        pat = /gem-fallback.rb/
        if defined?(RUBY_IGNORE_CALLERS)
          RUBY_IGNORE_CALLERS << pat
        else
          RUBY_IGNORE_CALLERS = [pat]
        end
      end
      require(*args)
    end
  end
end
