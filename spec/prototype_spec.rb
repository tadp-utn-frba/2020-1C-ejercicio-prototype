# que pasa cuando no esta la property, PropertyNotFound
# method missing
# instance_eval.... -> instance_exec -> define_singleton_method(name, &block)
# extender con call_next ?

class NullPrototype
  def get_property(_name)
    raise PropertyNotFound.new
  end
end

class Prototype
  def initialize(prototype = NullPrototype.new)
    @prototype = prototype
    @properties = {}
  end

  def set_property(name, value = nil, &block)
    if block_given?
      @properties = @properties.merge(name => block)
      # define_singleton_method(name, &block)
    else
      @properties = @properties.merge(name => value)
      # define_singleton_method(name) { get_property(name) }
    end
  end

  def copy
    self.class.new(self)
  end

  def get_property(name)
    @properties.fetch(name) do
      @prototype.get_property(name)
    end
  end

  def method_missing(method_name, *params)
    if respond_to_missing?(method_name, false)
      property = get_property(method_name)
      case property
      when Proc
        instance_exec(*params, &property)
      else
        property
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private_methods)
    has_property?(method_name) || @prototype.respond_to?(method_name, include_private_methods)
  end

  private

  def has_property?(method_name)
    @properties.key?(method_name)
  end
end

RootObject = Prototype.new

class PropertyNotFound < StandardError; end

describe '' do
  it 'if I set a property and then I ask for it, it returns me the value of the property' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.get_property(:nombre)).to eq 'pepe'
  end

  it '' do
    guerrero = RootObject.copy

    expect { guerrero.get_property(:nombre) }.to raise_error(PropertyNotFound)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.nombre).to eq 'pepe'
    expect(guerrero.respond_to?(:nombre)).to be(true)
  end

  it do
    guerrero = RootObject.copy

    expect { guerrero.nombre }.to raise_error(NoMethodError)
    expect(guerrero.respond_to?(:nombre)).to be(false)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:saludar) { "Hola" }

    expect(guerrero.saludar).to eq("Hola")
  end

  it do
    guerrero = RootObject.copy

    saludar = proc { "Hola" }

    guerrero.set_property(:saludar, &saludar)

    expect(guerrero.get_property(:saludar)).to eq(saludar)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar) { "Hola, soy #{nombre}" }

    expect(guerrero.saludar).to eq('Hola, soy pepe')
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    expect(otro_guerrero.get_property(:nombre)).to eq('pepe')
    expect(otro_guerrero.nombre).to eq('pepe')
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'pepe'
    expect(otro_guerrero.nombre).to eq 'marta'
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'marta'
    expect(otro_guerrero.nombre).to eq 'marta'
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:saludar) { "Hola, soy #{nombre}" }
    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:nombre, 'marta')

    expect(otro_guerrero.saludar).to eq('Hola, soy marta')
  end
end
