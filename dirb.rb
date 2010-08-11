#!/usr/bin/env ruby

require 'irb'
require 'irb/completion'

module IRB
  def IRB.parse_opts
    # Don't touch ARGV, which belongs to the app which called this module.
  end
  
  def IRB.start_session(object)
    unless $irb
      IRB.setup nil
      ## maybe set some opts here, as in parse_opts in irb/init.rb?
    end

    workspace = WorkSpace.new(object)

    if @CONF[:SCRIPT] ## normally, set by parse_opts
      $irb = Irb.new(workspace, @CONF[:SCRIPT])
    else
      $irb = Irb.new(workspace)
    end

    @CONF[:IRB_RC].call($irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = $irb.context

    trap 'INT' do
      $irb.signal_handle
    end
    
    custom_configuration if defined?(IRB.custom_configuration)

    catch :IRB_EXIT do
      $irb.eval_input
    end
    
    ## might want to reset your app's interrupt handler here
  end
end

class Object
  include IRB::ExtendCommandBundle # so that Marshal.dump works
end

if __FILE__ == $0
  require 'drb'
  require 'optparse'

  local_uri = nil
  remote_uri = nil
    
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]\n"

    opts.separator("")
    
    opts.on("-l", "--local-uri URI", String,
            "URI of this process") {|local_uri|}
    opts.on("-r", "--remote-uri URI", String,
            "URI to connect irb to") {|remote_uri|}

    opts.separator("")

    opts.on_tail("-h", "--help", "show this message") do
      puts opts
      exit
    end
  end

  begin
    opts.parse!(ARGV)
    unless ARGV.size == 0
      raise OptionParser::ParseError,
        "Too many non-option arguments: #{ARGV.join(' ')}"
    end
  rescue OptionParser::ParseError => e
    puts "", e.message, ""
    puts opts
    exit
  end

  if remote_uri  # client
    DRb.start_service(local_uri)
    main = DRbObject.new(nil, remote_uri)
    puts "dirb client starting at #{DRb.uri}"
  else    # server
    main = Object.new
    DRb.start_service(local_uri, main)
    puts "dirb server starting at #{DRb.uri}"
  end
  
  IRB.start_session(main)
end
