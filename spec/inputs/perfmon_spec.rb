require "logstash/devutils/rspec/spec_helper"
require_relative '../../lib/logstash/inputs/perfmon'

describe 'IntegrationTests' do
  describe 'Perfmon' do
  
    subject(:plugin) do
	  LogStash::Inputs::Perfmon.new(
		  "interval" => 1,
		  "counters" => ["\\processor(_total)\\% processor time"],
		  "host" => "webserver1"
		)
	end
  
    describe 'initialize' do
      it 'assigns counters' do
		expect(plugin.counters).to eq ["\\processor(_total)\\% processor time"]
	  end
	  
	  it 'assigns interval' do
        expect(plugin.interval).to eq 1
	  end
	  
	  it 'assigns hostname to host when host is not set' do
	    my_plugin = LogStash::Inputs::Perfmon.new(
		  "interval" => 1,
		  "counters" => ["\\processor(_total)\\% processor time"]
		)
		
		my_plugin.register
		
		expect(my_plugin.host).to eq Socket.gethostname
	  end
	  
	  it 'overrides hostname as host when host is set' do
	    my_plugin = LogStash::Inputs::Perfmon.new(
		  "interval" => 1,
		  "counters" => ["\\processor(_total)\\% processor time"],
		  "host" => "webserver1"
		)
		
		my_plugin.register
		
		expect(my_plugin.host).to eq 'webserver1'
	  end
    end
	
	describe 'run' do
	  it 'starts listening for perf metrics' do
	    my_queue = Queue.new
		
		plugin.register
		
		Thread.new do
		  plugin.run(my_queue)
		end
		
		# It can take a few seconds for it to start collecting metrics
		# Wait up to 60 seconds
		60.times do
		  break unless my_queue.empty?
		  sleep 1
		end
		
		expect(my_queue).not_to be_empty
		
		plugin.teardown
	  end
	end
	
  end
end