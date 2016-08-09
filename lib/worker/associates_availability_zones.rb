
require 'contracts'
require 'redis'
require 'shoryuken'

class AssociatesAvailabilityZones
  include ::Shoryuken::Worker
  include ::Contracts::Core
  include ::Contracts::Builtin

  shoryuken_options queue: 'ec2-availability-zone-associations', auto_delete: true

  Contract None => ::Redis
  def redis
    @redis ||= Redis.new
  end

  Contract None => Set
  def instances
    @instances ||= Set.new redis.smembers(:instances)
  end

  Contract String => String
  def availability_zone_region(availability_zone)
    availability_zone.gsub(/[[:alpha:]]$/, '')
  end

  Contract String => Bool
  def add_region(region)
    redis.sadd 'regions', region
  end

  Contract String, String => Bool
  def add_instance_to_region(instance, region)
    redis.sadd "region:#{region}:instances", instance
  end

  Contract String => Bool
  def add_availability_zone(availability_zone)
    redis.sadd 'availability-zones', availability_zone
  end

  Contract String, String => Bool
  def add_availability_zone_to_region(availability_zone, region)
    redis.sadd "region:#{region}:availability-zones", availability_zone
  end

  Contract String, String => Bool
  def add_instance_to_availability_zone(instance, availability_zone)
    redis.sadd "availability-zone:#{availability_zone}:instances", instance
  end

  Contract String => Hash
  def instance(id)
    redis.hgetall("instance:#{id}")
  end

  Contract String => String
  def instance_availability_zone(instance)
    instance(instance).fetch('placement:availability_zone')
  end

  Contract String => String
  def associate_instance(instance)
    instance_availability_zone(instance).tap do |availability_zone|
      add_availability_zone availability_zone
      add_instance_to_availability_zone instance, availability_zone
      availability_zone_region(availability_zone).tap do |region|
        add_region region
        add_availability_zone_to_region availability_zone, region
        add_instance_to_region instance, region
      end
    end
  end

  def perform(_, instance)
    associate_instance instance
    # result = instances.map { |instance| associate_instance instance }
    # STDERR.puts "Updated #{result.size} Instances in #{result.uniq.size} AZs"
  end
end
