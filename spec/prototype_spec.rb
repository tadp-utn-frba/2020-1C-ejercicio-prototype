# que pasa cuando no esta la property, PropertyNotFound
# method missing
# instance_eval.... -> instance_exec -> define_singleton_method(name, &block)
#

class Object
  def instance_exec_b(param_block, *args, &method_block)
    self.class.send(:define_method, :__juegos_de_azar_y_mujerzuelas__, &method_block)

    posta_method = self.method(:__juegos_de_azar_y_mujerzuelas__)

    self.class.send(:remove_method, :__juegos_de_azar_y_mujerzuelas__)

    posta_method.call(*args, &param_block)
  end
end

class X
  def initialize
    @properties = {}
  end
end

RootPrototype = X.new

RootPrototype.instance_eval do
  def respond_to_missing?(method_name, include_private_methods)
    has_property?(method_name)
  end

  def lookup_property_in_prototype(_name)
    raise PropertyNotFound.new
  end

  set_property_block = proc do |name, value = nil, &block|
    if block_given?
      @properties = @properties.merge(name => block)
      # define_singleton_method(name, &block)
    else
      @properties = @properties.merge(name => value)
      # define_singleton_method(name) { get_property(name) }
    end
  end

  define_singleton_method(:set_property, &set_property_block)

  set_property(:set_property, set_property_block)

  cosas = proc do
    @x = cosas

    # def set_property(name, value = nil, &block)
    #   if block_given?
    #     @properties = @properties.merge(name => block)
    #     # define_singleton_method(name, &block)
    #   else
    #     @properties = @properties.merge(name => value)
    #     # define_singleton_method(name) { get_property(name) }
    #   end
    # end

    def method_missing(method_name, *params, &block)
      if respond_to_missing?(method_name, false)
        property = get_property(method_name)
        case property
        when Proc
          if block_given?
            instance_exec_b(block, *params, &property)
          else
            instance_exec(*params, &property)
          end
        else
          property
        end
      else
        super
      end
    end

    def get_property(name)
      @properties.fetch(name) do
        lookup_property_in_prototype(name)
      end
    end

    def copy
      copied = X.new
      this = self

      copied.instance_eval do
        @prototype = this

        def respond_to_missing?(method_name, include_private_methods)
          has_property?(method_name) || @prototype.respond_to?(method_name, include_private_methods)
        end

        def lookup_property_in_prototype(name)
          @prototype.get_property(name)
        end
      end

      copied.instance_eval(&@x)

      copied
    end

    def has_property?(method_name)
      @properties.key?(method_name)
    end
  end

  instance_eval(&cosas)
end

class PropertyNotFound < StandardError; end

describe '' do
  it 'if I set a property and then I ask for it, it returns me the value of the property' do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.get_property(:nombre)).to eq 'pepe'
  end

  it '' do
    guerrero = RootPrototype.copy

    expect { guerrero.get_property(:nombre) }.to raise_error(PropertyNotFound)
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.nombre).to eq 'pepe'
    expect(guerrero.respond_to?(:nombre)).to be(true)
  end

  it do
    guerrero = RootPrototype.copy

    expect { guerrero.nombre }.to raise_error(NoMethodError)
    expect(guerrero.respond_to?(:nombre)).to be(false)
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:saludar) { "Hola" }

    expect(guerrero.saludar).to eq("Hola")
  end

  it do
    guerrero = RootPrototype.copy

    saludar = proc { "Hola" }

    guerrero.set_property(:saludar, &saludar)

    expect(guerrero.get_property(:saludar)).to eq(saludar)
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar) { "Hola, soy #{nombre}" }

    expect(guerrero.saludar).to eq('Hola, soy pepe')
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    expect(otro_guerrero.get_property(:nombre)).to eq('pepe')
    expect(otro_guerrero.nombre).to eq('pepe')
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'pepe'
    expect(otro_guerrero.nombre).to eq 'marta'
  end

  it do
    guerrero = RootPrototype.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'marta'
    expect(otro_guerrero.nombre).to eq 'marta'
  end
end
