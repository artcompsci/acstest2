# See README.
#
 

RDOC_VERSION = "0.9.0"

rcs = '$Date: 2003/03/10 03:50:33 $ $Revision: 1.70 $'.
  gsub(/\$/, '').
  sub(/Date: /, ': ').
  sub(/ Revision: (\S+)/) { "(#$1)" }

VERSION_STRING = %{RDoc V} + RDOC_VERSION + rcs


require 'rdoc/parsers/parse_rb.rb'
require 'rdoc/parsers/parse_c.rb'
require 'rdoc/parsers/parse_f95.rb'

require 'rdoc/parsers/parse_simple.rb'
require 'rdoc/options'

require 'rdoc/diagram'

require 'find'
require 'ftools'

# We put rdoc stuff in the RDoc module to avoid namespace
# clutter.
#
# ToDo: This isn't universally true.

module RDoc

  # Exception thrown by any rdoc error. Only the #message part is
  # of use externally.

  class RDocError < Exception
  end

  # Encapsulate the production of rdoc documentation. Basically
  # you can use this as you would invoke rdoc from the command
  # line:
  #
  #    rdoc = RDoc::RDoc.new
  #    rdoc.document(args)
  #
  # where _args_ is an array of strings, each corresponding to
  # an argument you'd give rdoc on the command line. See rdoc/rdoc.rb 
  # for details.
  
  class RDoc

    ##
    # This is the list of output generators that we
    # support
    
    Generator = Struct.new(:file_name, :class_name, :key)
    
    GENERATORS = {}
    $:.collect {|d|
      File::expand_path(d)
    }.find_all {|d|
      File::directory?("#{d}/rdoc/generators")
    }.each {|dir|
      Dir::entries("#{dir}/rdoc/generators").each {|gen|
        next unless /(\w+)_generator.rb$/ =~ gen
        type = $1
        unless GENERATORS.has_key? type
          GENERATORS[type] = Generator.new("rdoc/generators/#{gen}",
                                           "#{type.upcase}Generator".intern,
                                           type)
        end
      }
    }                                                    

    #######
    private
    #######

    ##
    # Report an error message and exit
    
    def error(msg)
      raise RDocError.new(msg)
    end
    
    ##
    # Create an output dir if it doesn't exist. If it does
    # exist, but doesn't contain the flag file <tt>created.rid</tt>
    # then we refuse to use it, as we may clobber some
    # manually generated documentation
    
    def setup_output_dir(op_dir)
      flag_file = File.join(op_dir, "created.rid")
      if File.exist?(op_dir)
        unless File.directory?(op_dir)
          error "'#{op_dir}' exists, and is not a directory" 
        end
        unless File.file?(flag_file)
          error "\nDirectory #{op_dir} already exists, but it looks like it\n" +
            "isn't an RDoc directory. Because RDoc doesn't want to risk\n" +
            "destroying any of your existing files, you'll need to\n" +
            "specify a different output directory name (using the\n" +
            "--op <dir> option).\n\n"
        end
      else
        File.makedirs(op_dir)
      end
      File.open(flag_file, "w") {|f| f.puts Time.now }
    end
    

    # Given a list of files and directories, create a list
    # of all the Ruby files they contain. 
    
    def normalized_file_list(options, *relative_files)
      file_list = []

      relative_files.each do |rel_file_name|

        case type = File.ftype(rel_file_name)
        when "file"
          file_list << rel_file_name
        when "directory"
          next if options.exclude && options.exclude =~ rel_file_name
          Find.find(rel_file_name) do |fn|
            next if options.exclude && options.exclude =~ fn
            next unless ParserFactory.can_parse(fn)
            next unless File.file?(fn)
            
            file_list << fn.sub(%r{\./}, '')
          end
        else
          raise RDocError.new("I can't deal with a #{type} #{rel_file_name}")
        end
      end
      file_list
    end

    # Parse each file on the command line, recursively entering
    # directories

    def parse_files(options)
 
      file_info = []

      files = options.files
      files = ["."] if files.empty?

      file_list = normalized_file_list(options, *files)

      file_list.each do |fn|
        $stderr.printf("\n%35s: ", File.basename(fn)) unless options.quiet
        
        content = File.open(fn, "r") {|f| f.read}

        top_level = TopLevel.new(fn)
        parser = ParserFactory.parser_for(top_level, fn, content, options)
        file_info << parser.scan
      end

      file_info
    end


    public

    ###################################################################
    #
    # Format up one or more files according to the given arguments.
    # For simplicity, _argv_ is an array of strings, equivalent to the
    # strings that would be passed on the command line. (This isn't a
    # coincidence, as we _do_ pass in ARGV when running
    # interactively). For a list of options, see rdoc/rdoc.rb. By
    # default, output will be stored in a directory called +doc+ below
    # the current directory, so make sure you're somewhere writable
    # before invoking.
    #
    # Throws: RDocError on error

    def document(argv)

      TopLevel::reset

      options = Options.instance
      options.parse(argv, GENERATORS)
    
      file_info = parse_files(options)

      gen = options.generator
      
      $stderr.puts "\nGenerating #{gen.key.upcase}..." unless options.quiet
      
      require gen.file_name
      
      gen_class = Generators.const_get(gen.class_name)
      
      unless file_info.empty?
        gen = gen_class.for(options)

        pwd = Dir.pwd

        unless options.all_one_file
          setup_output_dir(options.op_dir)
          Dir.chdir(options.op_dir)
        end

        begin
          Diagram.new(file_info, options).draw if options.diagram
          gen.generate(file_info)
        ensure
          Dir.chdir(pwd)
        end

      end
    end
  end
end

