class PerfmonProcGetter
  attr_reader :pid
  
  # Initializes the PerfmonProcGetter class
  def initialize
    @all_counters = `#{get_all_counters_command}`
  end
  
  # Creates a new process that runs typeperf to collect perfmon metrics
  # [counters] Array of counter names, such as ["\\Processor(_Total)\\% Processor Time"]
  # [interval] The number, in seconds, to wait between each round of collecting metrics
  # [output_queue] The queue to add each new message to
  def start_process(counters, interval, output_queue)
    cmd = get_typeperf_command(counters, interval)
	  
    IO.popen(cmd) do |f|
      @pid = f.pid

      f.each do |line| 
        next if counters.any? { |counter| line.include? counter } # don't show lines that contain headers
        line.gsub!('"', '') # remove quotes
        line.strip!
        output_queue << line
      end
    end
  end
  
  # Kills the typeperf process
  def stop_process
    Process.kill(9, @pid) 
    @pid = nil
  end
  
  # Gets a value indicating whether the typeperf
  # process is currently running
  def proc_is_running?
    if @pid.nil?
      return false
    else
      return true
    end
  end
  
  # Gets a value indicating whether the given counter 
  # exists on the system
  # [counter_name] The name of the counter, such as "\\Processor(_Total)\\% Processor Time"
  def counter_exists?(counter_name)
    counter_name = counter_name.gsub(/\(.+\)/, '(*)')
    return @all_counters.downcase.include?(counter_name.downcase)
  end
  
  # Gets the typeperf command line
  # [counters] Array of counter names, such as ["\\Processor(_Total)\\% Processor Time"]
  # [interval] The number, in seconds, to wait between each round of collecting metrics
  def get_typeperf_command(counters, interval)
    cmd = "typeperf "
    counters.each { |counter| cmd << "\"#{counter}\" " }
    cmd << "-si #{interval.to_s} "
    return cmd.strip!
  end
  
  # Gets the command line that lists all available 
  # perf counters on the system
  def get_all_counters_command
    "typeperf -q"
  end
  
  # Waits until the typeperf process is running
  def wait_for_process_to_start
    sleep 0.5 until proc_is_running?
  end
end