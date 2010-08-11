$stderr.puts "using standard profiler"

require 'profiler'

END {
  Profiler__::print_profile(STDERR)
}
Profiler__::start_profile

__END__

require 'my-profile'

profile true
