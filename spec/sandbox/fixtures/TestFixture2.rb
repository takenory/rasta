require 'lib/rasta/fixture/rasta_fixture'

class FixtureC
  include Rasta::Fixture::RastaFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end

class FixtureD
  include Rasta::Fixture::RastaFixture
  attr_accessor :a, :b
  def show_attributes
    [a,b]
  end
end