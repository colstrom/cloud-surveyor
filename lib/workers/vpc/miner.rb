require 'contracts'
require 'redis'
require 'shoryuken'
require_relative '../support/hash_compactor'

class VPCMiner
  include ::Shoryuken::Worker
  include ::Contracts::Core
  include ::Contracts::Builtin

  shoryuken_options queue: 'ec2-vpcs', auto_delete: true, body_parser: :json

  Contract None => ::Redis
  def redis
    @redis ||= ::Redis.new
  end

  Contract RespondTo[:to_s] => Bool
  def register(id)
    redis.sadd 'vpcs', id
  end

  Contract RespondTo[:to_s], Hash => Bool
  def update(id, properties)
    data = HashCompactor.new.collapse(properties)
    redis.hmset("vpc:#{id}", *data) == 'OK'
  end

  Contract Any, RespondTo[:fetch] => Any
  def perform(_, vpc)
    id = vpc.fetch('vpc_id')
    register(id).tap { |new| STDERR.puts "Registered new VPC: #{id}" if new }
    update(id, vpc).tap { STDERR.puts "Updated cache for #{id}" }
  end
end
