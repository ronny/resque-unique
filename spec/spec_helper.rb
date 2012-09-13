require 'rspec/autorun'
Dir["spec/support/**/*.rb"].each {|f| require f}

require 'timecop'

RSpec.configure do |config|
  config.before(:each) do
    Resque.redis.flushall
  end

  config.after(:each) do
    Resque.redis.flushall
  end
end
