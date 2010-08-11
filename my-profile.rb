# based on standard profiler
# profiling is not turned on by default
# the report has a new column for total seconds in each method
#
# usage: profile [true|false]
#        profile [true|false] do ... end

class Object
  def profile prof_flag = true
    if block_given?
      save = Profiler.profiler_state
      Profiler.profiler_state = prof_flag
      begin
        yield
      ensure
        Profiler.profiler_state = save
      end
    else
      Profiler.profiler_state = prof_flag
    end
  end
end


module Profiler
  if RUBY_VERSION.to_f >= 1.7
    def self.times; Process.times; end
  else
    def self.times; Time.times; end
  end
    
  Start = Float(Profiler.times[0])
  top = "toplevel".intern
  Stack = [[0, 0, top]]
  MAP = {"#toplevel" => [1, 0, 0, "#toplevel"]}
  
  def self.need_report; @need_report; end
  def self.profiler_state; @state; end
  
  def self.profiler_state= flag
    return unless flag ^ @state
    @need_report = true
    if flag
      set_trace_func @p
    else
      set_trace_func nil
    end
    @state = flag
  end

  def self.report
    set_trace_func nil
    total = Float(Profiler.times[0]) - Start
    if total == 0 then total = 0.01 end
    MAP["#toplevel"][1] = total
#    f = open("./rmon.out", "w")
    f = STDERR
    data = MAP.values.sort!{|a,b| b[2] <=> a[2]}
    sum = 0
    if data
      f.printf "  %%   cumulative   self     total              self     total\n"
      f.printf " time   seconds   seconds   seconds    calls  ms/call  ms/call  name\n"
      for d in data
        sum += d[2]
        f.printf "%6.2f %8.2f  %8.2f  %8.2f %8d ", d[2]/total*100, sum, d[2], d[1], d[0]
        f.printf "%8.2f %8.2f  %s\n", d[2]*1000/d[0], d[1]*1000/d[0], d[3]
      end
    end
    f.close
  end

  @p = proc{|event, file, line, id, binding, klass|
    unless id == :profile or id == :profiler_state or id == :profiler_state=
      case event
      when "call", "c-call"
        now = Float(Profiler.times[0])
        Stack.push [now, 0.0, id]
      when "return", "c-return"
        now = Float(Profiler.times[0])
        tick = Stack.pop
        name = klass.to_s
        if name.nil? then name = '' end
        if klass.kind_of? Class
	  name += "#"
        else
	  name += "."
        end
        name += id.id2name
        data = MAP[name]
        unless data
	  data = [0.0, 0.0, 0.0, name]
	  MAP[name] = data
        end
        data[0] += 1
        cost = now - tick[0]
        data[1] += cost
        data[2] += cost - tick[1]
        Stack[-1][1] += cost
      end
    end
  }
  END {
    Profiler.report if Profiler.need_report
  }
#  set_trace_func @p
end
