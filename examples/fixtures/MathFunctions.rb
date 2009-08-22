require 'rasta/fixture/classic_fixture'

class MathFunctions 
  include Rasta::Fixture::RastaClassicFixture
  attr_accessor :x, :y
  def add
    x+y
  end
  def subtract
    x-y
  end
  def multiply
    x*y
  end
  def divide
    raise ZeroDivisionError, 'Division by zero' if y == 0
    x/y
  end
  def x_is_even?
    x % 2 == 0
  end
end
