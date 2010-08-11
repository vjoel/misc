# Provides methods for deferring actions until after a user-defined event
# occurs in the instance of the class in which the deferral was requested.
#
module Defer

  # +event+:: any object -- see #signal
  #
  # +action+:: a code block that will be deferred until the event
  # is signalled
  #
  # Intended for non-recurring events. Deferring an action for an event that
  # has already happened will result in immediate execution of the action.
  #
  def defer_until event, &action
    init_deferred_actions unless @deferred_actions

    if @deferred_actions[event] == :done
      action.call
    else
      (@deferred_actions[event] ||= []) << action
    end

    return nil
  end

  # +event+:: any object -- see #signal
  #
  # +action+:: a code block that will be deferred until the event
  # is signalled
  #
  # Intended for recurring events. Deferring an action for an event that
  # has already happened will defer the action until the next time the event
  # is signalled.
  #
  def defer_until_next event, &action
    init_deferred_actions unless @deferred_actions

    if @deferred_actions[event] == :done
      @deferred_actions[event] = []
    end

    (@deferred_actions[event] ||= []) << action

    return nil
  end
  
  def init_deferred_actions
    unless @deferred_actions
      @deferred_actions = {}
      at_exit do
        @deferred_actions.each do |event, actions|
          unless actions == :done or actions.empty?
            $stderr.puts "There were deferred actions for event #{event} " +
                         "in #{self}."
          end
        end
      end
    end
  end

  # Execute actions that were deferred until +event+.
  #
  # Note that this is reentrant in the sense that an action can defer other
  # actions and can signal events. Actions are always executed in FIFO order.
  #
  # However, #signal is *not* thread safe.
  #
  def signal event
#   $stderr.puts "SIGNAL: #{event} on #{self}"
    @signalled_actions ||= {}
    @signalled_actions[event] = true
    
    @deferred_actions ||= {}
    
    actions = @deferred_actions[event]

    case actions

    when :done
      $stderr.puts "Signalled #{event} again."

    when nil
      $stderr.puts "No actions for event '#{event}'"

    else
      until actions.empty?
        actions.shift.call
      end
    end

    @deferred_actions[event] = :done

#   $stderr.puts "SIGNAL: #{event} on #{self} --- DONE"
    return nil
  end
  
  # Returns true if +event+ has been signalled (but actions might not have
  # completed yet.
  def signalled event
    @signalled_actions and @signalled_actions[event]
  end

end
