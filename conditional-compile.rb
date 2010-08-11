module M
  solaris = (RUBY_PLATFORM =~ /solaris/i)
  linux = (RUBY_PLATFORM =~ /linux/i)
  windows = (RUBY_PLATFORM =~ /win/i) ### this picks up darwin, unfotunately

  module_eval %{
    def self.print_platform
      print "Platform is... "
      #{
        if solaris then %{
          puts "solaris"
        }
        elsif linux then %{
          puts "linux"
        }
        elsif windows then %{
          puts "windows"
        }
        else %{
          puts "unknown"
        }
        end
      }
    end
  }
end

M.print_platform
