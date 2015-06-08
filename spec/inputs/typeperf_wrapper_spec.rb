# To run: jruby -S bundle exec rspec -fd spec
require "logstash/devutils/rspec/spec_helper"
require_relative '../../lib/logstash/inputs/typeperf_wrapper.rb'

class MockPerfmonProcGetter
  def start_process(counters, interval, output_queue)
	output_queue << "Test msg 1" 
	output_queue << "Test msg 2" 
	output_queue << "Test msg 3" 
  end
  
  def wait_for_process_to_start
    sleep 1
  end
  
  def counter_exists?(counter_name)
    true
  end
end

describe 'UnitTests' do
  describe 'TypeperfWrapper' do
    subject(:perfmon_proc_getter) do 
      MockPerfmonProcGetter.new
    end
  
    subject(:wrapper) { TypeperfWrapper.new(perfmon_proc_getter) }
  
    describe 'initialize' do
      it 'should initialize the counters array to empty' do
	    expect(wrapper.counters).to be_empty
      end
    end
  
    describe 'add_counter' do
      it 'should add a counter to the array' do
        wrapper.add_counter '\\processor(_total)\\% processor time'
	    expect(wrapper.counters.count).to eq 1
      end
	
	  it 'should convert the counter name to lowercase' do
	    wrapper.add_counter '\\Processor(_total)\\% Processor Time'
	    expect(wrapper.counters[0]).to eq '\\processor(_total)\\% processor time'
	  end
    end
	
	describe 'start_monitor' do
	  it 'should add messages to the message queue' do
	    wrapper.add_counter '\\Processor(_total)\\% Processor Time'
		wrapper.start_monitor
		msg1 = wrapper.get_next
		msg2 = wrapper.get_next
		msg3 = wrapper.get_next
		
		expect(msg1).to eq "Test msg 1"
		expect(msg2).to eq "Test msg 2"
		expect(msg3).to eq "Test msg 3"
	  end
	end
	
	describe 'get_next' do
	  it 'waits for message and then returns it' do
	    # Start waiting for messages now, before any are available
		msg = nil
		Thread.new do
		  msg = wrapper.get_next
		end
		
		# Now add a message
		wrapper.add_counter '\\Processor(_total)\\% Processor Time'
		wrapper.start_monitor
		
		# Should be seen by get_next
		sleep 2
		expect(msg).to eq "Test msg 1"
	  end
	end

  end
end





describe 'IntegrationTests' do
  describe 'TypeperfWrapper' do
    subject(:perfmon_proc_getter) do 
      PerfmonProcGetter.new
    end
  
    subject(:wrapper) { TypeperfWrapper.new(perfmon_proc_getter) }
	
	describe 'start_monitor' do
      it 'should raise error if no counters are defined' do
	    expect { wrapper.start_monitor }.to raise_error('No perfmon counters defined')
	  end
	
	  it 'should start the process running' do
	    wrapper.add_counter '\\Processor(_total)\\% Processor Time'
	    wrapper.start_monitor
	    expect(wrapper.alive?).to eq true
	    wrapper.stop_monitor
	  end
    end
  
    describe 'stop_monitor' do
      it 'should stop the monitor thread' do
	    wrapper.add_counter '\\Processor(_total)\\% Processor Time'
	    wrapper.start_monitor
	    wrapper.stop_monitor
	    expect(wrapper.alive?).to eq false
	  end
    end
  
    describe 'alive?' do
      it 'is false when monitor has not been started' do
	    expect(wrapper.alive?).to eq false
	  end
    end
	
	describe 'add_counter' do
	  it 'raises error when counter is not found' do
	    expect { wrapper.add_counter('\\Nada(_total)\\% DoesntExist') }.to raise_error 'Perfmon counter could not be found.'
	  end
	end
  end
end
