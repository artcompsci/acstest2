# We represent the various high-level code constructs that appear
# in Ruby programs: classes, modules, methods, and so on.

require 'rdoc/tokenstream'

module RDoc


  # We contain the common stuff for contexts (which are containers)
  # and other elements (methods, attributes and so on)
  #
  class CodeObject

    # We are the model of the code, but we know that at some point
    # we will be worked on by viewers. By implementing the Viewable
    # protocol, viewers can associated themselves with these objects.

    attr_accessor :viewer

    # do we document ourselves?

    attr_reader :document_self

    def document_self=(val)
      @document_self = val
      if !val
	remove_methods_etc
      end
    end

    # do we document ourselves and our children

    attr_reader :document_children

    def document_children=(val)
      @document_children = val
      if !val
	remove_classes_and_modules
      end
    end

    # Do we _force_ documentation, even is we wouldn't normally show the entity
    attr_accessor :force_documentation

    # Default callbacks to nothing, but this is overridden for classes
    # and modules
    def remove_classes_and_modules
    end

    def remove_methods_etc
    end

    def initialize
      @document_self = true
      @document_children = true
      @force_documentation = false
    end

    # Access the code object's comment
    attr_reader :comment

    # Update the comment, but don't overwrite a real comment
    # with an empty one
    def comment=(comment)
      @comment = comment unless comment.empty?
    end

    # There's a wee trick we pull. Comment blocks can have directives that
    # override the stuff we extract during the parse. So, we have a special
    # class method, attr_overridable, that lets code objects list
    # those directives. Wehn a comment is assigned, we then extract
    # out any matching directives and update our object

    def CodeObject.attr_overridable(name, *aliases)
      @overridables ||= {}

      attr_accessor name

      aliases.unshift name
      aliases.each do |directive_name|
        @overridables[directive_name.to_s] = name
      end
    end
  end

  # A Context is something that can hold modules, classes, methods, 
  # attributes, aliases, requires, and includes. Classes, modules, and
  # files are all Contexts.

  class Context < CodeObject
    attr_reader   :name, :method_list, :attributes, :aliases
    attr_reader   :requires, :includes, :in_files
    attr_accessor :parent
    

    def initialize
      super()

      @in_files    = []

      @name    ||= "unknown"
      @comment ||= ""
      @parent  = nil
      @visibility = :public

      initialize_methods_etc
      initialize_classes_and_modules
    end

    # map the class hash to an array externally
    def classes
      @classes.values
    end

    # map the module hash to an array externally
    def modules
      @modules.values
    end

    # Change the default visibility for new methods
    def ongoing_visibility=(vis)
      @visibility = vis
    end

    # Given an array +methods+ of method names, set the
    # visibility of the corresponding AnyMethod object

    def set_visibility_for(methods, vis)
      @method_list.each_with_index do |m,i|
        if methods.include?(m.name)
          m.visibility = vis
        end
      end
    end

    # Record the file that we happen to find it in
    def record_location(toplevel)
      @in_files << toplevel unless @in_files.include?(toplevel)
    end

    def add_class(class_type, name, superclass)
      add_class_or_module(@classes, class_type, name, superclass)
    end

    def add_module(class_type, name)
      add_class_or_module(@modules, class_type, name, nil)
    end

    def add_method(a_method)
      puts "Adding #@visibility method #{a_method.name} to #@name" if $DEBUG
      a_method.visibility = @visibility
      add_to(@method_list, a_method)
    end

    def add_attribute(an_attribute)
      add_to(@attributes, an_attribute)
    end

    def add_alias(an_alias)
      meth = find_method_named(an_alias.old_name)
      if meth
        new_meth = AnyMethod.new(an_alias.text, an_alias.new_name)
        new_meth.is_alias_for = meth
        new_meth.singleton    = meth.singleton
        new_meth.params       = meth.params
        new_meth.comment = "Alias for \##{meth.name}"
        meth.add_alias(new_meth)
        add_method(new_meth)
      else
        add_to(@aliases, an_alias)
      end
    end

    def add_include(an_include)
      add_to(@includes, an_include)
    end
    
    # Requires always get added to the top-level (file) context
    def add_require(a_require)
      if self.kind_of? TopLevel
        add_to(@requires, a_require)
      else
        parent.add_require(a_require)
      end
    end

    def add_class_or_module(collection, class_type, name, superclass=nil)
      cls = collection[name]
      if cls
        puts "Reusing class/module #{name}" if $DEBUG
      else
        cls = class_type.new(name, superclass)
        puts "Adding class/module #{name} to #@name" if $DEBUG
        collection[name] = cls
        cls.parent = self
      end
      cls
    end

    def add_to(array, thing)
      array <<  thing if @document_self
      thing.parent = self
    end

    # If a class's documentation is turned off after we've started
    # collecting methods etc., we need to remove the ones
    # we have

    def remove_methods_etc
      initialize_methods_etc
    end

    def initialize_methods_etc
      @method_list = []
      @attributes  = []
      @aliases     = []
      @requires    = []
      @includes    = []
    end

    # and remove classes and modules when we see a :nodoc: all
    def remove_classes_and_modules
      initialize_classes_and_modules
    end

    def initialize_classes_and_modules
      @classes     = {}
      @modules     = {}
    end

    # Iterate over all the classes and modules in
    # this object

    def each_classmodule
      @modules.each_value {|m| yield m}
      @classes.each_value {|c| yield c}
    end

    def each_method
      @method_list.each {|m| yield m}
    end

    def each_attribute 
      @attributes.each {|a| yield a}
    end

    # Return the toplevel that owns us

    def toplevel
      return @toplevel if defined? @toplevel
      @toplevel = self
      @toplevel = @toplevel.parent until TopLevel === @toplevel
      @toplevel
    end

    # allow us to sort modules by name
    def <=>(other)
      name <=> other.name
    end

    private

    # Find a named method, or return nil
    def find_method_named(name)
      @method_list.find {|m| m.name == name}
    end
    
  end


  # A TopLevel context is a source file

  class TopLevel < Context
    attr_accessor :file_stat
    attr_accessor :file_relative_name
    attr_accessor :file_absolute_name
    attr_accessor :diagram
    
    @@all_classes = {}
    @@all_modules = {}

    def TopLevel::reset
      @@all_classes = {}
      @@all_modules = {}
    end

    def initialize(file_name)
      super()
      @name = "TopLevel"
      @file_relative_name = file_name
      @file_absolute_name = file_name
      @file_stat          = File.stat(file_name)
      @diagram            = nil
    end

    def full_name
      nil
    end

    # Adding a class or module to a TopLevel is special, as we only
    # want one copy of a particular top-level class. For example,
    # if both file A and file B implement class C, we only want one
    # ClassModule object for C. This code arranges to share
    # classes and modules between files.

    def add_class_or_module(collection, class_type, name, superclass)
      cls = collection[name]
      if cls
        puts "Reusing class/module #{name}" if $DEBUG
      else
        if class_type == NormalModule
          all = @@all_modules
        else
          all = @@all_classes
        end
        cls = all[name]
        if !cls
          cls = class_type.new(name, superclass)
          all[name] = cls
        end
        puts "Adding class/module #{name} to #@name" if $DEBUG
        collection[name] = cls
        cls.parent = self
      end
      cls
    end

    def TopLevel.all_classes_and_modules
      @@all_classes.values + @@all_modules.values
    end

    def TopLevel.find_class_named(name)
     @@all_classes.each_value do |c|
        res = c.find_class_named(name) 
        return res if res
      end
      nil
    end
  end

  # ClassModule is the base class for objects representing either a
  # class or a module.

  class ClassModule < Context

    attr_reader   :superclass
    attr_accessor :diagram

    def initialize(name, superclass = nil)
      @name       = name
      @diagram    = nil
      @superclass = superclass
      @comment    = ""
      super()
    end

    # Return the fully qualified name of this class or module
    def full_name
      if @parent && @parent.full_name
        @parent.full_name + "::" + @name
      else
        @name
      end
    end

    def http_url(prefix)
      path = full_name.split("::")
      File.join(prefix, *path) + ".html"
    end

    # Return +true+ if this object represents a module
    def is_module?
      false
    end

    # to_s is simply for debugging
    def to_s
      res = self.class.name + ": " + @name 
      res << @comment.to_s
      res << super
      res
    end

    def find_class_named(name)
      return self if full_name == name
      @classes.each_value {|c| return c if c.find_class_named(name) }
      nil
    end
  end

  # Anonymous classes
  class AnonClass < ClassModule
  end

  # Normal classes
  class NormalClass < ClassModule
  end

  # Singleton classes
  class SingleClass < ClassModule
  end

  # Module
  class NormalModule < ClassModule
    def is_module?
      true
    end
  end


  # AnyMethod is the base class for objects representing methods

  class AnyMethod < CodeObject
    attr_accessor :name
    attr_accessor :parent
    attr_accessor :visibility
    attr_accessor :block_params
    attr_accessor :dont_rename_initialize
    attr_accessor :singleton
    attr_reader   :aliases           # list of other names for this method
    attr_accessor :is_alias_for      # or a method we're aliasing

    attr_overridable :params, :param, :parameters, :parameter

    include TokenStream

    def initialize(text, name)
      super()
      @text = text
      @name = name
      @token_stream  = nil
      @visibility    = :public
      @dont_rename_initialize = false
      @block_params  = nil
      @aliases       = []
      @is_alias_for  = nil
      @comment = ""
    end

    def <=>(other)
      @name <=> other.name
    end

    def to_s
      res = self.class.name + ": " + @name + " (" + @text + ")\n"
      res << @comment.to_s
      res
    end

    def param_seq
      p = params.gsub(/\s*\#.*/, '')
      p = p.tr("\n", " ").squeeze(" ")
      p = "(" + p + ")" unless p[0] == ?(

      if (block = block_params)
        block.gsub!(/\s*\#.*/, '')
        block = block.tr("\n", " ").squeeze(" ")
        if block[0] == ?(
          block.sub!(/^\(/, '').sub!(/\)/, '')
        end
        p << " {|#{block}| ...}"
      end
      p
    end

    def add_alias(method)
      @aliases << method
    end
  end


  # Represent an alias, which is an old_name/ new_name pair associated
  # with a particular context
  class Alias < CodeObject
    attr_accessor :parent, :text, :old_name, :new_name, :comment
    
    def initialize(text, old_name, new_name, comment)
      super()
      @text = text
      @old_name = old_name
      @new_name = new_name
      self.comment = comment
    end

    def to_s
      "alias: #{self.old_name} ->  #{self.new_name}\n#{self.comment}"
    end
  end

  # Represent attributes
  class Attr < CodeObject
    attr_accessor :parent, :text, :name, :rw

    def initialize(text, name, rw, comment)
      super()
      @text = text
      @name = name
      @rw = rw
      self.comment = comment
    end

    def to_s
      "attr: #{self.name} #{self.rw}\n#{self.comment}"
    end

    def <=>(other)
      self.name <=> other.name
    end
  end

  # a required file

  class Require < CodeObject
    attr_accessor :parent, :name

    def initialize(name, comment)
      super()
      @name = name.gsub(/'|"/, "") #'
      self.comment = comment
    end

  end

  # an included module
  class Include < CodeObject
    attr_accessor :parent, :name

    def initialize(name, comment)
      super()
      @name = name
      self.comment = comment
    end

  end

end
