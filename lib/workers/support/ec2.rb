require 'aws-sdk'
require 'concurrent'
require 'contracts'
require 'facets'
require_relative 'eventual_assignment'

module Support
  class EC2
    include ::Contracts::Core
    include ::Contracts::Builtin
    include ::EventualAssignment

    Contract String => ::Support::EC2
    def initialize(region)
      @region = region
      self
    end

    Contract None => ::Aws::EC2::Client
    def api
      @api ||= ::Aws::EC2::Client.new region: @region
    end

    Contract None => ::Concurrent::IVar
    def reservations
      @reservations ||= eventually do
        api.describe_instances.reservations
      end
    end

    Contract None => ::Concurrent::IVar
    def instances
      @instances ||= eventually do
        reservations.value.flat_map do |reservation|
          reservation.instances.map(&:to_h).map(&:stringify_keys)
        end
      end
    end

    Contract None => ::Concurrent::IVar
    def tags
      @tags ||= eventually do
        api.describe_tags.tags.map(&:to_h).map(&:stringify_keys)
      end
    end

    Contract None => ::Concurrent::IVar
    def vpcs
      @vpcs ||= eventually do
        api.describe_vpcs.vpcs.map(&:to_h).map(&:stringify_keys)
      end
    end

    Contract None => ::Concurrent::IVar
    def addresses
      @addresses ||= eventually do
        api.describe_addresses.addresses
      end
    end
  end
end
