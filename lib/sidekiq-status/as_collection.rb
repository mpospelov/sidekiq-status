module Sidekiq::Status::AsCollection
  NAMESPACE = 'sidekiq:statuses_all'.freeze
  UPDATE_TIME = 'update_time'.freeze
  HASH_KEYS = [:update_time, :status, :args].freeze

  def self.included(base)
    super
    base.extend ClassMethods
  end

  def keys_collection
    self.class.keys_collection
  end

  module ClassMethods
    def keys_collection
      "#{NAMESPACE}:#{self.to_s.downcase}"
    end

    # Stores all keys into set for current worker
    def refresh_collection
      Sidekiq.redis do |conn|
        worker_keys = conn.keys('sidekiq:status:*').select { |k| conn.hget(k, 'worker') == self.to_s }
        conn.del keys_collection
        return if worker_keys.empty?
        conn.sadd keys_collection, worker_keys
      end
    end

    def sorted_keys(page: 1, per_page: 10)
      Sidekiq.redis do |conn|
        conn
          .sort(
            keys_collection,
            limit: [(page - 1) * per_page, per_page],
            by: "*->#{UPDATE_TIME}",
            order: 'DESC',
            get: ['#'] + HASH_KEYS.map { |k| "*->#{k}" }
          )
          .lazy
          .map do |arr|
            { jid: arr[0].split(':').last, worker: self.to_s }.merge!(Hash[HASH_KEYS.zip(arr[1..-1])])
          end
      end
    end

    def total
      Sidekiq.redis { |conn| conn.scard(keys_collection) }
    end
  end
end
