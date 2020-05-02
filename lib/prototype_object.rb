class PrototypeObject
  def initialize(prototype = nil)
    @prototype = prototype
    @properties = {}
  end

  def set_property(property_name, value)
    @properties = @properties.merge(property_name => value)
  end

  def get_property(property_name)
    @properties.fetch(property_name) do
      if @prototype.nil?
        raise PropertyNotFound.new
      else
        @prototype.get_property(property_name)
      end
    end
  end

  def copy
    self.class.new(self)
  end

  def method_missing(method_name, *params, &block)
    if respond_to_missing?(method_name)
      if method_name.to_s.end_with?("=")
        possible_property_name = method_name.to_s.chomp("=")
        set_property(possible_property_name.to_sym, params.first)
      else
        possible_property_name = method_name
        property = get_property(possible_property_name)
        case property
        when Proc
          instance_exec(*params, &property)
        else
          property
        end
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_all_private_methods = false)
    if method_name.to_s.end_with?("=")
      possible_property_name = method_name.to_s.chomp("=")
    else
      possible_property_name = method_name
    end
    @properties.has_key?(possible_property_name.to_sym) || @prototype.respond_to?(possible_property_name.to_sym) || super
  end
end

class PropertyNotFound < StandardError
end