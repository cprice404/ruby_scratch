# We define this module to hold the global state we require, so that
# we don't alter the global namespace any more than necessary.
module LoadTrace
  # This array holds our list of files loaded and classes defined.
  # Each element is a subarray holding the class defined or the
  # file loaded and the stack frame where it was defined or loaded.
  T = []  # Array to hold the files loaded

  # Now define the constant OUT to specify where tracing output goes.
  # This defaults to STDERR, but can also come from command-line arguments
  if x = ARGV.index("--traceout")    # If argument exists
    OUT = File.open(ARGV[x+1], "w")  # Open the specified file
    ARGV[x,2] = nil                  # And remove the arguments
  else
    OUT = STDERR                     # Otherwise default to STDERR
  end


  @origin_stack = []

  def self.record_load_if_interesting(load_path, origin)
    if (load_path =~ /^(?:(?:puppet)|\.|\/)/) then
      if (@origin_stack.length == 0) then
        @origin_stack.push(load_path)
      else
        origin_match = origin.match(/^.*\/lib\/(.*)\.rb:\d+$/)
        if (origin_match) then
          origin_path = origin_match[1]
          if (! (@origin_stack.include?(origin_path))) then
            @origin_stack.push(origin_path)
          elsif (@origin_stack[-1] == origin_path) then
          else
            while (@origin_stack[-1] != origin_path) do
              @origin_stack.pop()
            end
          end
        end

        LoadTrace.add_trace_event(:load, load_path, origin)
      end
    end
  end

  def self.add_trace_event(operation, object, origin)
    LoadTrace::T << [@origin_stack.length, operation, object, origin]
  end

  def self.print_report()
    o = LoadTrace::OUT
    o.puts "="*60
    o.puts "Files Loaded and Classes Defined:"
    o.puts "="*60
    LoadTrace::T.each do |depth, operation, object, origin|
      o.puts "#{"  " * depth}#{operation}: #{object} at #{origin}"
    end
  end


  @traced_methods = {}
  def self.trace_method(module_or_class_name, method_sym, &block)
    @traced_methods[module_or_class_name] ||= {}
    @traced_methods[module_or_class_name][method_sym] = block
  end


  def self.call_traced_method_block(module_or_class_name, method_name, args, origin)
    extra_trace_val = ""
    if (@traced_methods.has_key?(module_or_class_name) &&
        @traced_methods[module_or_class_name].has_key?(method_name) &&
        ! @traced_methods[module_or_class_name][method_name].nil?) then
      extra_trace_val = @traced_methods[module_or_class_name][method_name].call(args)
    end

    return if extra_trace_val.nil?

    extra_trace_val = " (#{extra_trace_val})" unless extra_trace_val.empty?

    LoadTrace.add_trace_event(:method_call, "#{module_or_class_name}.#{method_name}(#{args.inspect})#{extra_trace_val}", origin)
  end



  @currently_defining_alias = false;

  def self.handle_method_added(is_singleton, method_sym, context)
    return if @currently_defining_alias
    if (@traced_methods.has_key?(context.to_s) &&
        @traced_methods[context.to_s].has_key?(method_sym)) then
        chained_method_def = <<END
alias original_#{method_sym} #{method_sym}

def #{method_sym}(*args)
  LoadTrace.call_traced_method_block("#{context.to_s}",  :#{method_sym}, args, caller[3])
  original_#{method_sym}(*args)
end
END

      target = eval(context.to_s);
      if is_singleton then
        target = class << target; self; end
      end

      @currently_defining_alias = true
      target.class_eval(chained_method_def)
      @currently_defining_alias = false
    end
  end

end

# Alias chaining step 1: define aliases for the original methods
alias original_require require
alias original_load load

# Alias chaining step 2: define new versions of the methods 
def require(file)
  LoadTrace::record_load_if_interesting(file, caller[0])
  original_require(file)                # Invoke the original method
end
def load(*args)
  LoadTrace::record_load_if_interesting(args[0], caller[0])
  original_load(*args)                  # Invoke the original method
end


def Object.method_added(method_sym)
  LoadTrace.handle_method_added(false, method_sym, self)
end

def Object.singleton_method_added(method_sym)
  LoadTrace.handle_method_added(true, method_sym, self)
end


## This hook method is invoked each time a new class is defined
#def Object.inherited(c)
##  LoadTrace::T << [c,caller[0]]        # Remember what was defined where
#end

# Kernel.at_exit registers a block to be run when the program exits
# We use it to report the file and class data we collected
at_exit {
  LoadTrace::print_report()
}
