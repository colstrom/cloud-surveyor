require 'shoryuken'
require_relative 'miner'
require_relative 'support/ec2'

class TagSurveyor
  include ::Shoryuken::Worker

  shoryuken_options queue: 'ec2-stale-tags', auto_delete: true

  def perform(_, region)
    ::Support::EC2.new(region).tags.value.each do |tag|
      TagCacher.perform_async(tag)
    end
  end
end
