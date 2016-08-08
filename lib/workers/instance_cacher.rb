require 'contracts'
require 'redis'
require 'shoryuken'
require_relative 'associates_availability_zones'
require_relative 'support/hash_compactor'

class InstanceCacher
  include ::Shoryuken::Worker
  include ::Contracts::Core
  include ::Contracts::Builtin

  shoryuken_options queue: 'ec2-instances', auto_delete: true, body_parser: :json

  Contract None => ::Redis
  def redis
    @redis ||= ::Redis.new
  end

  Contract RespondTo[:to_s] => Bool
  def register(id)
    redis.sadd('instances', id)
  end

  Contract RespondTo[:to_s], Hash => Bool
  def update(id, properties)
    data = HashCompactor.new.collapse(properties)
    redis.hmset("instance:#{id}", *data) == 'OK'
  end

  Contract Any, RespondTo[:fetch] => Any
  def perform(_, instance)
    id = instance.fetch('instance_id')

    register(id).tap do |added|
      AssociatesAvailabilityZones.perform_async(id)
      STDERR.puts "Registered new instance: #{id}" if added
    end

    update(id, instance).tap do |success|
      STDERR.puts "Updated cache for #{id}" if success
    end
  end
end
