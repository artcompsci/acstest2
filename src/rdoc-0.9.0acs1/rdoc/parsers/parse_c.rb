  # We attempt to parse C extension files. Basically we look for
  # the standard patterns that you find in extensions: <tt>rb_define_class,
  # rb_define_method</tt> and so on. We also try to find the corresponding
  # C source for the methods and extract comments, but if we fail
  # we don't worry too much.
  #
  # The comments associated with a Ruby method are extracted from the C
  # comment block associated with the routine that _implements_ that
  # method, that is to say the method whose name is given in the
  # <tt>rb_define_method</tt> call. For example, you might write:
  #
  #  /*
  #   * Returns a new array that is a one-dimensional flattening of this
  #   * array (recursively). That is, for every element that is an array,
  #   * extract its elements into the new array.
  #   *
  #   *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
  #   *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
  #   *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
  #   *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  #   */
  #   static VALUE
  #   rb_ary_flatten(ary)
  #       VALUE ary;
  #   {
  #       ary = rb_obj_dup(ary);
  #       rb_ary_flatten_bang(ary);
  #       return ary;
  #   }
  #
  #   ...
  #
  #   void
  #   Init_Array()
  #   {
  #     ...
  #     rb_define_method(rb_cArray, "flatten", rb_ary_flatten, 0);
  #
  # Here RDoc will determine from the rb_define_method line that there's a
  # method called "flatten" in class Array, and will look for the implementation
  # in the method rb_ary_flatten. It will then use the comment from that
  # method in the HTML output. This method must be in the same source file
  # as the rb_define_method.
  #
  # C classes can be diagramed (see /tc/dl/ruby/ruby/error.c), and RDoc
  # integrates C and Ruby source into one tree

  # Classes and modules built in to the interpreter. We need
  # these to define superclasses of user objects

require "rdoc/code_objects"
require "rdoc/parsers/parserfactory"


module RDoc

  KNOWN_CLASSES = {
    "rb_cObject"           => "Object",
    "rb_cArray"            => "Array",
    "rb_cBignum"           => "Bignum",
    "rb_cClass"            => "Class",
    "rb_cDir"              => "Dir",
    "rb_cData"             => "Data",
    "rb_cFalseClass"       => "FalseClass",
    "rb_cFile"             => "File",
    "rb_cFixnum"           => "Fixnum",
    "rb_cFloat"            => "Float",
    "rb_cHash"             => "Hash",
    "rb_cInteger"          => "Integer",
    "rb_cIO"               => "IO",
    "rb_cModule"           => "Module",
    "rb_cNilClass"         => "NilClass",
    "rb_cNumeric"          => "Numeric",
    "rb_cProc"             => "Proc",
    "rb_cRange"            => "Range",
    "rb_cRegexp"           => "Regexp",
    "rb_cString"           => "String",
    "rb_cSymbol"           => "Symbol",
    "rb_cThread"           => "Thread",
    "rb_cTime"             => "Time",
    "rb_cTrueClass"        => "TrueClass",
    "rb_cStruct"           => "Struct",
    "rb_eException"        => "Exception",
    "rb_eStandardError"    => "StandardError",
    "rb_eSystemExit"       => "SystemExit",
    "rb_eInterrupt"        => "Interrupt",
    "rb_eSignal"           => "Signal",
    "rb_eFatal"            => "Fatal",
    "rb_eArgError"         => "ArgError",
    "rb_eEOFError"         => "EOFError",
    "rb_eIndexError"       => "IndexError",
    "rb_eRangeError"       => "RangeError",
    "rb_eIOError"          => "IOError",
    "rb_eRuntimeError"     => "RuntimeError",
    "rb_eSecurityError"    => "SecurityError",
    "rb_eSystemCallError"  => "SystemCallError",
    "rb_eTypeError"        => "TypeError",
    "rb_eZeroDivError"     => "ZeroDivError",
    "rb_eNotImpError"      => "NotImpError",
    "rb_eNoMemError"       => "NoMemError",
    "rb_eFloatDomainError" => "FloatDomainError",
    "rb_eScriptError"      => "ScriptError",
    "rb_eNameError"        => "NameError",
    "rb_eSyntaxError"      => "SyntaxError",
    "rb_eLoadError"        => "LoadError",

    "rb_mKernel"           => "Kernel",
    "rb_mComparable"       => "Comparable",
    "rb_mEnumerable"       => "Enumerable",
    "rb_mPrecision"        => "Precision",
    "rb_mErrno"            => "Errno",
    "rb_mFileTest"         => "FileTest",
    "rb_mGC"               => "GC",
    "rb_mMath"             => "Math",
    "rb_mProcess"          => "Process"

  }

  # See rdoc/c_parse.rb

  class C_Parser


    extend ParserFactory
    parse_files_matching(/\.(c|cc|cpp|CC)$/)


    # prepare to parse a C file
    def initialize(top_level, file_name, body, options)
      @known_classes = KNOWN_CLASSES.dup
      @body = body
      @options = options
      @top_level = top_level
      @classes = Hash.new
    end

    # Extract the classes/modules and methods from a C file
    # and return the corresponding top-level object
    def scan
      remove_commented_out_lines
      do_classes
      do_methods
      @top_level
    end

    #######
    private
    #######

    # remove lines that are commented out that might otherwise get
    # picked up when scanning for classes and methods

    def remove_commented_out_lines
      @body.gsub!(%r{//.*rb_define_}, '//')
    end

    def handle_class_module(var_name, class_mod, class_name, parent, in_module)
      @known_classes[var_name] = class_name
      parent_name = @known_classes[parent] || parent

      if in_module
        enclosure = @classes[in_module]
        unless enclosure
          $stderr.puts("Enclosing class/module '#{in_module}' for " +
                        class_mod + " #{class_name} not known")
          return
        end
      else
        enclosure = @top_level
      end
      
      if class_mod == "class" 
        cm = enclosure.add_class(NormalClass, class_name, parent_name)
      else
        cm = enclosure.add_module(NormalModule, class_name)
      end
      cm.record_location(enclosure.toplevel)
      @classes[var_name] = cm
    end
    
    
    
    def do_classes
      @body.scan(/(\w+)\s* = \s*rb_define_module\(\s*"(\w+)"\s*\)/mx) do 
        |var_name, class_name|
        handle_class_module(var_name, "module", class_name, nil, nil)
      end
      
      @body.scan(/(\w+)\s* = \s*rb_define_module_under
                \( 
                   \s*(\w+),
                   \s*"(\w+)"
                \)/mx) do 
        
        |var_name, in_module, class_name|
        handle_class_module(var_name, "module", class_name, nil, in_module)
      end
      
      @body.scan(/(\w+)\s* = \s*rb_define_class
                \( 
                   \s*"(\w+)",
                   \s*(\w+)\s*
                \)/mx) do 
        
        |var_name, class_name, parent|
        handle_class_module(var_name, "class", class_name, parent, nil)
      end
      
      @body.scan(/(\w+)\s* = \s*rb_define_class_under
                \( 
                   \s*(\w+),
                   \s*"(\w+)",
                   \s*(\w+)\s*
                \)/mx) do 
        
        |var_name, in_module, class_name, parent|
        handle_class_module(var_name, "class", class_name, parent, in_module)
      end
      
    end
    
    
    def do_methods
      @body.scan(/rb_define_(singleton_method|method|module_function)\(\s*(\w+),
                               \s*"(.*?)",
                               \s*(?:RUBY_METHOD_FUNC\(|VALUEFUNC\()?(\w+)\)?,
                               \s*(-?\w+)\s*\)/xm) do 
        |type, var_name, meth_name, meth_body, param_count|
        
        class_name = @known_classes[var_name] || var_name
        class_obj  = @classes[var_name]
        if class_obj
          meth_obj = AnyMethod.new("", meth_name)
          meth_obj.singleton = type == "singleton_method"
          
          p_count = (Integer(param_count) rescue -1)
          
          if p_count < 0
            meth_obj.params = "(...)"
          elsif p_count == 0
            meth_obj.params = "()"
          else
            meth_obj.params = "(" +
              (1..p_count).map{|i| "p#{i}"}.join(", ") + 
              ")"
          end
          
          find_body(meth_body, meth_obj)
          class_obj.add_method(meth_obj)
        end
      end
    end
    
    # Find the C code corresponding to a c method
    def find_body(meth_name, meth_obj)
      if @body =~ %r{((?>/\*.*?\*/\s+))(static\s+)?VALUE\s+#{meth_name}
                    \s*(\(.*?\)).*?^}xm
        comment, params = $1, $3
        body_text = $&

        # see if we can find the whole body
        
        re = Regexp.escape(body_text) + "[^(]*^{.*?^}"
        if Regexp.new(re, Regexp::MULTILINE).match(@body)
          body_text = $&
        end

        meth_obj.params = params
        meth_obj.start_collecting_tokens
        meth_obj.add_token(RubyToken::Token.new(1,1).set_text(body_text))
        meth_obj.comment = mangle_comment(comment)
        
      end
    end
    
    # Remove the /*'s and leading asterisks from C comments
    
    def mangle_comment(comment)
      comment.sub!(%r{/\*+}) { " " * $&.length }
      comment.sub!(%r{\*+/}) { " " * $&.length }
      comment.gsub!(/^[ \t]*\*/m) { " " * $&.length }
      comment
    end
    
  end
  
end
