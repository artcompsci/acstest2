class Float
  def to_acs_special_s(precision, indent)
    " " * indent + sprintf(" %#{precision+8}.#{precision}e", self) + "\n"
  end
end

class Vector
  def to_acs_special_s(precision, indent)
    " " * indent +
      self.map{|x| sprintf(" %#{precision+8}.#{precision}e", x)}.join + "\n"
  end
end

class String
  def to_acs_special_s(indent, add_indent)
    s = " " + add_indent.to_s + "\n"
    s += self.gsub(/^/, " " * indent)
    if s =~ /\n$/
      s += " " * indent
    end
    s + "\n"
  end
end

class Array
  def to_acs_special_s(name, precision, indent, add_indent)
    s = ""
    self.each_index do |i|
      s += self[i].to_acs_s(name+"["+i.to_s+"]", precision, indent, add_indent)
    end
    s
  end
end

module ACS_IO

  ACS_HEADER = "ACS\n"
  ACS_FOOTER = "#{ACS_HEADER.chomp.reverse}\n"
  PRECISION = 16
  BASE_INDENT = 0
  ADD_INDENT = 2

  def to_acs_s(name, precision = PRECISION, base_indent = BASE_INDENT,
               add_indent = ADD_INDENT)
    indent = base_indent + add_indent
    if defined? self.class::ACS_IO_NAME
      tag = self.class::ACS_IO_NAME
    else
      tag = self.class.to_s
    end
    s = " " * base_indent + tag + " " + name + "\n"
    if self.instance_variables.size > 0
      return s + instance_variables_to_acs_s(precision, indent, add_indent)
    end
    case self.class.to_s
      when "String"
        return s.chomp + self.to_acs_special_s(indent, add_indent)
      when "Array"
        return s + self.to_acs_special_s(name, precision, indent, add_indent)
      when /^(Float|Vector)$/
        return s + self.to_acs_special_s(precision, indent)
    end
    s += " " * indent + self.to_s + "\n"
  end

  def instance_variables_to_acs_s(precision, indent, add_indent)
    s = ""
    self.instance_variables.each do |v|
      s += eval(v).to_acs_s(v.delete("@"), precision, indent, add_indent)
    end
    s
  end

  def acs_write(file = $stdout, precision = PRECISION, add_indent = ADD_INDENT)
    file.print ACS_HEADER +
               to_acs_s("", precision, add_indent, add_indent) +
               ACS_FOOTER
  end

  def read_acs_string(file = $stdin)
    s = file.gets
    while s =~ /^\s*$/
      s = file.gets
    end 
    return nil if not s
    raise "Not an ACS file" if s.chomp != ACS_HEADER
    contents = ""
    s = file.gets
    while s.chomp != ACS_FOOTER
      contents += s
      s = file.gets
    end
    contents
  end

  def acs_read(file = $stdin)
    s = read_acs_string(file)
    return nil if not s
    a = s.split("\n")
    acs_parse(a)
  end

  def io_name_okay?(w)
    if defined? ACS_IO_NAME
      if w != ACS_IO_NAME
        raise "first_word = #{first_word} != #{ACS_IO_NAME}"
      end
    else
      if w != self.class.to_s
        raise "first_word = #{first_word} != #{self.class.to_s}"
      end
    end
  end

  def acs_parse(a)
    first_line = a.shift.split
    io_name_okay?(first_line[0])
    name = first_line[1]
    first_line =~ /^ */
    indent = $&.size
    line = a.shift
    return nil if not line
    raise if line !~ /^ */    
    return a.unshift(line) if $&.size <= indent

    # we now know that we have gone one level deeper, where we expect
    # to find either an instance variable or the value for one of the
    # special classes: Float, Fixednum, Bignum, String, Array

#    while((line = a.shift) =~ /^*/
    
    

  end

end

class Object

  include ACS_IO

end
