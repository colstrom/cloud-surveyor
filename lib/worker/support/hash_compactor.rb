require 'contracts'
require 'facets'

# Takes a (maybe nested) Hash and compacts it into a non-nested Hash.
class HashCompactor
  include ::Contracts::Core
  include ::Contracts::Builtin

  Contract RespondTo[:to_s] => HashCompactor
  def initialize(delimiter = ':')
    @delimiter = delimiter.to_s
    self
  end

  Contract Array => Hash
  def array_to_hash(array)
    array.each_with_index.map { |object, index| [index, object] }.to_h
  end

  Contract RespondTo[:to_s], Maybe[RespondTo[:to_s]] => String
  def namespace(key, prefix = nil)
    [prefix, key].compact.map(&:to_s).join(@delimiter)
  end

  Contract Hash, Maybe[RespondTo[:to_s]] => Hash
  def flatten(hash, prefix = nil)
    hash
      .map { |key, value| [namespace(key, prefix), value] }
      .to_h
      .each_with_object({}) do |pair, memo|
      key, value = pair
      if value.is_a? Hash
        memo.merge! flatten(value, key)
      else
        memo.store key, value
      end
    end
  end

  Contract Hash => Hash
  def collapse(hash)
    result = hash.each_with_object({}) do |pair, memo|
      key, value = pair
      memo.merge! case value.class.to_s
                  when 'Array'
                    flatten array_to_hash(value), key
                  when 'Hash'
                    flatten(value, key)
                  else
                    { key => value }
                  end
    end

    result.values.any? { |v| v.is_a? Enumerable } ? collapse(result) : result
  end
end
