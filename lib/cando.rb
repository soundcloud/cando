if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  gem_root = File.dirname(File.dirname(File.absolute_path(__FILE__)))
  import "#{gem_root}/lib/tasks/cando.rake"
else
  puts "nope, nothing to do here"
end
