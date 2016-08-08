require 'contracts'
require 'redis'
require 'shoryuken'

class TagCacher
  include ::Shoryuken::Worker
  include ::Contracts::Core
  include ::Contracts::Builtin

  shoryuken_options queue: 'ec2-tags', auto_delete: true, body_parser: :json

  Contract None => ::Redis
  def redis
    @redis ||= ::Redis.new
  end

  Contract RespondTo[:to_s], RespondTo[:to_s], RespondTo[:to_s], RespondTo[:to_s] => Bool
  def register(type, resource, tag, value)
    redis.set "#{type}:#{resource}:tag:#{tag}", value
    redis.sadd "#{type}:tags", tag
    redis.sadd "#{type}:tagged", resource
    redis.sadd "#{type}:tag:#{tag}", resource
    redis.sadd "tag:#{tag}:resources", resource
    redis.sadd "tag:#{tag}:resource_types", type
    redis.sadd "tag:#{tag}:values", value
  end

  def parse(tag)
    [
      tag.fetch('resource_type'),
      tag.fetch('resource_id'),
      tag.fetch('key'),
      tag.fetch('value')
    ]
  end

  Contract Any, RespondTo[:fetch] => Any
  def perform(_, tag)
    register(*parse(tag))
  end
end
