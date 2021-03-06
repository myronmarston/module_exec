unless Object.new.respond_to?(:instance_exec)
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(mname="__instance_exec#{n}")
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
      ensure
        Thread.critical = old_critical
      end
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
end

unless Module.respond_to?(:module_exec)
  class Module
    def module_exec(*args, &block)
      instance_methods = extract_instance_method_defs_from(block)

      instance_methods.each do |mname, mdef|
        define_method(mname, &mdef)
      end

      instance_exec(*args, &block)

      # any method defs within the instance_exec have defined the methods on the singleton class,
      # so we need to undo the damage here and remove those definitions.
      singleton_class = class << self; self; end
      instance_methods.each do |mname, mdef|
        singleton_class.send(:remove_method, mname)
      end
    end

    def extract_instance_method_defs_from(block)
      klass = Class.new do
        # swallow any missing class method errors; we only care to capture the raw method definitions here.
        def self.method_missing(*a); end

        # skip any dynamic method definitions; they'll happen later during instance_exec
        def self.define_method(*a); end

        # run the block so our instance methods get defined
        class_eval(&block)
      end

      instance = klass.new
      klass.instance_methods(false).inject({}) { |h, m| h[m] = instance.method(m); h }
    end
  end
end
