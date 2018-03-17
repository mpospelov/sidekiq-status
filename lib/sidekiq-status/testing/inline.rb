module Sidekiq
  module Status
    class << self
      def status(jid)
        :complete
      end
    end
  end

  module Storage
    def store_status(id, status, worker_class, expiration = nil, redis_pool=nil)
      'ok'
    end

    def store_for_id(id, status_updates, worker_class, expiration = nil, redis_pool=nil)
      'ok'
    end
  end
end

