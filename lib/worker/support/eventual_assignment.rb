require 'concurrent'
require 'contracts'

module EventualAssignment
  include ::Contracts::Core
  include ::Contracts::Builtin

  Contract Proc => ::Concurrent::IVar
  def eventually
    ::Concurrent::IVar.new.tap do |ivar|
      Thread.new do
        ivar.set yield
      end
    end
  end

  def method_missing(symbol, *args)
    if instance_variable_defined? "@#{symbol}"
      instance_variable_get "@#{symbol}"
    elsif block_given?
      instance_variable_set("@#{symbol}", eventually { yield(*args) })
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_all = false)
    instance_variables.include?("@#{symbol}".to_sym) || super
  end
end
