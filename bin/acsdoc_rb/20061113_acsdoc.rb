#!/usr/bin/ruby
#
# acsdoc2.rb
#
# This script takes a number of files and make HTML or LaTeX files from them. 
# usage:  ruby acsdoc.rb [--tolatex]   [file]...
#
# 2004/3/22 Major rewrite to make it more easily extensible.
#
# Basic change: all functions are changed to (if not already designed
# that way) taking string(s) as an argument and output the processed
# string as an argument
#
# 2005/11/17 created acsdoc2.rb
# test for more change
# more changes
#
#==============================================================================
#$DEBUG=1
module Rdoctotex

  @@latexwordreplace=[
    [/(^|\W)\+([a-zA-Z_]+)\+($|\W)/,"{\\tt", "}"],
    [/(^|\W)\*(\w+)\*($|\W)/,"{\\bf", "}"],
    [/(^|\W)\\_(\w+)\\_($|\W)/,"{\\it", "}"]
  ]
  
  @@latextagreplace=[
    ["<tt>","</tt>","{\\tt", "}"],
    ["<b>","</b>","{\\bf", "}"],
    ["<em>","</em>","{\\it", "}"],
    ["<i>","</i>","{\\it", "}"],
    ["<tex>","</tex>","", ""]
  ]
  
  @@header=[
    "part","chapter","section","subsection","subsubsection",
    "subsubsubsection"]

  @@latexlisttypes=[
    ["paragraph","paragraph"],
    ["ulist*","itemize"],
    ["ulist-","itemize"],
    ["nlist", "enumerate"],
    ["verbatim","verbatim"]]

  @@imglinkcount = 0
  @@latexscalingforimage = 0.5

  @@charstotexmath =[
    [/\$/,"\\$"],
    [/\\</,"$<$"],
    [/\\>/,"$>$"],
    [/\\([^\$])/,'$\\backslash$\1'],
    [/\{/,"\\{"],
    [/\}/,"\\}"],
    ['&','\\\\&'],
    [/#/,"\\#"],
    [/~/,"$\\sim$"],
    [/\_/,"\\_"],
    [/\%/,"\\%"],
    [/\^/,"$\\hat{\\ }$"]]

  @@basic_preambles_for_tex = "\\documentclass{book}\n\\usepackage{graphicx}"
  @@additional_preambles_for_tex = ""
  @@additional_commands_for_tex = ""

  def escapetexspecialcharacters(instring)
    s = instring
    @@charstotexmath.each{|x|
      s=s.gsub(x[0],x[1])}
    # additional change for ">"...
    s=s.gsub(/((\\<\w*)|(\s[0-9A-Za-z_`"-+]+)|(\s+))>/){$1+"$>$"}
    s
  end
  
  def latexwordmarkup(instr)
    @@latexwordreplace.each do |x| instr.gsub!(x[0]) do |word|
	$1 + x[1]+ " " + $2 +x[2] + $3
      end
    end
    instr
  end

  def latex_process_wordmarkup(instring,dirname)
    instring = instring.split("\n") if instring.class != Array
    ostring = []
    inlisting = false
    while s=instring.shift
      inlisting = true if s =~ /\\begin\{verbatim\}/
      inlisting = false if s =~ /\\end\{verbatim\}/
      if inlisting
        ostring.push(s)
      else
        ostring.push(latexwordmarkup(s))
      end
    end
    ostring
  end

  def tagmarkup(instr)
    @@latextagreplace.each do |x| 
      instr.gsub!(x[0]) { |word|x[2]+ " " }
      instr.gsub!(x[1]) { |word|x[3] }
    end
    instr
  end

  def process_tagmarkup(instring,dirname)
    instring = instring.split("\n") if instring.class != Array
    ostring = []
    inlisting = false
    while s=instring.shift
      inlisting = true if s =~ /\\begin\{verbatim\}/
      inlisting = false if s =~ /\\end\{verbatim\}/
      if inlisting
        ostring.push(s.gsub(/\\<(tex|web)>/){"<"+$1+">"})
      else
        ostring.push(tagmarkup(s))
      end
    end
    ostring
  end

  def gettexauxlabel(dirname,label)
    defaultlabel=dirname+"/"+label
    dirname=dirname.gsub(/\\/,"")
    label=label.gsub(/\\/,"")
    aux_file_list=Dir[dirname+"/*.aux"].delete_if{|x| x=~ /tmp\.aux$/}
    if aux_file_list.length > 1
      STDERR.print "#{$0} found too many .aux files in directory #{dirname}\n"
      STDERR.print "   Please remove all but one which is actually used.\n"
      STDERR.print "   Files found are: #{aux_file_list.join(" ")}\n"
      exit(-1)
    elsif aux_file_list.length == 0
      return defaultlabel
    end
    f=open(aux_file_list[0],"r")
    while s = f.gets
      if s.index("newlabel{#{label}")
        newlabel=s.split("{")[3]
        newlabel = newlabel[0,newlabel.length-1]
        newtag=$volindex[dirname[3,dirname.length]]
        newtag =  newtag ? "v"+newtag.to_s : dirname+"."
        return newtag+newlabel
      end
    end
    return defaultlabel
  end

  def process_refmarkup(instring)
    ostring = []
    instring.each{|x| 
      y=x.gsub(/ref\(sect\:((\w|\d|\:)*)\)/){|s|  
        labelbody = $1.gsub(/\\/,"")
        print "LABELY = ",labelbody, "\n" if $DEBUG
        if @@latex_section_table[labelbody]
          labelbody =  @@latex_section_table[labelbody] 
        end
	"\\ref{sect:"+ labelbody.to_s + "}"
      }
#      z=y.gsub(/ref\(((\w|\d|\:)*)\)/){|s|  "\\ref{"+ $1 + "}"}
      z=y.gsub(/ref\(((\w|\d|[:_#.\/\\])*)\)/){|s| 
        label = $1.gsub(/\\/,"")
        print "LABEL = ",label, "\n" if $DEBUG
        if label =~ /(.*)\#(.*)/
            dirname = $1
          reallabel = $2
          tag=gettexauxlabel(dirname,reallabel)
        else
          tag = "\\ref{#{label}}"
        end
        tag
      }

      ostring.push(z)
    }
    ostring
  end

  def process_tex_equations_for_latex(s,instring)
    eqtype = s
    texcode = "<tex>\n\\begin{#{eqtype}}\n"
    while (s = instring.shift ) =~ /\S/
      texcode += s + "\n"
      if s == nil 
	raise "End of file reached while searching for newline: #{$infile}"
      end
    end
    texcode += "\\end{#{eqtype}}\n</tex>\n"
  end


  def latex_process_tex_equations(instring)
    ostring=[]
    while s = instring.shift
      if s =~ /^\s*:(equation|eqnarray):\s*$/
	ostring.push(process_tex_equations_for_latex($1,instring))
      else
	ostring.push(s)
      end
    end
    ostring
  end



  def latex_process_tex_mathmarkup(instring)
    ostring=[]
    while s = instring.shift
      if s !~ /^(\s+)(.+)<\$(.+?)\$>/
        s.gsub!(/<\$(.+?)\$>/){"<tex>$"+$1+"$</tex>"}
      end
      ostring.push s
    end
    ostring
  end

  def postprocess_footnotes_in_figure_captions_old(instring)
    ins = instring.split(/\n[ \t]*\n/)
    ins.each{|x| p x}
    footnoteregexp = /\\footnote\{\\tt ([0-9,a-z,A-Z,#,-,_,\/,:,.,\$,\\]*)\}/
    ins.map{|x|
      if x =~/^\s*\:figure\:/
        footnotes=[]
        num = 0
        print "figure found\n"
        p x
        s = x
        while  s =~ footnoteregexp
          num += 1
          s.sub!(footnoteregexp,"\\protect \\footnotemark[#{num}]")
          footnotes.push($1)
        end
        num = 0
        x = s + "\n"+"\n"+ footnotes.map{|x| 
          num += 1
          "<tex>\\footnotetext[#{num}]{\\tt #{x}}</tex>\n"
        }.join("\n")
      end
      x
    }.join("\n\n")
  end
  def postprocess_footnotes_in_figure_captions(instring)
#    ins = instring.split(/\n[ \t]*\n/)
    ins = instring.split(/(\n[ \t]*\n)/)
#    ins.each{|x| p x}
    footnoteregexp = /\\footnote\{\\tt ([0-9,a-z,A-Z,#,-,_,\/,:,.,\$,\\]*)\}/
    ins.map{|x|
      if x =~/^\s*\:figure\:/
        footnotes=[]
        num = 1
        print "figure found\n"
        p x
        s = x
        while  s =~ footnoteregexp
          num += 1
          s.sub!(footnoteregexp,"\\protect \\footnotemark[#{num}]")
          footnotes.push($1)
        end
        num = 1
        x = s + "\n"+ footnotes.map{|x| 
          num += 1
          "<tex>\\footnotetext[#{num}]{\\tt #{x}}</tex>"
        }.join("\n")+"\n"
        print x

      end
      x
    }.join
  end
  def latex_process_tex_weblinks(instring)
    ins = instring.join("\n")
    ostring=ins.gsub(/<web>(.+?)<\/web>/m){ linktext = $1
      if linktext =~ /(.*)\|(.*)/m
	url=escapetexspecialcharacters($1)
	text=$2
	s="<tex>{\\it #{text}\\footnote{\\tt #{url}}}</tex>"
      else
	s="<tex>{\\it #{linktext}</tex>"
      end
      s
    }
    postprocess_footnotes_in_figure_captions(ostring).split("\n")
#    ostring.split("\n")
  end


  def latex_copy_figure_file(figurefilename,dirname, figure_number)
    imgbase =".imgs/"
    imgdir =  imgbase 
    Dir.mkdir(imgdir) unless File.exist?(imgdir)
    imgname = imgbase + figure_number.to_s + "_" +
      File.basename(figurefilename) + ".eps"
    p imgname  if $DEBUG
    if figurefilename =~ /eps$/ 
      system "/bin/cp -p #{dirname}/#{figurefilename} #{imgname}"
    else
      system "convert #{dirname}/#{figurefilename} #{imgname}"
    end
    system "mv -f #{imgname}.0 #{imgname}"if File.exist?(imgname + ".0")
    imgname
  end

@@latex_figure_number = 0
  def latex_process_figures(s,instring,dirname)
    @@latex_figure_number += 1

    a=s.chomp.split
    figurefilename,size,label = a[1],a[2],a[3]
    caption = ""
    footnotes= ""
    while (s = instring.shift ) =~ /\S/
      if s =~ /\\footnotetext/
        footnotes += s + "\n"
      else
        caption += s + "\n"
      end
      if s == nil 
	raise "End of file reached while searching for newline: #{$infile}"
      end
    end
    filename_to_link = latex_copy_figure_file(figurefilename,dirname,
					      @@latex_figure_number)
    texstring = <<-END

<tex>
\\begin{figure}
\\begin{minipage}{\\columnwidth}
\\begin{center}
\\renewcommand{\\thefootnote}{\\fnsymbol{footnote}}
\\renewcommand{\\thempfootnote}{\\fnsymbol{mpfootnote}}
    \\includegraphics[width=#{size}]{#{filename_to_link}}
\\caption{#{caption}}
#{footnotes}
\\label{#{label}}
\\end{center}
\\end{minipage}
\\end{figure}
</tex>
END
  end


  def latex_find_and_process_figures(instring,dirname)
    ostring=[]
    while s = instring.shift
      p s  if $DEBUG
      if s =~ /^\s*:figure:\s*/
	ostring.push(latex_process_figures(s,instring,dirname))
      else
	ostring.push(s)
      end
    end
    ostring
  end

  @@latex_section_number = 0
  @@latex_section_table={}
  
  def latex_process_headers(instring)
    
    nosectionnumber = nil
    
    ostring=[]
    afterverbatim = nil
    inabstract = nil
    labeltext=nil
    while s=instring.shift
      header_candidate =s.split[0] 
      if /^=+\s/ =~ s
	header_text = s.sub(/=+/," ")
	while /^\s+$/ =~ (s = instring.shift )
	  header_text += s + " "
	end
	p header_text if $DEBUG
	if header_text =~ /^\s*Abstract\s*$/ then
	  inabstract = true
	  header = "\\begin{abstract}"
	else
	  header = ""
	  if inabstract 
	    header = "\\end{abstract}\n\n" 
	    inabstract = nil
	  end
	  sectiontype= nosectionnumber ? "*":""
	  header+= "\\"+@@header[header_candidate.length]+sectiontype+"{" +
	    header_text + "}"
	  if nosectionnumber
	    header+= "\n\\addcontentsline{toc}{" +
	      @@header[header_candidate.length]+"}{" +
	      header_text + "}"
	    nosectionnumber=nil
	  end
	end
	ostring.push(header)
	@@latex_section_number+=1
#	print "label and section header ", labeltext, header_text,"\n"
	ss = labeltext ? labeltext : header_text
#	p ss
	@@latex_section_table.store(ss, @@latex_section_number)
	ostring.push("\\label{sect:#{@@latex_section_number}}")
	instring.unshift(s)
	labeltext=nil
      elsif /^---*$/ =~ s
	if afterverbatim
	  ostring.push("\\hrule\n\n\\bigskip\n\n")
	else
	  ostring.push("\n\\bigskip\n\n\\hrule\n\n")
	end
	afterverbatim = nil
      elsif /^\s*:nosectionnumber:\s*$/ =~ header_candidate
	nosectionnumber = true
      elsif /^\s*:label:\s*$/ =~ header_candidate
	labeltext=s.split[1].gsub(/\\/,"")
        labeltext = "sect:"+labeltext if labeltext !~ /^sect/
	ostring.push("\\label{#{labeltext}}")
      else
	ostring.push(s)
      end
      if /\\end\{verbatim/  =~ s
	afterverbatim = 1  
      elsif /\S+/ =~ s
	afterverbatim = nil
      end
    end
    ostring
  end

  def process_include(instring)
    ostring=[] 
    while s=instring.shift
      if /^(\s*)\:include\:\s*(\S+)$/  =~ s
        indent = $1
        infile= open($2,"r")
	while ss=infile.gets
	  ostring.push(indent+ss.chomp)
	end
	infile.close
      else
	ostring.push(s)
      end
    end
    ostring
  end
  
  def latex_process_link(instring)
    ostring=[] 
    while s=instring.shift
      if /(^|\s)link\:(\S+)/  =~ s
	imglinkfile = $2
	imgbase =".imgs/"
	imgdir =  imgbase
	epsfilename = @@imglinkcount.to_s+".eps"
	Dir.mkdir(imgdir) unless File.exist?(imgdir)
	print "convert  #{imglinkfile} #{imgdir}#{epsfilename}\n"
	system "convert  #{imglinkfile} #{imgdir}#{epsfilename}"
	s.sub!(/(^|\s)link\:(\S+)/,
	       "\n\\scalebox{#{@@latexscalingforimage}}{\\includegraphics{#{imgbase+epsfilename}}}\n")
	@@imglinkcount+=1
      end
      ostring.push(s)
    end
    ostring
  end

  @@intex_state = 0

  def process_tex_special_chars(instring)
    s = instring
    ostring =""
    while s.length > 0
#
# The algorithm below can be simplified, but not done so yet -- JM
# 
      if @@intex_state == 0
	texloc = /<tex>/ =~ s
	if texloc
	  ostring+=escapetexspecialcharacters(s[0,texloc])+"<tex>"
	  @@intex_state = 1
	  s = s[texloc+5,s.length]
	else
	  ostring += escapetexspecialcharacters(s)
	  s=""
	end
      else
        deepertex = /<tex>/ =~ s
	texloc = /<\/tex>/ =~ s
        if deepertex 
          @@intex_state += 1  if (texloc && (deepertex < texloc)) || (! texloc)
        end
            
	if texloc
	  ostring+=s[0,texloc]+"</tex>"
	  @@intex_state -= 1
	  s = s[texloc+6,s.length]
	else
	  ostring += s
	  s=""
	end
      end
    end
    ostring
  end

  def latex_process_single_paragraphs_lists_etc(instring,indent,type,new,vlimit)
    instring = instring.split("\n") if instring.class != Array

    s_prev = ""
    ostr=[]
    ostr.push(":modestart "+@@latexlisttypes[type][1]+":")  if new
    intex = nil
    #
    # intex is used to suppress formatting. As you can see from the code below, 
    # suppression can take place only if "<tex>" appears as single item in one 
    # line, and suppression stops only of "</tex>" appears as single item in one
    # line. So if you use them in a more complex ways, it might cause strange 
    # problems.
    #
    new_indent = 0
    while s=instring.shift
      header_candidate =s.split[0] 
      new_item = nil
      new_type = 1
      @@intex_state = 1 if s == "<tex>" 
      @@intex_state = 0 if s == "</tex>" 
      if @@intex_state == 1
	new_type = type
	new_indent = indent
	s1 = s
        if type == 4
          new_type=0
          new_indent=0
        end
      elsif (header_candidate =~ /^(\*|\-|\d+\.)$/)
        new_type = 1+[/\*/,/\-/,/\d+\./].collect{|x|
          x=~ header_candidate}.index(0)
        s1 = s.sub(/\S+\s/){|x| " "*x.length} 
        new_indent = /\S/ =~ s1
        new_item = 1
      else
        new_indent = /\S/ =~ s
        if /^\s*$/ =~s 
          new_indent = indent 
          ostr.push(":modestart paragraph:")if type != 4
        end
        s1=s
      end
      if type == 4 and /^\s+/ =~s 
        s1 = s
        new_type=4
        new_item = nil
      end
      if new_indent > indent and new_item == nil
	new_type = 4 
      end
      if new_indent > indent
	instring.unshift(s)
	new=1
	new = nil if new_type == type and type == 4 
	vlimit = indent+1 if new and new_type == 4
	if new 
	  ostr+= latex_process_single_paragraphs_lists_etc(instring,new_indent,
						     new_type,new,
						     vlimit)
	else
	  ostr.push s1
	  instring.shift
	end
      elsif new_indent == indent
	if new_item
	  if new_type != type
	    ostr.push(":modeend "+@@latexlisttypes[type][1]+":")
	    instring.unshift(s)
	    ostr+= latex_process_single_paragraphs_lists_etc(instring,new_indent,
						       new_type,1,vlimit)
	  end
	  ostr.push(":item:") if new_type < 4
	end
	ostr.push s1
      else
	if type == 4 and new_type==4 and new_indent > vlimit
	  indent = new_indent
	  ostr.push s1
	else
	  ostr.push(":modeend "+@@latexlisttypes[type][1]+":")
	  instring.unshift(s)
	  return ostr
	end
      end
      s_prev = s
    end	
    ostr
  end

  def latex_post_process_paragraphs(instring)
    ostr=[]
    inlisting = false
    while s=instring.shift
      if s=~ /\:modestart (\S+)\:$/
        ostr.push "\\begin{#{$1}}" if $1 != "paragraph"
        inlisting = ($1 == "verbatim") 
      elsif s=~ /\:modeend (\S+)\:$/
        inlisting = false
        ostr.push "\\end{#{$1}}" if $1 != "paragraph"
      elsif s=~ /\:item\:$/
        ostr.push "\\item " if $1 != "paragraph"
      else
        if $DEBUG
          p s 
          p process_tex_special_chars(s)
          p inlisting
        end
        ostr.push(inlisting ? s: process_tex_special_chars(s))
      end
    end
    ostr
  end


  def post_process_verbatim(instring)
    ostr=[]
    while s=instring.shift
      if s =~ /\\end\{verbatim\}/
#	unless (last = ostr.pop) =~ /^\s*$/
	unless (last = ostr.pop) =~ /^$/
	  ostr.push last
	end
      end
      ostr.push s
    end
    ostr
  end


  def process_toc_latex(instring)
    ostring=[]
    while s=instring.shift
      if /^(\s*):tableofcontents:/ =~ s
	ostring.push("\\newpage\n\\tableofcontents\n\\newpage\n")
      else
	ostring.push(s)
      end
    end
    ostring
  end

  def process_ctrls(instring)
    ostring=[]
    while s=instring.shift
      ostring.push(s.gsub(/[[:cntrl:]]/,""))
    end
    ostring
  end
  

  
  
  def convert_to_latex(instring,dirname)
    s=process_include(instring)
    s=latex_process_tex_mathmarkup(s)
    s=latex_process_tex_equations(s)
#    print s.join("\n").split("\n").join("|\n")
    # in the next method somehow blanck line changed...
    s=latex_process_tex_weblinks(s)
    s=latex_find_and_process_figures(s,dirname)

    s=s.join("\n").split("\n")

    s=latex_process_single_paragraphs_lists_etc(s,0,0,1,0)

    s=latex_post_process_paragraphs(s)

    s=post_process_verbatim(s)
    s=latex_process_link(s)
    s=latex_process_wordmarkup(s,dirname)
    s=latex_process_headers(s)
    s=process_refmarkup(s)
    s=process_toc_latex(s)
    s=process_ctrls(s)
    s = process_tagmarkup(s,dirname).join("\n")
    s= <<-END_TEXSOURCE
    #{@@basic_preambles_for_tex}
    #{@@additional_preambles_for_tex}
    \\begin{document}
       #{@@additional_commands_for_tex}
       #{s}
    \\end{document}
    END_TEXSOURCE
  end

end



module Acsdoc
  include Rdoctotex

  @@auxfilename = ".acsdoc.aux"
  @@volindexfilename = "../volumetable.dat"

  @@prompt = "|gravity> "

  @@imgcount = 0
  @@additional_preambles_for_inline_tex = ""
  @@additional_commands_for_inline_tex = ""

  @@outputcount = 0
  @@reuseoutput = nil

  @@oldoutputs={}
  @@section_label_table={}

  @@section_counters=[]
  @@wordreplace=[
    [/(^|\W)\+([a-zA-Z_]+)\+($|\W)/,"<tt>", "</tt>"],
    [/(^|\W)\*(\w+)\*($|\W)/,"<b>", "</b>"],
    [/(^|\W)\_(\w+)\_($|\W)/,"<i>", "</i>"]
  ]
  
  @@tagreplace=[
    ["<tt>","</tt>","{\\tt", "}"],
    ["<b>","</b>","{\\bf", "}"],
    ["<em>","</em>","{\\it", "}"],
    ["<i>","</i>","{\\it", "}"],
    ["<tex>","</tex>","", ""]
  ]
  

  def wordmarkup(instr)
    @@wordreplace.each do |x| instr.gsub!(x[0]) do |word|
	$1 + x[1]+ " " + $2 +x[2] + $3
      end
    end
    instr
  end

  def process_wordmarkup(instring)
    instring = instring.split("\n") if instring.class != Array
    ostring = []
    instring.each{|s| ostring.push(wordmarkup(s))}
    ostring.join("\n")
  end



  def process_link(instring)
    instring = instring.split("\n") if instring.class != Array
    ostring=[] 
    while s=instring.shift
      if /(^|\s)link\:(\S+)/  =~ s
	imglinkfile = $2
	s.sub!(/(^|\s)link\:(\S+)/,
	       "\n<IMG src=#{imglinkfile}>\n")
	@@imglinkcount+=1
      end
      ostring.push(s)
    end
    ostring.join("\n")
  end



  @@listtypes=[
    ["paragraph","p"],
    ["ulist*","ul"],
    ["ulist-","ul"],
    ["nlist", "ol"],
    ["verbatim","pre"]]

  @@htmllisttypes={
    "paragraph"=>"p",
    "itemize"=>"ul",
    "enumerate"=> "ol",
    "verbatim"=>"pre"}


  def process_tex_specials(s)
    s.gsub(/\\<tex>/,"&lt;tex>").gsub(/<\/tex>/,"&lt;/tex>")
  end
  def process_tex_specials_in_listing(s)
    s.gsub(/</,"&lt;")
  end
  def process_single_paragraphs_lists_etc(instring,indent,type,new,vlimit)
    instring = instring.split("\n") if instring.class != Array
    s_prev = ""
    ostr=[]
    ostr.push("<"+@@listtypes[type][1]+">")  if new and (type >0)

    intex = nil

#
# intex is used to suppress formatting. As you can see from the code below, 
# suppression can take place only if "<tex>" appears as single item in one 
# line, and suppression stops only of "</tex>" appears as single item in one
# line. So if you use them in a more complex ways, it might cause strange 
# problems.
#
    while s=instring.shift
      header_candidate =s.split[0] 
      new_item = nil
      new_type = 0
      if @@intex_state == 1
	new_type = type
	new_indet = indent
	s1 = s
      elsif (/^(\*|\-|\d+\.)$/ =~ header_candidate) 
	new_type = 1+[/\*/,/\-/,/\d+\./].collect{
	  |x| x=~ header_candidate}.index(0)

	s1 = s.sub(/\S+\s/){|x| " "*x.length} 
	new_indent = /\S/ =~ s1
	new_item = 1
      else
	new_indent = /\S/ =~ s
	new_indent = indent if /^\s*$/ =~s 
	s1=s
      end
      if type == 4 and /^\s+/ =~s 
	s1 = s
	new_type=4
	new_item = nil
      end
      if type == 4 and s=="" 
	s1 = s
	new_type=0
        new_indent=0
	new_item = nil
      end
      if new_indent > indent and new_item == nil
	new_type = 4 
      end
      s1= process_tex_specials(s1) unless new_type == 4
      if new_indent > indent
	instring.unshift(s)
	new=1
	new = nil if new_type == type and type == 4 
	vlimit = indent+1 if new and new_type == 4
	if new 
	  ostr+= process_single_paragraphs_lists_etc(instring,new_indent,
						     new_type,new,
						     vlimit)
	else
	  ostr.push s1
	  instring.shift
	end
      elsif new_indent == indent
	if new_item
	  if new_type != type
	    ostr.push("</"+@@listtypes[type][1]+">")
	    instring.unshift(s)
	    ostr+= process_single_paragraphs_lists_etc(instring,new_indent,
						       new_type,1,vlimit)
	  end
	  ostr.push("<li> ") if new_type < 4
	end
        ostr.push "<p>\n" if new_type == 0 and type==0 and s_prev == ""
	ostr.push s1
      else
	if type == 4 and new_type==4 and new_indent > vlimit
	  indent = new_indent
	  ostr.push s1
	else
	  ostr.push("</"+@@listtypes[type][1]+">")
	  instring.unshift(s)
	  return ostr
	end
      end
      s_prev = s
    end	
    ostr
  end



  def post_process_paragraphs(instring)
    ostr=[]
    inlisting = false
    while s=instring.shift
      if s=~ /\:modestart (\S+)\:$/
        ostr.push "<#{@@htmllisttypes[$1]}>"
        inlisting = ($1 == "verbatim") 
      elsif s=~ /\:modeend (\S+)\:$/
        inlisting = false
        ostr.pop  if ($1 == "verbatim") and (ostr.last == "")
        ostr.push "</#{@@htmllisttypes[$1]}>"
      elsif s=~ /\:item\:$/
        ostr.push "<li> " if $1 != "paragraph"
      else
        ostr.push(inlisting ? process_tex_specials_in_listing(s): process_tex_specials(s))
#        ostr.push(s)
      end
    end
    p ostr if $DEBUG
    ostr
  end



  def setreuseoutput(value)
    @@reuseoutput = value
  end

  def readcommandfile(fname, dirname)
    fid = fname.to_i
    @@outputcount = fid if fid >   @@outputcount 
    f=open(dirname+"/"+fname,"r")
    while s = f.gets
      p s if $DEBUG
      if s.chomp == "COMMAND"
	command = f.gets.chomp
      end
      if s.chomp == "OUTPUT"
	outputstr=""
	while ss = f.gets
	  outputstr += ss
	end
      end
    end
    
    @@oldoutputs[command]=outputstr
  end
    
  

  @@commandoutputdir= ".acsdoc.commandoutdir"
  def readin_commandoutputs
    return unless File.exist?(@@commandoutputdir)
    Dir.entries(@@commandoutputdir).each{|fname|
      unless fname == "." or  fname == ".."
	readcommandfile(fname, @@commandoutputdir)
      end
    }    
  end

  @@verbatim_separator = "---\n"
  @@verbatim_pre_separator = "<tex>{\\parskip 0pt</tex>\n\n---\n\n"
  @@verbatim_post_separator = "---\n<tex>}</tex>\n\n"

  
  def reset_verbatim_separator
    @@verbatim_separator = ""
  @@verbatim_pre_separator = ""
  @@verbatim_post_separator = ""
  end
    
#
# takes a single string which contains a command
# and creates processed string which contain output
#
  def add_output(s,  dirname, tag,fname,lineno,saveresult)
    ostring = "";
    a = s.split
    indent = s.index(tag) 
    noout = false
    noout = true if tag == ":command:" 
    nooutput = false
    nooutput = true if tag == ":commandnooutput:" 
    tmpname = ".acsdoc.command-out"
    tmpcommand = ".acsdoc.command-file"
    prompt = " "* indent + @@prompt
    commandline = a[1..a.size].join(" ").chomp
    ostring = ostring +  @@verbatim_pre_separator     unless ( noout or @previous_is_command )
      fullcommand  = "cd #{dirname}; #{commandline}" 
    unless noout or nooutput
      fullcommand  = "cd #{dirname}; (#{commandline})>&  #{tmpname}" 
      print "Generating output of \"#{commandline}\"...\n" 
    else
      print "Executing command \"#{commandline}\"...\n" 
    end
    reused = nil
    reusedcommandid = commandline+"#"+fname+"-"+lineno.to_s
    if @@reuseoutput && saveresult
      if reusedoutput = @@oldoutputs[reusedcommandid]
	reused = true
      end
    end
    if reused
      print "Output reused\n"
      open(dirname+"/"+tmpname,"w"){|f| f.print reusedoutput}
    else
      open(tmpcommand,"w+"){ |f|  f.print fullcommand + "\n"}
      system("cat  #{tmpcommand}") if $DEBUG
      system("csh -f #{tmpcommand}");
      system "sync; sleep 1"
      @@outputcount += 1
      Dir.mkdir(@@commandoutputdir) unless File.exist? @@commandoutputdir
      outfile = open(@@commandoutputdir+"/"+ @@outputcount.to_s,"w")
      outfile.print "COMMAND\n"
      outfile.print reusedcommandid+"\n"
    end
    unless noout
       ostring = ostring +  prompt + commandline + "\n" if tag =~ /command/
      unless nooutput
        output = `cat #{dirname}/#{tmpname}`
        unless reused
          outfile.print "OUTPUT\n"
          outfile.print output
          outfile.close
        end
        output.each{|x| ostring+=  " "*indent +x} 
      end
      ostring= ostring.chomp+"\n"
      @previous_is_command = true;
    end
    ostring
  end
  PSEUDO_INTERACTIVE_LIB_NAME = ".pseudo_interactive.rb"
  def create_pseudo_interactive_library
    open (  PSEUDO_INTERACTIVE_LIB_NAME, "w+") { |f|
    f.print <<-END
    alias original_gets gets
        def gets
          a=original_gets
          print a
          a
        end
    END
      }
  end

    
#
# takes an array of strings, starting 
#
  def command_with_input(s,tag, instring, dirname, showout, showin,saveresult )
    ostring = ""
    a = s.chomp.split
    endtag = a.pop
    indata=""
    until (line= instring.shift.chomp) =~ /#{endtag}/
      if $DEBUG
	p indata
	print "\n"
	p line
	print "\n"
      end
      indata += line+ "\n"
    end
#    print "indata:\ ", indata, "indata end\n" 
    tmpinname =   ".acsdoc.command-in"
    open(dirname+"/"+tmpinname, "w+"){|f| f.print indata}
    indent = s.index(tag) 
    p tag
    p indent
    tmpname = ".acsdoc.command-out"
    tmpcommand = ".acsdoc.command-file"
    prompt = " "* indent + @@prompt
    commandline = a[1..a.size].join(" ").chomp
    ostring = ostring +  @@verbatim_pre_separator
    fullcommand = "cd #{dirname}; (" +commandline+ "<" + tmpinname + " )"
    if showout
#      fullcommand  +=   " >& " + tmpname 
      fullcommand  = "(#{fullcommand})" if showout
      if showout
	fullcommand = "cd #{dirname}; (( #{commandline} < #{tmpinname}  ))>& #{tmpname}"
      end
      print "Generating output of \"#{commandline}\"...\n" 
    else
      print "Executing command \"#{commandline}\"...\n" 
    end
    commandname = "csh -f "+tmpcommand
    if /inputoutputinteractive/ =~ tag
      create_pseudo_interactive_library
      commandname = "env RUBYOPT=\" -r#{PSEUDO_INTERACTIVE_LIB_NAME}\" "+commandname
      p commandname
    end
    print "command to run = ", fullcommand, "\n" if $DEBUG
    open(tmpcommand,"w+"){ |f|  f.print fullcommand + "\n"}
    system("cat  #{tmpcommand}") if $DEBUG
    system("#{commandname}");
    system("sync; sleep 1")
    ostring = ostring +  prompt + commandline+ "\n"
    if showin
      output = indata 
    else
      output = ""
    end
    output += `cat #{dirname}/#{tmpname}`  if  showout
    output.each{|x| ostring = ostring +  " "*indent + x}
    ostring = ostring +  @@verbatim_post_separator
    @previous_is_command = nil if showout 
    if showout then ostring else "" end
  end

  def set_prompt(s)
    a = s.split
    @@prompt = a[1]
    print "New prompit is #{@@prompt}\n"
  end

  def check_tag(s, tagname)
    loc = s.index(tagname)
    loc = nil if loc and s.index('"'+tagname+'"')
    loc
  end

  def process_srcfile(a)
    if File.exist?(a)
      if  a=~ /\.rb$/
        prep_rb(a)
        prep_rb_defs(a)
        prep_rb_hashes(a)
        prep_rb_special_comments(a)
        prep_rb_special_comments_for_partfiles(a)
      elsif a =~ /\.(h|C|c|cc)$/
        prep_rb(a)
        prep_c_defs(a)
        prep_rb_hashes(a)
      end
    end
  end
  
  def file_is_there(name)
    print "preprocess file #{name}\n" if $DEBUG
    print "preprocess file #{name}\n" 
    return true if File.exist?(name)
    dir=File.dirname(name)
    fname=File.basename(name)
    p dir if $DEBUG
    p fname if $DEBUG
    if fname[0]== "."[0]
      if fname[1,fname.length-1] =~ /^(\S*\.(h|c|rb|C|cc))/
        filename = dir+ "/"+$1
        raise "File #{filename} does not exist" unless File.exist?(filename)
        process_srcfile(filename)
      end
    end
    return true if File.exist?(name)
  end

# prep_cp handles the following tags (in the form of, for example,
# ":output:" in the case of "output" below: 

# * "inccode (or  /inc.*code/) filename" includes the file specified by 
#   the filename, between horizontal lines
# * "output command and args" includes the output of the command (with args) 
#   Both stderr and stdout are included
# * "commandoutput command and args" includes the command line itself and
#   its output (prompt default is "|gravity>"
# * "prompt new_prompt" sets new prompt
# * "command command and args" just run the command, but discard the output
# * "commandinputoutput args endtag" runs the command, taking the lines 
#   as input, untill endtag is reached.
# 
  def prep_cp_string(instring,dirname,fname)
    ostring = ""
    @previous_is_command=nil;
    lineno = 0
    while s = instring.shift
      lineno += 1
#
# should check if :command: etc directives contains save or not here
# and edit s if that's the case.
# 
      saveresult=false
      s=s.gsub(/:(\w+)save:/){saveresult=true;":"+$1+":"}
      if s.index("#") == 0
        print "comment line skipped ",s, "\n"
      elsif s =~ /^(\s*):in.*code:/ and s.index("\":inccode:\"")==nil
	s.sub!(/:in.*code:/, ':include: ')
        raise "failed to open file #{s.split[1]}" unless file_is_there(s.split[1])
	ostring = ostring +  @@verbatim_pre_separator
	ostring = ostring +  s
	ostring = ostring +  @@verbatim_post_separator
      elsif  s =~ /^(\s*):output:/
	ostring = ostring +  add_output(s, dirname, ":output:",fname,
                                        lineno,saveresult)
      elsif  s =~ /^(\s*):commandoutput:/  and s.index("\":commandoutput:\"")==nil
	ostring = ostring +  add_output(s,  dirname, ":commandoutput:",
					fname,lineno, saveresult)
      elsif  s=~ /^(\s*):commandnooutput:/  and s.index("\":commandnooutput:\"")==nil
	ostring = ostring +  add_output(s,  dirname, ":commandnooutput:",
					fname,lineno, saveresult)
      elsif  s=~ /^(\s*):command:/  and s.index("\":command:\"")==nil
	ostring = ostring +  add_output(s,  dirname, ":command:",
					fname,lineno, saveresult)
      elsif  s=~/^(\s*):prompt:/ and s.index("\":prompt:\"")==nil
	set_prompt(s)
      elsif s=~ /^(\s*):commandinputoutput:/
	ostring = ostring +  command_with_input(s,":commandinputoutput:", 
				      instring,dirname,true, true,saveresult)
      elsif s=~ /^(\s*):commandinputoutputnoecho:/
	ostring = ostring +  command_with_input(s,":commandinputoutputnoecho:", 
				      instring,dirname,true, false,saveresult)
      elsif s=~ /^(\s*):commandinputoutputinteractive:/
	ostring = ostring +  command_with_input(s,":commandinputoutputinteractive:", 
				      instring,dirname,true, false,saveresult)
      elsif s =~ /^(\s*):commandinput:/
	ostring = ostring +  command_with_input(s,":commandinput:", instring,
				      dirname,false, true,saveresult)
      else
	ostring += @@verbatim_post_separator if @previous_is_command
	ostring += s 
	@previous_is_command = nil 
      end
    end
    ostring
  end


  def convert_link_to_rdoc_style(instring,dirname)
    ostring=[] 
    while s=instring.shift
      if /(^|\s)link\:(\S+)/  =~ s
	print "rdoc style line #{s}\n"
	preceedingspaces = $1
	imglinkfile = $2
	s.sub!(/(^|\s)link\:(\S+)/,
	       "#{preceedingspaces}link:../#{dirname}/#{imglinkfile}")
	print "converted to: #{s}\n"
      end
      ostring.push(s)
    end
    ostring
  end


  def process_texcode(texcode,dirname)
    imgbase =".imgs/"
    imgdir =  imgbase 
    Dir.mkdir(imgdir) unless File.exist?(imgdir)
    texname = "tmp.tex"
    texbase = "tmp"
    texsource=open(texname,"w+")
    texsource.print <<-END_TEXSOURCE
    \\documentclass{article}
    \\usepackage{graphicx}
    #{@@additional_preambles_for_inline_tex}
    \\begin{document}
       \\pagestyle{empty}
       \\thispagestyle{empty}
       #{@@additional_commands_for_inline_tex}
       #{texcode}
       \\thispagestyle{empty}
    \\end{document}
    END_TEXSOURCE
    texsource.close
    system("cat "+texname)
    if  (ENV["LANG"] == "ja_JP.eucJP") or ($KCODE == "EUC") 
      latexcommand = "platex"
    else
      latexcommand = "latex"
    end

    system "#{latexcommand} #{texname}"
    system "dvips -o #{texbase}.ps -l 1 -x #{$texscale} -E #{texbase}"
    system "rm -f #{texbase}.jpeg; convert  #{texbase}.ps  #{texbase}.jpeg "
    imgname = imgbase + @@imgcount.to_s + ".jpeg"
    if File.exist?(texbase+".jpeg")
      system "mv -f #{texbase}.jpeg #{imgname}"
    elsif File.exist?(texbase+".jpeg.0")
      system "mv -f #{texbase}.jpeg.0 #{imgname}"
    else
      raise "Failed to create the jpeg file #{texbase}.jpeg"
    end
    @@imgcount+=1
    "<IMG ALIGN=\"middle\" SRC=#{imgname}>"
  end

  def process_tex_inlines(s,instring,dirname)
    if s.index("<tex>")-1==  s.index("\\<tex>")
      print "s is escaped ", s, "\n"
      return [s[s.index("<tex>")+5,s.length],s[0,s.index("<tex>")+5]]
    end
    ostring = s[0,s.index("<tex>")]
    s = s[s.index("<tex>")+5,s.length]
    texcode = ""
    while s.index("</tex>")==nil
      texcode += s + "\n"
      s = instring.shift
      if s == nil 
	raise "End of file reached while searching for </tex>: #{$infile}"
      end
    end
    texcode += s[0,s.index("</tex>")];
    s = s[s.index("</tex>")+6,s.length]
    texresult=    process_texcode(texcode,dirname)
    ostring += texresult
    [s,ostring]
  end

#
# <tex> xxx </tex> is passed to tex process and converted to 
# an image link
  def find_and_process_tex_inlines(instring,dirname)
    ostring=""
    while s = instring.shift
      while loc = s.index("<tex>")  
	r = process_tex_inlines(s,instring,dirname)
	ostring +=r[1]
	s = r[0]
      end
      ostring += s+"\n"
    end
    ostring
  end

  @@tex_equation_number = 0
  @@tex_labels = {}
  @@tex_labels_filename = {}

  def process_tex_equations(s,instring,dirname)
    @@tex_equation_number += 1
    eqtype = s
    namelabel = ""
    texcode = "\\setcounter{equation}{#{@@tex_equation_number-1}}\n\\begin{#{eqtype}}\n"
    while (s = instring.shift ) =~ /\S/
      if s =~ /\\label\{(\S+)\}/ 
	@@tex_labels[$1]=@@tex_equation_number
        @@tex_labels_filename[$1]=$current_cp_filename
	namelabel = "<a name=" + $1 + ">\n"
      end
      texcode += s + "\n"
      if s == nil 
	raise "End of file reached while searching for newline: #{$infile}"
      end
    end
    texcode += "\\end{#{eqtype}}\n"
    pp = process_texcode(texcode,dirname)
    namelabel +"<div class=\"equation\"><p>\n" +pp+"</p></div>\n"
  end


  def find_and_process_tex_equations(instring,dirname)
    is = instring.split("\n");
    ostring=""
    while s = is.shift
      p s  if $DEBUG
      if s =~ /^\s*:(equation|eqnarray):\s*$/
	r = process_tex_equations($1,is,dirname)
	ostring +=r
      else
	ostring += s+"\n"
      end
    end
    ostring
  end

  def process_nosectionnumber(realtag,s,taggedstring,dirname)
    if $DEBUG
      print "Enter process_nosectionnumber\n"
      p realtag
      p s
      p taggedstring
      p dirname
    end
    ""
  end

  def find_and_process_generic_tag(instring,dirname,tagname,funcname)
    tagexpr = Regexp.compile("^\\s*:"+tagname+"\\s*:")
    is = instring.split("\n");
    ostring=""
    while s = is.shift
      p s  if $DEBUG
      if s =~ tagexpr
	realtag = $1
	taggedstring = ""
	while (ss = is.shift ) =~ /\S/
	  taggedstring += ss + "\n"
	  if ss == nil 
	    raise "End of file reached while searching for newline: #{$infile}"
	  end
	end
	ostring +=send(funcname,realtag,s,taggedstring,dirname)
      else
	ostring += s+"\n"
      end
    end
    ostring
  end
  
  def copy_figure_file(figurefilename,dirname, figure_number)
    imgbase =".imgs/"
    imgdir =  imgbase 
    Dir.mkdir(imgdir) unless File.exist?(imgdir)
    imgname = imgbase + figure_number.to_s + "_" +
      File.basename(figurefilename) + ".jpeg"
    p imgname  if $DEBUG
    system "convert #{dirname}/#{figurefilename} #{imgname}"
    system "mv -f #{imgname}.0 #{imgname}"if File.exist?(imgname + ".0")
    imgname
  end

  @@figure_number =0

  def process_figures(s,instring,dirname)
    @@figure_number += 1
    a=s.chomp.split
    figurefilename,size,label = a[1],a[2],a[3]
    @@tex_labels[label]=@@figure_number
    @@tex_labels_filename[label]=$current_cp_filename
    namelabel = "<a name=#{label}>\n"
    caption = ""
    while (s = instring.shift ) =~ /\S/
      caption += s + "\n"
      if s == nil 
	raise "End of file reached while searching for newline: #{$infile}"
      end
    end
    filename_to_link = copy_figure_file(figurefilename,dirname,@@figure_number)
    "<div class=\"center\">"+
    "<p>"+namelabel + "<img ALIGN=\"middle\" src=\"#{filename_to_link}\"></p>"+
    "\n<p> Figure " + @@figure_number.to_s + ": " + caption + "</p></div>\n"
  end


  def find_and_process_figures(instring,dirname)
    is = instring.split("\n");
    ostring=""
    while s = is.shift
      p s  if $DEBUG
      if s =~ /^\s*:figure:\s*/
	r = process_figures(s,is,dirname)
	ostring +=r
      else
	ostring += s+"\n"
      end
    end
    ostring
  end

#  def to_rdocname(name)
#    "_"+name.gsub(/\./,"_")+".html"
#  end

  def to_htmlname(a)
    File.dirname(a)+"/"+File.basename(a,$current_extention)+ ".html"
  end

  def getauxlabel(dirname, label)
    print "filename = "+dirname+"/"+@@auxfilename+"\n"
    begin
      x = Marshal.load(open(dirname+"/"+@@auxfilename,"r"))
      tex_labels, tex_labels_filename,  section_label_table,  sectionheaders = x
      if tex_labels[label]
        location = dirname+"/"+
          to_htmlname(tex_labels_filename[label])
        newtag=@@volindex[dirname[3,dirname.length]]
        tag =  newtag ? "v"+newtag.to_s : dirname+"."
        return [location,tag+tex_labels[label].to_s]
      else
        return [nil,nil]
      end
    rescue
      print "aux file in dir #{dirname} does not exist. \n"
      return [nil,nil]
    end 
  end

  def process_tex_labels(instring,dirname)
    x = instring
    x.gsub(/ref\(((\w|\d|[:_#.\/])*)\)/){|s| 
      label = $1
      print "LABEL = ",label, "\n" 
      if label =~ /(.*)\#(.*)/
          dirname = $1
        reallabel = $2
        filename, tag=getauxlabel(dirname,reallabel)
        if filename
          "<a href=#{filename}\##{reallabel}>#{tag}</a>"
        else
          "(unknown label #{label})"
        end
      elsif @@tex_labels[label] 
#        "("+@@tex_labels[label].to_s+")["+
#          to_rdocname(@@tex_labels_filename[label])+"\#"+label+"]"
          "<a href="+to_htmlname(@@tex_labels_filename[label])+"\#"+label+">"+
          @@tex_labels[label].to_s+"</a>"
      elsif @@old_tex_labels[label]
#          "("+@@old_tex_labels[label].to_s+")["+
#            
          "<a href="+
             to_htmlname(@@old_tex_labels_filename[label])+"\#"+label+">"+
          @@old_tex_labels[label].to_s+"</a>"
      else
        "(unknown label #{label})"
      end
    }

  end

@@sectionheadercounter=0
@@sectionheaders=[]

  def process_section_headers_old(instring,filename)
    instring.gsub(/^(=+)\s*(.+)$/){|s| 
      sectionlevel = $1.length
      sectionname = $2
      sectionlabel="rdocsect"+@@sectionheadercounter.to_s
      @@sectionheaders.push [sectionlabel,sectionlevel,sectionname,filename]
      @@sectionheadercounter+= 1
      s+"<name>" + sectionlabel + "</name>\n"
    }
  end


  def process_section_headers(instring,filename)
#    p "enter process_section_headers"
#    print instring
#    p "input lines end"
    labeltext=nil
    ostring=""
    lastsectionnumber=nil
    instring.each_line{|str|
      if str =~ /^\s*:label:\s/
	labeltext=str.split[1]
        labeltext = "sect:"+labeltext if labeltext !~ /^sect/
        ostring+= "<a name=#{labeltext}>"
	@@tex_labels[labeltext]=lastsectionnumber
        @@tex_labels_filename[labeltext]=$current_cp_filename
	print "Label #{labeltext} as #{lastsectionnumber}\n"
      elsif /^---*$/ =~ str
        ostring += "\n<hr>\n"
      else
	x=str.gsub(/^(=+)\s*(.+)$/){|s| 
	  sectionlevel = $1.length
	  sectionname = $2
          if @@section_counters[sectionlevel]==nil
            @@section_counters[sectionlevel]=1
          else
            @@section_counters[sectionlevel]+=1
          end
          @@section_counters= @@section_counters[0..sectionlevel]
          number_label = @@section_counters[1..sectionlevel].join(".")+"."
          sectionname = number_label+ " "+ sectionname if $numbersections
	  sectionlabel="rdocsect"+@@sectionheadercounter.to_s
	  @@sectionheaders.push [sectionlabel,sectionlevel,sectionname,filename]
	  @@sectionheadercounter+= 1
	  labeltext = sectionname if labeltext==nil
	  @@section_label_table[labeltext]=sectionlabel
          lastsectionnumber=number_label[0,number_label.length-1]
	  labeltext=nil
#	   "<h2> "+sectionname+ "</h2>\n<a name=" + sectionlabel + ">\n"
	   "<a name=" + sectionlabel + ">\n<h2> "+sectionname+ "</h2>\n"
	} 
	ostring +=x
      end
    }
    ostring
  end

@@filefortoc = []
  def process_toc(instring,filename)
    if instring =~ /^(\s*):tableofcontents:/
      instring=instring.gsub(/^(\s*):tableofcontents:/,"TOCTOCTOCTOC")
      @@filefortoc.push(filename)
    end
    instring
  end

  def process_tex_weblinks(instring)
    ostring=instring.gsub(/(\\*)<web>(.+?)<\/web>/m){ linktext = $2
      blank=""
      p linktext  if $DEBUG
      if $1 == ""
        if linktext =~ /(.*)\|(.*)/m
          url=($1)
          text=$2
        else
          url=text=linktext
        end
        s="<a href=#{url}>#{text}</a>"
        s=blank+s.gsub(/\s/m," ")
      else
        s=blank+"&lt;web>#{linktext}&lt;/web>"
      end
      s
    }
  end


  def process_some_special_characters(instring)
    instring.gsub!(/\\>/m,">")
    instring.gsub!(/\\</m,"&lt;")
    ostring=""
    instring.each{|x| ostring += expand(x)}
    ostring
  end
  def prep_cp(infile, outfile,tolatex_flag)
    $infile = infile
    begin
      ifile = open(infile, "r")
    rescue
      raise "#{infile} does not exist"
    end
    dirname = File.dirname(infile)
    ofile = open(outfile, "w+")
    instring = []
    while s = ifile.gets
      instring.push(s)
    end
    ifile.close
    s = instring
    reset_verbatim_separator    unless tolatex_flag
    tmpstring=prep_cp_string(s,dirname,infile).split("\n");
    if tolatex_flag
      tmp2= Rdoctotex::convert_to_latex(tmpstring,dirname);
    else
      tmp2= Rdoctotex::latex_process_tex_mathmarkup(tmpstring)
      tmp2= Rdoctotex::process_include(tmp2)
      tmp2= find_and_process_tex_inlines(tmp2,dirname);
      tmp2= find_and_process_tex_equations(tmp2,dirname);
      tmp2= find_and_process_figures(tmp2,dirname);
      tmp2= find_and_process_generic_tag(tmp2,dirname,"nosectionnumber",
					 "process_nosectionnumber")
      tmp2= process_toc(tmp2,infile);
      tmp2= process_section_headers(tmp2,infile)
      tmp2= process_tex_labels(tmp2,dirname);
      tmp2= process_tex_weblinks(tmp2)
      tmp2= process_some_special_characters(tmp2)
#      tmp2= process_single_paragraphs_lists_etc(tmp2,0,0,1,0).join("\n")
      tmp2= latex_process_single_paragraphs_lists_etc(tmp2,0,0,1,0)
      tmp2= post_process_paragraphs(tmp2).join("\n")
      tmp2= process_link(tmp2)
      tmp2=process_wordmarkup(tmp2)

    end
    ofile.print tmp2
    ofile.close
  end

  def expand(s)
    if s 
      t=s.gsub(/([^\t]{8})|([^\t]*)\t/n){[$+].pack("A8")}
      t=t.gsub(/\f/,"")
      t=t.gsub(/[[:cntrl:]]/,"")+"\n"
    else
      t=nil
    end
    t
  end

  # :segment start: prep_rb
  def prep_rb(infile)
    # :segment start: open-input-file
    begin
      ifile = open(infile, "r")
    rescue
      raise "#{infile} does not exist"
    end
    # :segment end:
    segment_level = 0
    ofile = Array.new;
    oname = Array.new;
    while s = expand(ifile.gets)
      
      if loc = s.index(":segment start:")  and s.index("\":segment start:\"")==nil
	segment_name = s[loc,s.length].split[2];
	print segment_name if $DEBUG
	outfile = File.dirname(infile)+"/."+File.basename(infile) +
	  "-" + segment_name
	if oname[0...segment_level].index(outfile) != nil
	  raise "Too many #{s} for file #{infile} line #{ARGF.lineno}"
	end
	oname[segment_level]=outfile
	ofile[segment_level] = open(outfile, "w+")
	segment_level += 1
      elsif  s.index(":segment end:") and  s.index("\":segment end:\"")  ==nil
	segment_level -= 1
	if (segment_level >= 0)
	  ofile[segment_level].close
	else
	  raise "Too many #{s} for file #{infile} line #{ARGF.lineno}"
	end
      else
	for i in 0...segment_level do
	  ofile[i].print s
	end
      end
    end
    ifile.close
  end
  # :segment end: prep_rb


  def prep_rb_special_comments(infile)
    begin
      ifile = open(infile, "r")
    rescue
      raise "#{infile} does not exist"
    end
    outfile = File.dirname(infile)+"/."+File.basename(infile)
    ofile = open(outfile,"w+")
    while s = expand(ifile.gets)
      case s
      when /\#(\d+)(.*)/  
	s = s.gsub(/\#(\d+)(.*)/,'')      
      when /(^|(\s)+)\#(\s*)\:segment /
	s = nil
      end
      ofile.print s if s
    end
    ifile.close
    ofile.close
  end

  def prep_rb_special_comments_for_partfiles(file)
    basename =File.dirname(file)+"/."+File.basename(file) 
    Dir[basename+"{+,-}*"].each{|f|
      newname =File.dirname(f)+"/."+File.basename(f) 
      prep_rb_special_comments(f)
      File.rename(newname,f)
    }
  end


  @@hashtypes={
    ".rb", /\#(\d+)(.*)/,
    ".h", /\/\/(\d+)(.*)/,
    ".c", /\/\/(\d+)(.*)/,
    ".C", /\/\/(\d+)(.*)/,
    ".cc", /\/\/(\d+)(.*)/,
  }
  def prep_rb_hashes(infile)
    print "prep_rb_hashes for file #{infile}\n" if $DEBUG
    begin
      ifile = open(infile, "r")
    rescue
      raise "#{infile} does not exist"
    end

    if infile =~ /\.(\w+)$/
      extension = "."+$1
    else
      raise "File name #{infile} has no extention part"
    end
    hashnames=[]
    while s = expand(ifile.gets)
      if s  =~ @@hashtypes[extension]
	segment_name = $1
	s = s.gsub(/\#(\d+)(.*)/,'')
	print segment_name if $DEBUG
	outfile = File.dirname(infile)+"/."+File.basename(infile) +
	  "-" + segment_name
        print "prep_rb_hashed outfile = #{outfile}\n" if $DEBUG
	if hashnames.index(outfile) 
	  openmode= "a+" 
	else
	  openmode = "w+"
	  hashnames.push(outfile)
	end
	open(outfile,openmode){|f| f.print s}
      end
    end
    ifile.close
  end

  def prep_rb_defs(infile)
    ifile = open(infile, "r")
    method_level = 0
    ofile = Array.new;
    oname = Array.new;
    olevel = Array.new;
    classname = "noname"
    while s = expand(ifile.gets)
      s.gsub!(/([^\t]{8})|([^\t]*)\t/n){[$+].pack("A8")}
      if s.split[0]== "class"
	classname = s.split[1]
      elsif s.split[0]== "module"
	classname = s.split[1]
      elsif s.split[0]== "def"
	method_name = s.gsub(/\(/," ").split[1]
	print method_name if $DEBUG
	method_name = "_divide_" if method_name == "/"
	outfile = File.dirname(infile)+"/."+File.basename(infile) +
	  "+" + method_name
	outfilelong=outfile+ "+" +classname
	if oname[0...method_level].index(outfile) != nil
	  raise "Too many defs for file #{infile} line #{ARGF.lineno}"
	end
	oname[method_level]=[outfile,outfilelong]
	ofile[method_level] = [open(outfile, "w+"),open(outfilelong, "w+")]
	olevel[method_level] = s.index("def")
	method_level += 1
      elsif  s.split[0] == "end"
	loc = s.index("end")
	# check if this "end" corresponds to the deepest level "def"
	if method_level > 0
	  lastlevel = method_level-1
	  if olevel[lastlevel] == loc 
	    ofile[lastlevel].each{|x| x.print s}
	    ofile[lastlevel].each{|x| x.close}
	    method_level -= 1
	  elsif olevel[lastlevel] > loc 
	    raise "Unexpected \"end\" with level #{loc} for expected level "+
	      "#{olevel[lastlevel]} at line #{ARGF.lineno} of file #{infile}"
	  end
	end
      end
      for i in 0...method_level do
	ofile[i].each{|x| x.print s}
      end
    end
    ifile.close
  end

  def prep_c_defs(infile)
    ifile = open(infile, "r")
    outfilenamebase = File.dirname(infile)+"/."+File.basename(infile) +
	  "+" 
    while s = expand(ifile.gets)
      s.gsub!(/([^\t]{8})|([^\t]*)\t/n){[$+].pack("A8")}
      if s =~ /\s*typedef\s+(struct|union)\s+(\w\S*)\{$/
	name=$2
	typedefstring = s
	while (s = expand(ifile.gets)) !~ /^\s*\}.*;\s*$/
	  typedefstring += s
	end
	typedefstring += s
	open(outfilenamebase+name,"w"){|f|f.print typedefstring}
      elsif s =~ /^(\w\S*\s+)+(\S+)\(/
	name = $2
	print "#{infile}: #{s.chomp} : #{name}\n"
	functionstring = s
	while s !~ /(^\{)|(\);)/
	  s = expand(ifile.gets)
	  functionstring += s
	end
	if $1
	  while s !~ /^\}/
	    s = expand(ifile.gets)
	    functionstring += s
	  end
	  open(outfilenamebase+name,"w"){|f|f.print functionstring}
	end
      end
    end
    ifile.close
  end

  def initacs
    acsdocinitfile=nil
    for fname in [ENV["ACSDOCINITRC"], ".acsdocinitrc", ENV["HOME"]+"/.acsdocinitrc"]
      if acsdocinitfile == nil and fname != nil and File.exist?(fname)
	acsdocinitfile = fname 
      end
    end
    
    if acsdocinitfile
      print "Loading initialization file #{acsdocinitfile}\n"
      load acsdocinitfile
    else
      print "No config file found\n"
    end
  end
  
@@toppagefilename= nil
  def navigation_string(prev,nex,filename)
    prevtext = "Previous"
    nexttext = "Next"
    toctext  = "ToC"
    toptext  = ""
    if @@toppagefilename
      toptext = "<td> \n   <a href=#{@@toppagefilename} target=\"_top\">Up</a>\n   </td>"
    end
    prevtext = "<a href=#{prev}>Previous</a>" if prev    
    nexttext = "<a href=#{nex}>Next</a>" if nex
    toctext = "<a href=#{@@filefortoc[0]}#TOC>ToC</a>" if @@filefortoc[0]
    s = <<END
<table border="0" width="70%">
<tr>
  <td>
      #{prevtext}
  </td>
  <td>
      #{toctext}
  </td>
  #{toptext}
  <td>
      #{nexttext}
  </td>
</tr>
</table>
END
  end

  def add_links(filename,prev,nex)
    navi = navigation_string(prev,nex,filename)
    instring = open(filename,"r"){|f| f.gets(nil)}
    ostring= navi+ "\n" +instring +navi+ "\n" 
    open(filename,"w"){|f| f.puts(ostring)}
  end

@@stylefilename = ".acsdoc-style.css"

  def htmlheader(name)
    <<-END
<html>
<head>
  <title> #{name}</title>
  <link rel=StyleSheet href="#{@@stylefilename}" type="text/css" media="screen" />
</head>

<body bgcolor="white">

END
  end
@@htmlfooter = <<-END

</body>
</html>
END
@@htmlcss = <<-END

PRE {
  background: #E0FFE8;

}
.center  { text-align: center; }

.equation  { text-align: right; }

body,td,p { font-family: Verodana, Arial, Helvetica, sans-serif; 
       color: #000010;
}

.attr-rw { font-size: x-small; color: #444488 }

.title-row { background: #0000aa;
             color:      #eeeeff;
}

.big-title-font { color: white;
                  font-family: Verdana, Arial, Helvetica, sans-serif;
                  font-size: large; 
                  height: 50px}

.small-title-font { color: aqua;
                    font-family: Verdana, Arial, Helvetica, sans-serif;
                    font-size: xx-small; }

.aqua { color: aqua }

.method-name, attr-name {
      font-family: monospace; font-weight: bold;
}

.tablesubtitle, .tablesubsubtitle {
   width: 100%;
   margin-top: 1ex;
   margin-bottom: .5ex;
   padding: 5px 0px 5px 20px;
   font-size: large;
   color: aqua;
   background: #3333cc;
}

.name-list {
  font-family: monospace;
  margin-left: 40px;
  margin-bottom: 2ex;
  line-height: 140%;
}

.description {
  margin-left: 40px;
  margin-top: -2ex;
  margin-bottom: 2ex;
}

.description p {
  line-height: 140%;
}

.aka {
  margin-left: 40px;
  margin-bottom: 2ex;
  line-height: 100%;
  font-size:   small;
  color:       #808080;
}

.methodtitle {
  font-size: medium;
  text-decoration: none;
  color: #0000AA;
  background: white; 
}

.paramsig {
   font-size: small;
}

.srcbut { float: right }


pre.source {
  border-style: groove;
  background-color: #ddddff;
  margin-left:  40px;
  padding: 1em 0em 1em 2em;
}

.classlist {
  margin-left: 40px;
  margin-bottom: 2ex;
  line-height: 140%;
}

li {
  display:    list-item;
  margin-top: .6em;
}

.kw { color: #3333FF; font-weight: bold }
.cmt { color: green; font-style: italic }
.str { color: #662222; font-style: italic }
.re  { color: #662222; }
END


  def add_html_headeretc(filenames)
    filenames.each{|filename|
      instring = open(filename,"r"){|f| f.gets(nil)}
      ostring= htmlheader(filename)+ "\n" +instring +@@htmlfooter+ "\n" 
      open(filename,"w"){|f| f.puts(ostring)}
    }
  end
  def add_navigation_links(rdochtmls)
    n=rdochtmls.size
    rdochtmls.each_index{|i|
      if i == 0 then
	prev = nil
      else
	prev = rdochtmls[i-1]
      end
      nex = rdochtmls[i+1]
      add_links(rdochtmls[i],prev,nex)
    }
  end
  def convert_cpfilename_to_htmlfilename(name)
    name.gsub(/\.((cp)|(ok))$/,".html")
  end
  def create_navigations_for_cp_files(args)
    add_navigation_links(args) if args.size > 1
  end

  
  def create_toc_string(filename)
    s = "<p><H1>Contents</H1><a name=TOC><p>"
    currentlevel=0
    @@sectionheaders.each{|x|
      while x[1]>currentlevel
	s += "<ul>\n"
	currentlevel+= 1
      end
      while x[1]<currentlevel
	s+=  "</ul>\n"
	currentlevel -= 1
      end
      fname =  convert_cpfilename_to_htmlfilename(x[3])
      s+= "<li> <a href=#{fname}##{x[0]}>#{wordmarkup(x[2])}</a></li>\n"
    }
    while 0<currentlevel
      s+=  "</ul>\n"
      currentlevel -= 1
    end
    s
  end  
  def add_toc
    print "Enter add_toc\n"
    @@filefortoc.collect!{|x|
      s=create_toc_string(x)
      print s
      fname=convert_cpfilename_to_htmlfilename(x)
      instring=File.open(fname,"r").read.gsub(/TOCTOCTOCTOC/,s)
      f=File.open(fname,"w+")
      f.write(instring)
      f.close
      fname
    }
  end

  def process_css
    open(@@stylefilename,"w"){|x| x.write @@htmlcss}
  end

  def dump_aux
    f=open(@@auxfilename,"w+")
    f.print Marshal.dump([@@tex_labels, 
                           @@tex_labels_filename, 
                           @@section_label_table,
                           @@sectionheaders])
    f.close
  end

  def load_old_aux
    @@old_tex_labels= {}
    @@old_tex_labels_filename= {}
    @@old_section_label_table= {}
    @@old_sectionheaders = {}
    begin 
      x = Marshal.load(open(@@auxfilename,"r"))
      @@old_tex_labels, @@old_tex_labels_filename,  @@old_section_label_table,  @@old_sectionheaders = x
      if $DEBUG
        p @@old_tex_labels
        p @@old_tex_labels_filename
        p @@old_section_label_table
        p @@old_sectionheaders
      end
    rescue
      print "aux file does not exist. \n"
    end 
  end

  def load_volindex
    begin 
      @@volindex = Marshal.load(open(@@volindexfilename,"r"))
    rescue
      print "volindex file does not exist. \n"
      @@volindex={}
    end 
    $volindex = @@volindex
  end


  def convert_cpfilename_to_rdoc_htmlfilename(name)
    name = File.dirname(name)+"/."+File.basename(name)
    'doc/files/'+name.gsub(/\./, '_')+ '.html'
  end

  def create_dir_recursively(name)
    parent = File.dirname(name)
    create_dir_recursively(parent) if not File.exist?(parent)
    Dir.mkdir(name) if not File.exist?(name)
  end

  def make_notice_for_old_page(newfile, oldfile)
    create_dir_recursively(File.dirname(oldfile)) if not File.exist?(oldfile)
    open(oldfile,"w"){|f| f.write <<-END
      <HTML>        
        <BODY>
        This page has been moved to <a href="../../../#{newfile}">here</a>.<p>
Please update your bookmarks.
</BODY>
        </HTML>        
END
      }
  end

  def movetosubdirectory(cplist, directory_name)
    if File.exist?(directory_name) and not File.directory?(directory_name)
      raise "#{directory_name} is a file. Cannot move texts there"
    end
    Dir.mkdir(directory_name) unless File.exist?(directory_name)
    if  File.exist?(directory_name+"/.imgs")
      files = Dir.glob(directory_name+"/.imgs/*")
      File.delete(*files) if files.size > 0
      Dir.rmdir(directory_name+"/.imgs") 
    end
    system "mv -f  #{cplist.join(" ")} .imgs #{@@stylefilename} #{directory_name}"
  end
end


# :segment start: acsdoc
include Acsdoc

## define some global variables used as options, before reading in 
## the initialization file 
$numbersections=true
initacs
$texscale= ENV["ACSDOCTEXSCALE"]?  ENV["ACSDOCTEXSCALE"]:1900
load_old_aux

load_volindex
del_flag = true
tolatex_flag = false

directory_arg  = false
directory_name = nil
cpfiles = []
ARGV.collect! do |a|
  if a =~ /\.((cp)|(ok))$/
    extention = "."+$1
    $current_extention=extention
    if FileTest.size?(a)
      unless tolatex_flag 
	dot_a = File.dirname(a)+"/"+File.basename(a,extention)+ ".html"
      else
	dot_a = File.dirname(a)+"/"+File.basename(a,extention)+ ".tex"
      end
      $current_cp_filename = a
      prep_cp(a, dot_a, tolatex_flag)
      if File.exist?(dot_a)
        cpfiles.push([a,dot_a, convert_cpfilename_to_rdoc_htmlfilename(a)])
        a = dot_a
      else
        a = nil
      end
    else
      a = nil
    end
    a
  elsif a =~ /\.rb$/
    if File.exist?(a)
      prep_rb(a)
      prep_rb_defs(a)
      prep_rb_hashes(a)
      prep_rb_special_comments(a)
      prep_rb_special_comments_for_partfiles(a)
    else
      a = nil
    end
    a
  elsif a =~ /\.(h|C|c|cc)$/
    if File.exist?(a)
      prep_rb(a)
      prep_c_defs(a)
      prep_rb_hashes(a)
#      prep_rb_special_comments(a)
#      prep_rb_special_comments_for_partfiles(a)
    else
      a = nil
    end
    a
  elsif a == "--keep-dot-files"
    print "Obsolete option ignored:  --keep-dot-files\n"
    a = nil
  elsif a == "--tolatex"
    tolatex_flag = true
    del_flag = false
    a = nil
  elsif a == "--reuseoutput"
    print "reuse flag set\n" 
    setreuseoutput true
    readin_commandoutputs
    a = nil
  elsif a == "--directory"
    print "Directory arg found\n"
    directory_arg = true        
    a = nil
  elsif directory_arg == true
    directory_name = a 
    print "Directory to store: #{a}\n"
    directory_arg = false
    a=nil
  end
  a
end
if  (ENV["LANG"] == "ja_JP.eucJP") or ($KCODE == "EUC") 
  coptions = "--charset=EUC-JP"
else
  coptions = " "
end


ARGV.compact!


unless tolatex_flag
  cplist = cpfiles.collect{|x| x[1]}
  p cplist if $DEBUG
  add_toc
  process_css
  dump_aux
  create_navigations_for_cp_files(cplist)
  add_html_headeretc(cplist)
  cpfiles.each{|x| make_notice_for_old_page(x[1],x[2])}
  movetosubdirectory(cplist, directory_name) if directory_name
end




# :segment end:
