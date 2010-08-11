#!/usr/bin/env ruby

require 'irb'
require 'irb/completion'

def start(ap_path = nil)
  $0 = File::basename(ap_path, ".rb") if ap_path

  conf = IRB.conf
  conf[:HISTORY_FILE] = "my-irb-history"
  IRB.setup(ap_path)

  if conf[:SCRIPT]
    irb = IRB::Irb.new(nil, conf[:SCRIPT])
  else
    irb = IRB::Irb.new
  end

  conf[:IRB_RC].call(irb.context) if conf[:IRB_RC]
  conf[:MAIN_CONTEXT] = irb.context

  trap("SIGINT") do
    irb.signal_handle
  end

  begin
    catch(:IRB_EXIT) do
      irb.eval_input
    end
  ensure
    IRB.irb_at_exit
  end
end

start
