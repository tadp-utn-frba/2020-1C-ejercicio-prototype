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
    define_singleton_method(name) { get_property(name) }
  end

  def get_property(name)
    @properties.fetch(name) do
      raise PropertyNotFoundError.new
    end
  end

  # def method_missing(name, *params, &block)
  #   if respond_to_missing?(name)
  #     get_property(name)
  #   else
  #     super
  #   end
  # end
  #
  # def respond_to_missing?(name, include_private_methods = false)
  #   @properties.key?(name)
  # end
end

class PropertyNotFoundError < StandardError
end

describe 'Objetos prototipicos' do
  it 'pueden definir propiedades y accederlas' do
    guerrero = PrototypedObject.new

    guerrero.set_property(:energia, 100)

    expect(guerrero.get_property(:energia)).to eq(100)
  end

  it 'fallan si se intenta acceder una propiedad que no poseen' do
    guerrero = PrototypedObject.new

    expect { guerrero.get_property(:energia) }.to raise_error(PropertyNotFoundError)
  end

  it 'puede responder mensajes cuyo nombre se corresponda a una propiedad definida' do
    guerrero = PrototypedObject.new

    guerrero.set_property(:energia, 100)

    expect(guerrero.energia).to eq(100)
    expect(guerrero.respond_to?(:energia)).to be(true)
  end

  it 'no puede responder mensajes cuyo nombre no se corresponda a ninguna propiedad definida' do
    guerrero = PrototypedObject.new

    expect { guerrero.energia }.to raise_error(NoMethodError)
    expect(guerrero.respond_to?(:energia)).to be(false)
  end
end

