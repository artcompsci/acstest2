#!/usr/bin/env ruby
#
# check_and_install.rb
#
# command to check if target is doubly defined or not 
# and put it if it is okay.
#
# Usage: check_and_install.rb NAME_OF_ENV_VAR_FOR_INSTALL_DIR [files ...]
#
# Example: check_and_install.rb ACSSCRIPTS check_and_install.rb

def addzeros(n,s="")
  ("0" * (n - s.length))+s
end




def name_with_date(name)

  addzeros(4,Time.now.year.to_s)+ addzeros(2,Time.now.month.to_s)+
    addzeros(2,Time.now.day.to_s)+"_"+name
end
def store_file_with_date(sourcename, dirname,fullsourcename)
  subdirname = (sourcename.gsub(/\./,"_"))
  if subdirname == sourcename
    subdirname = sourcename + "_"
  end
  subdirpath = dirname+"/"+subdirname
  Dir.mkdir(subdirpath) unless File.exist?(subdirpath)
  targetname=name_with_date(sourcename)

  system "/bin/cp -p #{sourcename} #{subdirpath}/#{targetname}"
  logfile= "#{subdirpath}/#{targetname}_log"
  open(logfile,"w"){|f| f.print fullsourcename} 
  if $use_svn
    system "svn add -N #{subdirpath}"
    system "svn add -N #{subdirpath}/#{targetname}"
    system "svn add -N #{logfile}"
  end
end  

def check_and_install(sourcename, dirname)
  checkdirname= dirname+"/./.sourcenames"
  checkfilename= checkdirname+"/"+sourcename
  fullsourcename=File.expand_path(sourcename)
  if File.exist?(checkfilename)
    oldsource= open(checkfilename,"r"){|f| f.gets}.chomp
    if oldsource != fullsourcename
      print "#{__FILE__} error:" 
      print "  Target file comes from #{oldsource}, " 
      print "  different from #{fullsourcename}\n"
      print "  If you want to overwrite, please remove file #{checkfilename}\n"
      print "  Also, make sure that you do not export file #{sourcename} from\n"
      print "  more than one place.\n"
      print "File #{sourcename} is not installed. Exiting...\n"
      exit 1
    end
  end
  copyfile=1
  targetfile=dirname+"/"+sourcename
  if File.exist?(targetfile)
    system "diff -q  #{sourcename} #{targetfile}"
    copyfile= ( $? != 0) ? 1:0
  end
  if copyfile==1
    STDERR.print "Installing file #{sourcename} to  #{dirname}" 
    system "/bin/cp -p #{sourcename} #{dirname}" 
    store_file_with_date(sourcename,dirname,fullsourcename)
    STDERR.print " ... finished\n" 
  end
  Dir.mkdir(checkdirname) unless File.exist?(checkdirname)
  unless File.exist?(checkfilename)
    open(checkfilename,"w"){|f| f.print fullsourcename} 
  end
end

dirvarname = ARGV.shift
if ENV.key?(dirvarname)
  dirname= ENV[dirvarname]
else
  dirname=dirvarname
end
raise "#{$0}:#{dirname} does not exist" unless File.exist?(dirname)
raise "#{$0}:#{dirname} is not a directory" unless File.stat(dirname).ftype == "directory"

$use_svn=1
svnenvname="ACSUSESVN"
if  ENV.key?(svnenvname)
   $use_svn= (ENV[svnenvname] == "yes") ?  1:nil
end



while sourcename = ARGV.shift
  check_and_install(sourcename, dirname)
end
