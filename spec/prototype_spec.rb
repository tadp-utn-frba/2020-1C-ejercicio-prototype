require_relative '../lib/prototype'

describe 'Prototype' do
  it 'pueden definir y acceder a sus propiedades' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.get_property(:nombre)).to eq 'pepe'
  end

  it 'fallan al tratar de acceder a una propiedad que no poseen' do
    guerrero = RootObject.copy

    expect { guerrero.get_property(:nombre) }.to raise_error(PropertyNotFound)
  end

  it 'al definir propiedades definen un metodo con el nombre de la propiedad que devuelve el valor de la misma' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    expect(guerrero.nombre).to eq 'pepe'
    expect(guerrero.respond_to?(:nombre)).to be(true)
  end

  it 'fallan al tratar de responder un mensaje que no se corresponde a ninguna propiedad ni a ningun mensaje que entiendan' do
    guerrero = RootObject.copy

    expect { guerrero.nombre }.to raise_error(NoMethodError)
    expect(guerrero.respond_to?(:nombre)).to be(false)
  end

  it 'al definir propiedades cuyo valor es un proc, tambien definen un metodo con el nombre de la propiedad que ejecuta el proc' do
    guerrero = RootObject.copy

    guerrero.set_property(:saludar, -> { "Hola" })

    expect(guerrero.saludar).to eq("Hola")
  end

  it 'al acceder a propiedades cuyo valor es un proc, devuelven ese proc' do
    guerrero = RootObject.copy

    saludar = proc { "Hola" }

    guerrero.set_property(:saludar, saludar)

    expect(guerrero.get_property(:saludar)).to eq(saludar)
  end

  it 'los metodos creados al definir propiedades con procs como valores ejecutan el proc en contexto del objeto' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar, -> { "Hola, soy #{nombre}" })

    expect(guerrero.saludar).to eq('Hola, soy pepe')
  end

  it 'se pueden copiar, y las copias pueden responder a los mismos mensajes que el prototipo' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    expect(otro_guerrero.get_property(:nombre)).to eq('pepe')
    expect(otro_guerrero.nombre).to eq('pepe')
  end

  it 'las copias pueden redefinir una propiedad, y esto no afecta al prototipo' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'pepe'
    expect(otro_guerrero.nombre).to eq 'marta'
  end

  it 'pueden redefinir sus propiedades, y eso tiene efecto en las copias en caso que estas no hayan redefinido esa propiedad' do
    guerrero = RootObject.copy

    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy

    guerrero.set_property(:nombre, 'marta')

    expect(guerrero.nombre).to eq 'marta'
    expect(otro_guerrero.nombre).to eq 'marta'
  end

  it 'los metodos heredados de prototipos se ejecutan en contexto de quien recibe el mensaje' do
    guerrero = RootObject.copy

    guerrero.set_property(:saludar, -> { "Hola, soy #{nombre}" })
    guerrero.set_property(:nombre, 'pepe')

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:nombre, 'marta')

    expect(otro_guerrero.saludar).to eq('Hola, soy marta')
  end

  it 'usando call_next, pueden usar el comportamiento definido en sus prototipos' do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, -> { 100 })

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia, -> { call_next + 50 })

    expect(otro_guerrero.energia).to eq(150)
  end

  it 'pueden usar call_next aun cuando en la definicion del metodo en su prototipo tambien se usa call_next' do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia, -> { call_next + 50 })

    otro_guerrero_mas = otro_guerrero.copy
    otro_guerrero_mas.set_property(:energia, -> { call_next * 2 })

    expect(otro_guerrero_mas.energia).to eq(300)
  end

  it 'se puede usar call_next mas de una vez en la definicion de una propiedad y el objeto no debería saber responder a call_next' do
    guerrero = RootObject.copy

    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia, -> { call_next + 50 })

    otro_guerrero_mas = otro_guerrero.copy
    otro_guerrero_mas.set_property(:energia, -> { call_next + call_next })

    expect(otro_guerrero_mas.energia).to eq(300)
    expect(otro_guerrero_mas.respond_to?(:call_next)).to be(false)
  end
end
