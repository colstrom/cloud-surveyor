require 'shoryuken'
require_relative 'miner'
require_relative '../support/ec2'

class VPCSurveyor
  include ::Shoryuken::Worker

  shoryuken_options queue: 'ec2-stale-vpcs', auto_delete: true

  def perform(_, region)
    ::Support::EC2.new(region).vpcs.value.each do |vpc|
      VPCMiner.perform_async(vpc)
    end
  end
end
