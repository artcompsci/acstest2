# We handle the parsing of options, and subsequently as a singleton
# object to be queried for option values
class Options

  require 'singleton'
  require 'getoptlong'

  include Singleton

  # files matching this pattern will be excluded
  attr_accessor :exclude

  # the name of the output directory
  attr_accessor :op_dir
  
  # the name to use for the output
  attr_reader :op_name

  # include private and protected methods in the
  # output
  attr_accessor :show_all
  
  # name of the file, class or module to display in
  # the initial index page (if not specified
  # the first file we encounter is used)
  attr_accessor :main_page

  # Don't display progress as we process the files
  attr_reader :quiet

  # description of the output generator (set with the <tt>-fmt</tt>
  # option
  attr_accessor :generator

  # and the list of files to be processed
  attr_reader :files

  # array of directories to search for files to satisfy an :include:
  attr_reader :rdoc_include

  # title to be used out the output
  #attr_writer :title

  # template to be used when generating output
  attr_reader :template

  # should diagrams be drawn
  attr_reader :diagram

  # should we draw fileboxes in diagrams
  attr_reader :fileboxes

  # include the '#' at the front of hyperlinked instance method names
  attr_reader :show_hash

  # image format for diagrams
  attr_reader :image_format

  # character-set
  attr_reader :charset

  # should source code be included inline, or displayed in a popup
  attr_reader :inline_source

  # should the output be placed into a single file
  attr_reader :all_one_file

  # the number of columns in a tab
  attr_reader :tab_width

  # include line numbers in the source listings
  attr_reader :include_line_numbers

  module OptionList

    OPTION_LIST = [
      [ "--all",           "-a",   nil,
        "include all methods (not just public)\nin the output" ],

      [ "--charset",       "-c",   "charset",
        "specifies HTML character-set" ],

      [ "--debug",         "-D",   nil,
        "displays lots on internal stuff" ],

      [ "--diagram",       "-d",   nil,
        "Generate diagrams showing modules and classes.\n" +
        "You need dot V1.8.6 or later to use the --diagram\n" +
        "option correctly. Dot is available from\n"+
        "http://www.research.att.com/sw/tools/graphviz/" ],

      [ "--exclude",       "-x",   "pattern",
        "do not process files or directories matching\n" +
        "pattern. Files given explicitly on the command\n" +
        "line will never be excluded." ],

      [ "--fileboxes",     "-F",   nil,
        "classes are put in boxes which represents\n" +
        "files, where these classes reside. Classes\n" +
        "shared between more than one file are\n" +
        "shown with list of files that sharing them.\n" +
        "Silently discarded if --diagram is not given\n" +
        "Experimental." ],

      [ "--fmt",           "-f",   "format name",
        "set the output formatter (see below)" ],

      [ "--help",          "-h",   nil,
        "you're looking at it" ],

      [ "--help-output",   "-O",   nil,
        "explain the various output options" ],

      [ "--image-format",  "-I",   "gif/png/jpg/jpeg",
        "Sets output image format for diagrams. Can\n" +
        "be png, gif, jpeg, jpg. If this option is\n" +
        "omitted, png is used. Requires --diagram." ],

      [ "--include",       "-i",   "dir[,dir...]",
        "set (or add to) the list of directories\n" +
        "to be searched when satisfying :include:\n" +
        "requests. Can be used more than once." ],

      [ "--inline-source", "-S",   nil,
        "Show method source code inline, rather\n" +
        "than via a popup link" ],

      [ "--line-numbers", "-N", nil,
        "Include line numbers in the source code" ],

      [ "--main",          "-m",   "name",
        "'name' will be the initial page displayed" ],

      [ "--one-file",      "-1",   nil,
        "put all the output into a single file" ],

      [ "--op",            "-o",   "dir",
        "set the output directory" ],

      [ "--opname",       "-n",    "name",
        "Set the 'name' of the output. Has no\n" +
        "effect for HTML." ],

      [ "--quiet",         "-q",   nil,
        "don't show progress as we parse" ],

      [ "--show-hash",     "-H",   nil,
        "A name of the form #name in a comment\n" +
        "is a possible hyperlink to an instance\n" +
        "method name. When displayed, the '#' is\n" +
        "removed unless this option is specified" ],

      [ "--tab-width",     "-w",   "n",
        "Set the width of tab characters (default 8)"],

      [ "--template",      "-T",   "template name",
        "Set the template used when generating output" ],

      [ "--title",         "-t",   "text",
        "Set 'txt' as the title for the output" ],

      [ "--version",       "-v",   nil,
        "display  RDoc's version" ],
    ]

    def OptionList.options
      OPTION_LIST.map do |long, short, arg,|
        [ long, 
          short, 
          arg ? GetoptLong::REQUIRED_ARGUMENT : GetoptLong::NO_ARGUMENT 
        ]
      end
    end


    def OptionList.strip_output(text)
      text =~ /^\s+/
      leading_spaces = $&
      text.gsub!(/^#{leading_spaces}/, '')
      $stdout.puts text
    end


    # Show an error and exit

    def OptionList.error(msg)
      $stderr.puts
      $stderr.puts msg
      $stderr.puts "\nFor help on options, try 'rdoc --help'\n\n"
      exit 1
    end

    # Show usage and exit
    
    def OptionList.usage(generator_names)
      
      puts
      puts(VERSION_STRING)
      puts

      name = File.basename($0)
      OptionList.strip_output(<<-EOT)
          Usage:

            #{name} [options]  [names...]

          Files are parsed, and the information they contain
          collected, before any output is produced. This allows cross
          references between all files to be resolved. If a name is a
          directory, it is traversed. If no names are specified, all
          Ruby files in the current directory (and subdirectories) are
          processed.

          Options:

      EOT

      OPTION_LIST.each do |long, short, arg, desc|
        opt = sprintf("%20s", "#{long}, #{short}")
        oparg = sprintf("%-7s", arg)
        print "#{opt} #{oparg}"
        desc = desc.split("\n")
        if arg.nil? || arg.length < 7
          puts desc.shift
        else
          puts
        end
        desc.each do |line|
          puts(" "*28 + line)
        end
        puts
      end

      puts "\nAvailable output formatters: " +
        generator_names.sort.join(', ') + "\n\n"

      puts "For information on where the output goes, use\n\n"
      puts "   rdoc --help-output\n\n"

      exit 0
    end

    def OptionList.help_output
      OptionList.strip_output(<<-EOT)
      How RDoc generates output depends on the output formatter being
      used, and on the options you give.

      - HTML output is normally produced into a number of separate files
        (one per class, module, and file, along with various indices). 
        These files will appear in the directory given by the --op
        option (doc/ by default).

      - XML output by default is written to standard output. If a
        --opname option is given, the output will instead be written
        to a file with that name in the output directory.

      - .chm files (Windows help files) are written in the --op directory.
        If an --opname parameter is present, that name is used, otherwise
        the file will be called rdoc.chm.

      For information on other RDoc options, use "rdoc --help".
      EOT
      exit 0
    end
  end

  # Parse command line options. We're passed a hash containing
  # output generators, keyed by the generator name

  def parse(argv, generators)
    old_argv = ARGV.dup
    begin
      ARGV.replace(argv)
      @op_dir = "doc"
      @op_name = nil
      @show_all = false
      @main_page = nil
      @exclude   = nil
      @quiet = false
      @generator_name = 'html'
      @generator = generators[@generator_name]
      @rdoc_include = []
      @title = nil
      @template = nil
      @diagram = false
      @fileboxes = false
      @show_hash = false
      @image_format = 'png'
      @inline_source = false
      @all_one_file  = false
      @tab_width = 8
      @include_line_numbers = false

      @charset = case $KCODE
                 when /^S/i
                   'Shift_JIS'
                 when /^E/i
                   'EUC-JP'
                 else
                   'iso-8859-1'
                 end

      go = GetoptLong.new(*OptionList.options)
      go.quiet = true

      go.each do |opt, arg|
	case opt
	when "--all"           then @show_all      = true
	when "--debug"         then $DEBUG         = true
	when "--main"          then @main_page     = arg
	when "--op"            then @op_dir        = arg
	when "--opname"        then @op_name       = arg
	when "--quiet"         then @quiet         = true
        when "--charset"       then @charset       = arg
        when "--exclude"       then @exclude       = Regexp.new(arg)
        when "--inline-source" then @inline_source = true
        when "--one-file"      then @all_one_file  = true
        when "--show-hash"     then @show_hash     = true
        when "--template"      then @template      = arg
        when "--title"         then @title         = arg
        when "--line-numbers"  then @include_line_numbers = true

        when "--diagram"
          check_diagram
          @diagram = true

        when "--fileboxes"
          @fileboxes = true if @diagram

	when "--fmt"
          @generator_name = arg.downcase
	  @generator = generators[@generator_name]
          if !@generator
            OptionList.error("Invalid output formatter")
          end

          if @generator_name == "xml"
            @all_one_file = true
            @inline_source = true
          end

        when "--help"      
          OptionList.usage(generators.keys)

        when "--help-output"      
          OptionList.help_output

        when "--image-format"
          if ['gif', 'png', 'jpeg', 'jpg'].include?(arg)
            @image_format = arg
          else
            raise GetoptLong::InvalidOption.new("unknown image format: #{arg}")
          end

        when "--include"   
          @rdoc_include.concat arg.split(/\s*,\s*/)

        when "--tab-width"
          begin
            @tab_width     = Integer(arg)
          rescue 
            $stderr.puts "Invalid tab width: '#{arg}'"
            exit 1
          end
          
	when "--version"
	  puts VERSION_STRING
	  exit
	end

      end

      @files = ARGV.dup

      @rdoc_include << "." if @rdoc_include.empty?

      check_files

      # If no template was specified, use the default
      # template for the output formatter

      @template ||= @generator_name

    rescue GetoptLong::InvalidOption, GetoptLong::MissingArgument => error
      OptionList.error(error.message)

    ensure
      ARGV.replace(old_argv)
    end
  end


  def title
    @title ||= "RDoc Documentation"
  end
  
  # Set the title, but only if not already set. This means that a title set from 
  # the command line trumps one set in a source file

  def title=(string)
    @title ||= string
  end


  private

  # Check that the right version of 'dot' is available.
  # Unfortuately this doesn't work correctly under Windows NT, 
  # so we'll bypass the test under Windows

  def check_diagram
    return if RUBY_PLATFORM =~ /win/

    ok = false
    ver = nil
    IO.popen("dot -V 2>&1") do |io|
      ver = io.read
      if ver =~ /dot\s+version(?:\s+gviz)?\s+(\d+)\.(\d+)/
        ok = ($1.to_i > 1) || ($1.to_i == 1 && $2.to_i >= 8)
      end
    end
    unless ok
      if ver =~ /^dot version/
        $stderr.puts "Warning: You may need dot V1.8.6 or later to use\n",
          "the --diagram option correctly. You have:\n\n   ",
          ver,
          "\nDiagrams might have strange background colors.\n\n"
      else
        $stderr.puts "You need the 'dot' program to produce diagrams.",
          "(see http://www.research.att.com/sw/tools/graphviz/)\n\n"
        exit
      end
#      exit
    end
  end
  
  # Check that the files on the command line exist
  
  def check_files
    @files.each do |f|
      stat = File.stat f rescue error("File not found: #{f}")
      error("File '#{f}' not readable") unless stat.readable?
    end
  end

  def error(str)
    $stderr.puts str
    exit(1)
  end

end
