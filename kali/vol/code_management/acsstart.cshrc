#
# acsstart.cshrc: startup for ACS
#
# one should source this file somewhere
#
if ( $?ACSROOT) then
   if (! $?ACSSCRIPTS ) then
     setenv ACSSCRIPTS $ACSROOT/bin
     set path=( $ACSSCRIPTS $path )
   endif
   setenv ACSDOCOPTIONS --reuseoutput
   setenv ACSLIBS $ACSROOT/lib
   setenv RUBYPATH .:$ACSSCRIPTS
   setenv RUBYLIB .:$ACSLIBS
   if ( -e $ACSSCRIPTS/acsstart.local ) then
      source   $ACSSCRIPTS/acsstart.local
   endif
endif
