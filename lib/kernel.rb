module Kernel
  def system_with_debug(*args)
    puts "\nRunning shell command: #{args.join(' ')}"
    system_without_debug(*args)
  end

  # alias_method_chain :system, :debug
  alias system_without_debug system
  alias system system_with_debug
end
