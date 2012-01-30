module Approach1
  def self.description() "instance method, 'include'" end
  # start off with a simple module with an instance method
  module MyStaticMethodsModule
    def my_static_method(); "call successful"; end
  end

  class MyClass
    include MyStaticMethodsModule
    def call_static_method(); my_static_method(); end
  end
end

module Approach2
  def self.description() "class method, 'include'" end
  # this time we use a 'class' (or 'module') method instead of an instance method
  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
  end

  class MyClass
    include MyStaticMethodsModule
    def call_static_method(); my_static_method(); end
  end
end

module Approach3
  def self.description() "instance method + 'module_function', 'include'" end
  # here we use instance method + a call to "module_function"
  module MyStaticMethodsModule
    def my_static_method(); "call successful"; end
    module_function :my_static_method
  end

  class MyClass
    include MyStaticMethodsModule
    def call_static_method(); my_static_method(); end
  end
end

module Approach4
  def self.description() "module with 'extend' + instance method, 'include'" end
  # here we use "extend" instead of "module_function"
  module MyStaticMethodsModule
    extend MyStaticMethodsModule
    def my_static_method(); "call successful"; end
  end

  class MyClass
    include MyStaticMethodsModule
    def call_static_method(); my_static_method(); end
  end
end

module Approach5
  def self.description() "module with 'extend' + instance method + 'private', 'include'" end
  # "extend" plus a call to "private"
  module MyStaticMethodsModule
    extend MyStaticMethodsModule
    def my_static_method(); "call successful"; end
    private :my_static_method
  end

  class MyClass
    include MyStaticMethodsModule
    def call_static_method(); my_static_method(); end
  end
end

module Approach6
  def self.description() "class method, manual 'import'" end
  # now we start trying out things that don't require using "include"
  # inside of MyClass.  In this case we very manually, explicitly
  # define an instance method that calls the Module's module/class method
  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
  end

  class MyClass
    def my_static_method(); MyStaticMethodsModule.my_static_method(); end
    def call_static_method(); my_static_method(); end
  end
end

module Approach7
  def self.description() "class method, manual 'import' + 'private'" end
  # same as approach 6, but now we explicitly make the proxy method
  # private
  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
  end

  class MyClass
    def my_static_method(); MyStaticMethodsModule.my_static_method(); end
    private :my_static_method
    def call_static_method(); my_static_method(); end
  end
end

module Approach8
  def self.description() "class method, local 'import' method" end
  # OK, now we've met all of our requirements but the code was not
  # very elegant or sustainable, so let's play around with writing
  # a custom "import" method.
  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
  end

  class MyClass
    def self.import(source_module, methods_list)
      methods_list.each do |method_name|
        define_method(method_name) do |*args|
          source_module::method(method_name).call(*args)
        end
        private method_name
      end
    end

    import MyStaticMethodsModule, [:my_static_method]
    def call_static_method(); my_static_method(); end
  end
end


module Approach9
  def self.description() "class method, external 'import' method" end
  # Now we need to move the import method out to a generic,
  # reusable location
  module Util
    def self.import(clazz, source_module, methods_list)
      methods_list.each do |method_name|
        clazz.send(:define_method, method_name) do |*args|
          source_module::method(method_name).call(*args)
        end
        clazz.send(:private, method_name)
      end
    end
  end

  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
  end

  class MyClass
    Util::import self, MyStaticMethodsModule, [:my_static_method]
    def call_static_method(); my_static_method(); end
  end
end

module Approach10
  def self.description() "class method, external 'import' method + multiple imported methods" end
  # Now let's try it with more than one method, and with a method that
  # takes params

  module MyStaticMethodsModule
    def self.my_static_method(); "call successful"; end
    def self.my_static_method2(param1, param2); param1 + param2; end
  end

  class MyClass
    Approach9::Util::import self, MyStaticMethodsModule,
        [:my_static_method, :my_static_method2]
    def call_static_method()
      # just make sure we can call it
      result = my_static_method2("foo", "bar")
      raise "Agh!" unless result == "foobar"
      my_static_method()
    end
  end
end