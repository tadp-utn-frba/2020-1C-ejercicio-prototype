# que pasa cuando no esta la property, PropertyNotFound
# method missing
# instance_eval.... -> instance_exec -> define_singleton_method(name, &block)
# luego de implementar el copy, cambiar los ejemplos de los tests para que esos objetos se generen a partir de un prototipo original
# extender con call_next ?
# extender con objeto.propiedad = ...

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
    case property
    when Proc
      call_next = method(:call_next) if respond_to?(:call_next)
      define_singleton_method(:call_next) { evaluate_property_value(property_name, params, property_holder.prototype) }
      result = instance_exec(*params, &property)
      if call_next
        define_singleton_method(:call_next, &call_next)
      else
        singleton_class.send(:remove_method, :call_next)
      end

      result
    else
      property
    end
  end

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

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:energia) { 100 }

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia) { call_next + 50 }

    expect(otro_guerrero.energia).to eq(150)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia) { call_next + 50 }

    expect(otro_guerrero.energia).to eq(150)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia) { call_next + 50 }

    otro_guerrero_mas = otro_guerrero.copy
    otro_guerrero_mas.set_property(:energia) { call_next * 2 }

    expect(otro_guerrero_mas.energia).to eq(300)
  end

  it do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, 100)
    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia) { call_next + 50 }
    otro_guerrero.set_property(:nombre) { call_next + ' jr' }

    otro_guerrero_mas = otro_guerrero.copy
    otro_guerrero_mas.set_property(:energia) { call_next + call_next }
    otro_guerrero_mas.set_property(:nombre) { 'marta hijo de ' + call_next }
    otro_guerrero_mas.set_property(:saludar) { nombre + ", con #{energia} de energia" }

    expect(otro_guerrero_mas.energia).to eq(300)
    expect(otro_guerrero_mas.saludar).to eq("marta hijo de pepe jr, con #{300} de energia")
    expect(otro_guerrero_mas.respond_to?(:call_next)).to be(false)
  end
end
