# que pasa cuando no esta la property, PropertyNotFound
# method missing
# instance_eval.... -> instance_exec -> define_singleton_method(name, &block)
# extender con call_next ?

class PrototypedObject
  def initialize
    @properties = {}
  end

  def set_property(name, value)
    @properties[name] = value
  end

  def get_property(name)
    @properties.fetch(name) do
      raise PropertyNotFoundError.new
    end
  end
end

class PropertyNotFoundError < StandardError
end

describe do
  it '' do
    guerrero = PrototypedObject.new

    guerrero.set_property(:energia, 100)

    expect(guerrero.get_property(:energia)).to eq(100)
  end

  it '' do
    guerrero = PrototypedObject.new

    expect { guerrero.get_property(:energia) }.to raise_error(PropertyNotFoundError)
  end
end

