LoadTrace.trace_method("Puppet::Application", :run_mode) do |args|
  # if mode_val is nil then the trace won't occur
  #puts("BLOCK CALLED: '#{args.inspect}'")
  next nil if args.length == 0
  mode_val = args[0]
  next mode_val.to_s unless mode_val.nil?
  nil
end