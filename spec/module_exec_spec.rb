require 'rspec'

describe '#module_exec' do
  it 'allows instance methods to be defined' do
    k = Class.new
    k.module_exec do
      def m1; 75; end
    end

    k.should_not respond_to(:m1)
    k.new.m1.should == 75
  end

  it 'allows dynamic methods to be defined with #define_method using the provided parameters' do
    k = Class.new
    k.module_exec(7, 5) do |a, b|
      define_method "m_#{a}_#{b}" do
        a + b + 3
      end
    end

    k.should_not respond_to(:m_7_5)
    k.new.m_7_5.should == 15
  end

  it 'runs with self set to the class receiver' do
    k = Class.new
    me_self = nil
    k.module_exec { me_self = self }
    me_self.should == k
  end

  it 'allows class methods to be defined using def self.method' do
    k = Class.new
    k.module_exec do
      def self.m2; 35; end
    end

    k.new.should_not respond_to(:m2)
    k.m2.should == 35
  end

  it 'allows class methods to be defined using #define_method on the singleton class' do
    k = Class.new
    k.module_exec(2, 3) do |a, b|
      class << self; self; end.send(:define_method, "m_#{a}_#{b}") do
        a + b + 10
      end
    end

    k.new.should_not respond_to(:m_2_3)
    k.m_2_3.should == 15
  end
end
