require "rdoc/parsers/parse_simple"

module RDoc

  # A parser is simple a class that implements
  #
  #   #initialize(file_name, body, options)
  #
  # and
  #
  #   #scan
  #
  # The initialize method takes a file name to be used, the body of the
  # file, and an RDoc::Options object. The scan method is then called
  # to return an appropriately parsed TopLevel code object.

  # The ParseFactory is used to redirect to the correct parser given a filename
  # extension. This magic works because individual parsers have to register 
  # themselves with us as they are loaded in. The do this using the following
  # incantation
  #
  #
  #    require "rdoc/parsers/parsefactory"
  #    
  #    module RDoc
  #    
  #      class XyzParser
  #        extend ParseFactory                  <<<<
  #        parse_files_matching /\.xyz$/        <<<<
  #    
  #        def initialize(file_name, body, options)
  #          ...
  #        end
  #    
  #        def scan
  #          ...
  #        end
  #      end
  #    end



  module ParserFactory

    @@parsers = []

    Parsers = Struct.new(:regexp, :parser)

    # Record the fact that a particular class parses files that
    # match a given extension

    def parse_files_matching(regexp)
      @@parsers.unshift Parsers.new(regexp, self)
    end

    # Return a parser that can handle a particular extension

    def ParserFactory.can_parse(file_name)
      @@parsers.find {|p| p.regexp.match(file_name) }
    end

    # Find the correct parser for a particular file name. Return a 
    # SimpleParser for ones that we don't know

    def ParserFactory.parser_for(top_level, file_name, body, options)
      parser_description = can_parse(file_name)
      if parser_description
        parser = parser_description.parser 
      else
        parser = SimpleParser
      end
      parser.new(top_level, file_name, body, options)
    end
  end
end
