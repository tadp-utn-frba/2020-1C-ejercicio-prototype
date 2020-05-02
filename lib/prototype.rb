class NullPrototype
  def get_property(_name)
    raise PropertyNotFound.new
  end
end

class Prototype
  attr_reader :prototype

  def initialize(prototype = NullPrototype.new)
    @prototype = prototype
    @properties = {}
  end

  def set_property(name, value)
    @properties = @properties.merge(name => value)
  end

  def copy
    self.class.new(self)
  end

  def get_property(name)
    @properties.fetch(name) { @prototype.get_property(name) }
  end

  def method_missing(method_name, *params)
    if respond_to_missing?(method_name, false)
      evaluate_property_value(method_name, params, self)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private_methods)
    has_property?(method_name) || @prototype.respond_to?(method_name, include_private_methods)
  end

  private

  def evaluate_property_value(property_name, params, property_holder)
    property = property_holder.get_property(property_name)
    property.is_a?(Proc) ? evaluate_proc_property_value(property, property_name, params, property_holder) : property
  end

  def evaluate_proc_property_value(property, property_name, params, property_holder)
    call_next_was_already_defined = has_property?(:call_next)
    previous_call_next = get_property(:call_next) if call_next_was_already_defined
    set_property(:call_next, -> { evaluate_property_value(property_name, params, property_holder.prototype) })
    result = instance_exec(*params, &property)
    call_next_was_already_defined ? set_property(:call_next, previous_call_next) : remove_property(:call_next)

    result
  end

  def has_property?(method_name)
    @properties.key?(method_name)
  end

  def remove_property(property_name)
    @properties.delete(property_name)
  end
end

class PropertyNotFound < StandardError; end

RootObject = Prototype.new
