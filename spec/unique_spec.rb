require 'resque'
require 'resque/plugins/unique'

require 'spec_helper'

describe "Resque::Plugins::Unique" do
  let(:queue) { :unique_test }
  let(:resque_queue_key) { "queue:#{queue}" }
  let(:arg) { :success }
  let(:lock) { Job.lock(arg) }
  let(:expires_at) {
    ((Time.now.to_f * 1_000).to_i + 3_600_000 + 1_000).to_i
  }


  class Job
    extend Resque::Plugins::Unique
    @queue = :unique_test

    def self.perform(arg)
      if arg.to_sym == :raise
        raise "perform: simulated exception"
      else
        puts "perform: #{arg}"
      end
    end
  end

  before :each do
    Resque.redis.flushall
  end

  it "passes Resque::Plugin.lint" do
    expect {
      Resque::Plugin.lint(Resque::Plugins::Unique)
    }.not_to raise_error
  end

  it "has before_enqueue_hooks" do
    Resque::Plugin.should respond_to :before_enqueue_hooks
  end

  describe "enqueue" do
    it "ensures only one instance of a job exists" do
      3.times { Resque.enqueue(Job, arg) }
      Resque.redis.llen(resque_queue_key).should == 1
    end

    it "locks with time out" do
      Timecop.freeze(Time.now) do
        3.times { Resque.enqueue(Job, arg) }
        Resque.redis.get(lock).to_i.should == expires_at
      end
    end

    it "advances lock expiry on subsequent enqueueing" do
      Resque.enqueue(Job, arg)
      first_expiry = Resque.redis.get(lock)
      Timecop.freeze(Time.now + 10) do
        Resque.enqueue(Job, arg)
        second_expiry = Resque.redis.get(lock)
        second_expiry.to_i.should > first_expiry.to_i
      end
    end
  end

  describe "worker" do
    let(:worker) do
      Resque::Worker.new(queue).tap do |w|
        w.term_child = "1"
        w.very_verbose = "1"
        # w.verbose = "1"
      end
    end

    before :each do
      Resque.enqueue(Job, arg)
      lock.should_not be_nil
      Resque.redis.get(lock).should_not be_nil
    end

    shared_examples_for "a sane worker" do
      it "removes the lock" do
        worker.work(0)
        Resque.redis.get(lock).should be_nil
      end

      it "allows requeueing" do
        worker.work(0)
        Resque.redis.get(lock).should be_nil
        Resque.enqueue(Job, arg)
        lock.should_not be_nil
        Resque.redis.get(lock).should_not be_nil
      end
    end

    context "when job was successfully performed" do
      let!(:arg) { :success }
      it_behaves_like "a sane worker"
    end

    context "when job failed" do
      let!(:arg) { :raise }
      it_behaves_like "a sane worker"
    end
  end
end
