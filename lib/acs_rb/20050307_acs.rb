include_files = %w{ vector acsio clop }

require "acsrequire"

include_files.each do |f|
  file = f + ".rb"
  acsrequire f if $0 != file
end

include Math

VERY_LARGE_NUMBER = 1e30

class Object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end
