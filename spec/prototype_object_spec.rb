require_relative '../lib/prototype_object'

describe 'Prototyped Objects' do
  it 'pueden definir y acceder a sus propiedades' do
    guerrero = PrototypeObject.new

    guerrero.set_property(:energia, 100)

    expect(guerrero.get_property(:energia)).to eq 100
  end

  it 'fallan al tratar de acceder a una propiedad que no poseen' do
    guerrero = PrototypeObject.new

    expect { guerrero.get_property(:energia) }.to raise_error(PropertyNotFound)
  end

  it 'al definir propiedades definen un metodo con el nombre de la propiedad que devuelve el valor de la misma' do
    guerrero = PrototypeObject.new

    guerrero.set_property(:energia, 100)

    expect(guerrero.energia).to eq 100
    expect(guerrero.respond_to?(:energia)).to be(true)
  end

  it 'fallan al tratar de responder un mensaje que no se corresponde a ninguna propiedad ni a ningun mensaje que entiendan' do
    guerrero = PrototypeObject.new

    expect { guerrero.energia }.to raise_error(NoMethodError)
    expect(guerrero.respond_to?(:energia)).to be(false)
  end

  it 'al definir propiedades cuyo valor es un proc, tambien definen un metodo con el nombre de la propiedad que ejecuta el proc' do
    guerrero = PrototypeObject.new

    guerrero.set_property(:saludar, proc { "Hola!" })

    expect(guerrero.saludar).to eq("Hola!")
  end

  it 'los metodos creados al definir propiedades con procs como valores ejecutan el proc en contexto del objeto' do
    guerrero = PrototypeObject.new

    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar, proc { "Hola!, soy #{nombre}" })

    expect(guerrero.saludar).to eq("Hola!, soy pepe")
  end

  it 'los metodos creados al definir propiedades con procs pueden recibir parametros' do
    guerrero = PrototypeObject.new

    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar, proc do |nombre_del_que_saludo|
      "Hola #{nombre_del_que_saludo}!, soy #{nombre}"
    end)

    expect(guerrero.saludar('juan')).to eq("Hola juan!, soy pepe")
  end

  it 'se pueden copiar, y las copias pueden responder a los mismos mensajes que el prototipo' do
    guerrero = PrototypeObject.new
    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy

    expect(otro_guerrero.energia).to eq(100)
  end

  it 'las copias pueden redefinir una propiedad, y esto no afecta al prototipo' do
    guerrero = PrototypeObject.new
    guerrero.set_property(:energia, 100)

    otro_guerrero = guerrero.copy
    otro_guerrero.set_property(:energia, 150)

    expect(guerrero.energia).to eq(100)
    expect(otro_guerrero.energia).to eq(150)
  end

  it 'pueden redefinir sus propiedades, y eso tiene efecto en las copias en caso que estas no hayan redefinido esa propiedad' do
    guerrero = PrototypeObject.new
    guerrero.set_property(:energia, 100)
    otro_guerrero = guerrero.copy

    guerrero.set_property(:energia, 150)

    expect(otro_guerrero.energia).to eq(150)
  end

  it 'los metodos heredados de prototipos se ejecutan en contexto de quien recibe el mensaje' do
    guerrero = PrototypeObject.new
    guerrero.set_property(:nombre, 'pepe')
    guerrero.set_property(:saludar, -> { "Hola!, soy #{nombre}" })
    otro_guerrero = guerrero.copy

    otro_guerrero.set_property(:nombre, 'marta')

    expect(otro_guerrero.saludar).to eq("Hola!, soy marta")
  end

  it 'al definir propiedades definen un metodo con el nombre de la propiedad seguido de = que permite cambiar el valor de la misma' do
    guerrero = PrototypeObject.new
    guerrero.set_property(:nombre, 'pepe')

    guerrero.nombre = 'jose'

    expect(guerrero.respond_to?("nombre=")).to be(true)
    expect(guerrero.nombre).to eq('jose')
  end
end
