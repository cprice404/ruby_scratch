require "rspec"
require "approaches"

describe "Include vs import" do

  approaches = [Approach1, Approach2, Approach3, Approach4, Approach5,
                Approach6, Approach7, Approach8, Approach9, Approach10]
  approaches.each do |namespace|
    describe "#{namespace} (#{namespace.description}): MyClass" do
      my_object = namespace::MyClass.new

      it "should not have an is-a relationship with the module that it imported static methods from" do
        my_object.is_a?(namespace::MyStaticMethodsModule).should == false
      end

      it "should not publicly expose the imported static method" do
        my_object.respond_to?(:my_static_method).should == false
      end

      it "should (internally) have access to the imported static method" do
        my_object.call_static_method().should == "call successful"
      end

      it "should allow access to the static method directly via the module" do
        namespace::MyStaticMethodsModule.my_static_method().should == "call successful"
      end
    end
  end
end