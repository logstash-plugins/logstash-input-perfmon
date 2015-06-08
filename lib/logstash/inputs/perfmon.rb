# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname
require_relative "typeperf_wrapper"

# This input will pull metrics from https://technet.microsoft.com/en-us/library/cc749249.aspx[Windows Performance Monitor].
# Under the covers, it uses https://technet.microsoft.com/en-us/library/bb490960.aspx[Typeperf].
#
# To collect performance measurements, use a config like:
# [source,ruby]
#     input {
#       perfmon {
#         interval => 10
#         counters => [
#           "\Processor(_Total)\% Privileged Time",
#           "\Processor(_Total)\% Processor Time", 
#           "\Processor(_Total)\% User Time"]
#       }
#     }

#     filter {
#       grok {
#         match => {
#           "message" => "%{DATESTAMP:Occurred},%{NUMBER:PrivilegedTime:float},%{NUMBER:ProcessorTime:float},%{NUMBER:UserTime:float}"
#       }
#     }
#   }
class LogStash::Inputs::Perfmon < LogStash::Inputs::Base
  attr_reader :counters, :interval, :host
  
  config_name "perfmon"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain" 
  
  # Sets which perfmon counters to collect
  config :counters, :validate => :array, :required => false, :default => [
    "\\Processor(_Total)\\% Processor Time",
    "\\Processor Information(_Total)\\% User Time", 
    "\\Process(_Total)\\% Privileged Time"]

  # Sets the frequency, in seconds, at which to collect perfmon metrics
  config :interval, :validate => :number, :required => false, :default => 10
  
  # Identifies the server being monitored. Defaults to hostname, but can be overriden.
  # [source,ruby]
  #     input {
  #       perfmon {
  #         interval => 10
  #         counters => ["\Processor(_Total)\% Privileged Time"],
  #         host => "webserver1"
  #       }
  #     }
  config :host, :required => false, :default => Socket.gethostname
  
  #------------Public Methods--------------------
  public
  
  # Registers the plugin with logstash
  def register
    @typeperf = TypeperfWrapper.new(PerfmonProcGetter.new, @interval)
    @counters.each { |counter| @typeperf.add_counter(counter) }
  end

  # Runs the perf monitor and monitors its output
  # [queue] The queue to add new events to
  def run(queue)
    @typeperf.start_monitor
	
    @logger.debug("Started perfmon monitor")

    while @typeperf.alive?
      data = @typeperf.get_next

      @codec.decode(data) do |event|
        decorate(event)
		
        event['host'] = @host
		
        queue << event
        @logger.debug("Added event to queue: #{event}")
      end
    end
  end 

  # Cleans up any resources
  def teardown
    @typeperf.stop_monitor
    @logger.debug("Stopped the perfmon monitor")
    finished
  end

end