require 'win32/process'
require_relative 'perfmon_proc_getter'

# Wraps the typeperf command-line tool, used to get 
# Windows performance metrics
class TypeperfWrapper
  attr_reader :counters
  
  # Initializes the TypeperfWrapper class
  # [perfmon_proc_getter] Gets the proc for opening the perfmon process and getting messages
  # [interval] The time between samples, defaults to ten seconds
  def initialize(perfmon_proc_getter, interval = 10)
    @interval = interval
    @perfmon_proc_getter = perfmon_proc_getter
    @counters = []
    @msg_queue = Queue.new
  end
  
  # Adds a counter to the list of counters watched
  # [counter_name] The path to the counter, such as "\\processor(_total)\\% processor time"
  def add_counter(counter_name)
    raise 'Perfmon counter could not be found.' unless @perfmon_proc_getter.counter_exists?(counter_name)
    @counters << counter_name.downcase
  end
  
  # Begins monitoring, using the counters in the @counters array
  # [interval] The time between samples, defaults to ten seconds
  def start_monitor
    raise "No perfmon counters defined" if @counters.compact.empty?
    open_thread_and_do_work()
  end
  
  # Stops monitoring
  def stop_monitor
    @perfmon_proc_getter.stop_process
  end
  
  # Gets a value indicating whether the typeperf process is running
  def alive?
    @perfmon_proc_getter.proc_is_running?
  end
  
  # Waits until a new message is put onto the queue, then returns it
  def get_next
    while @msg_queue.empty?
      sleep 0.5 
    end
	
    @msg_queue.pop
  end
  
  #-------------Private methods----------------
  private
  
  def open_thread_and_do_work
    Thread.new do
      @perfmon_proc_getter.start_process(@counters, @interval, @msg_queue)
    end
	
    @perfmon_proc_getter.wait_for_process_to_start
  end
end