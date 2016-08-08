require 'shoryuken'
require_relative 'instance_cacher'
require_relative 'support/ec2'

class RegionSurveyor
  include ::Shoryuken::Worker

  shoryuken_options queue: 'ec2-stale-regions', auto_delete: true

  def perform(_, region)
    ::Support::EC2.new(region).instances.value.each do |instance|
      InstanceCacher.perform_async(instance)
    end
  end
end
