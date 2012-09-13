module Resque
  module Plugins
    module Unique
      def lock(*args)
        "unique:#{name}-#{args.map(&:to_sym).to_s}"
      end

      def lock_timeout
        @lock_timeout || 3_600 #seconds
      end

      def before_enqueue_unique(*args)
        acquire_lock(*args)
      end

      def around_perform_unique(*args)
        begin
          yield
        ensure
          # Always clear the lock when we're done, even if there is an
          # error.
          Resque.redis.del(lock(*args))
        end
      end

    private

      def lock_expires_at
        ((Time.now.to_f * 1_000).to_i + (lock_timeout * 1_000) + 1_000).to_i
      end

      # http://redis.io/commands/setnx
      def acquire_lock(*args)
        if Resque.redis.setnx(lock(*args), lock_expires_at)
          true
        else
          new_lock_expiry = lock_expires_at
          existing_lock_expiry = Resque.redis.getset(lock(*args), new_lock_expiry).to_i
          existing_lock_expiry <= Time.now.to_i
        end
      end

    end
  end
end
