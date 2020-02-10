#!/usr/bin/nawk -f
# Usage: epoch_sss_log_conversion.awk some-log-file-with-$1 ~ [epoch_sss]
#
#  E.g.: epoch_sss_log_conversion.awk /usr/local/logs/archives/nagios-11-??-2006-00.log
#
#        grep -i ivrtel4 /usr/local/logs/archives/nagios-11-??-2006-00.log \
#         | epoch_sss_log_conversion.awk
#
#        tail -f /usr/local/logs/status.log | epoch_sss_log_conversion.awk
#
BEGIN {
        julian_table()

        #--------------------------------------#
        # Verbose (development) output wanted? #
        #--------------------------------------#
        for (n=1; n<ARGC; n++)
        {
          if (ARGV[n] == "-v") # Verbose option
          {
            opt_v = 1
            ARGV[n] = ""
            shift_ARGV()
            break
          }
        }
      }

#======================================================================#
#                               M A I N                                #
#======================================================================#
{
  if ($1 ~ /\133[0-9]+\135/)
  {
    #----------------------------------------------------------#
    # Separate the epoch seconds from the brackets "[]" around #
    # it so we can convert the seconds to yyyy-mm-dd hh:mi:ss. #
    #----------------------------------------------------------#
    Lbracket = match($0,/\133[0-9]+\135/)
    L   = substr($0, 1, Lbracket  )
    sss = substr($0,    Lbracket+1)
    Rbracket = match(sss,/\]/)
    R   = substr(sss,   Rbracket)
    sss = substr(sss,1, Rbracket)
    print L""sss_to_datetime(sss)""R
    next

  }
  print
}


#======================================================================#
#                     U S E R    F U N C T I O N S                     #
#                        (in alphabetical order)                       #
#----------------------------------------------------------------------#
function basedate(                                               \
                   YYYY,MM,DD,                                   \
                   yyyy,cc,ddddd,leapdays,cc_leapdays,accum_days \
                 )                                                     #
# -------------------------------------------------------------------- #
# Globals: julian_days[] and julian_leap[]                             #
#   Calls: leap_year()                                                 #
#----------------------------------------------------------------------#
{
  julian_table() # Start with a new julian table.

  #--------------------------------------------------------#
  # First, decrement the year and get the number of days   #
  # for all the years preceeding it (in the Common Era).   #
  #--------------------------------------------------------#
  yyyy = YYYY
  if ((yyyy - 1) > 0)
  {                                                   ;if (opt_v) print "   YYYY       =|"YYYY       "|"
    yyyy--                                            ;if (opt_v) print "   yyyy       =|"yyyy       "|"
    cc          = int(yyyy / 100)                     ;if (opt_v) print "   cc         =|"cc         "|"
    ddddd       = yyyy * 365                          ;if (opt_v) print "   ddddd      =|"ddddd      "|"
    leapdays    = int(yyyy / 4)                       ;if (opt_v) print "   leapdays   =|"leapdays   "|"
    cc_leapdays = (cc > 0) ? (int(cc / 4)) : 0        ;if (opt_v) print "   cc_leapdays=|"cc_leapdays"|"
    ddddd       = ddddd + leapdays - cc + cc_leapdays ;if (opt_v) print "   ddddd      =|"ddddd      "|"
    yyyy++                                            ;if (opt_v) print "   yyyy       =|"yyyy       "|"
  }
  ddddd += DD                                         ;if (opt_v) print "   ddddd      =|"ddddd      "|"

  #--------------------------------------------------------#
  # Add the previous month YTD days to our ddddd.  If it   #
  # is a leap year, assign julian_leap[] to accum_days[].  #
  # Then add in YTD days for previous months of this year  #
  #--------------------------------------------------------#
  if (leap_year(yyyy))
    for (i=0; i<13; i++) accum_days[i] = julian_leap[i]
  else
    for (i=0; i<13; i++) accum_days[i] = julian_days[i]
  ddddd += accum_days[MM += 0] # 'MM += 0' removes leading zero

  if (opt_v)
    print "==> return ("ddddd")"
               return ( ddddd )
} # function basedate

#----------------------------------------------------------------------#
function ddddd_to_yyyymmdd(DDDDD,                   ddddd,yyyy,mmdd,i) #
# -------------------------------------------------------------------- #
# Globals: julian_days[] and julian_leap[].                            #
#----------------------------------------------------------------------#
{
  if (opt_v)
  {
    print "ddddd_to_yyyymmdd(DDDDD)"
    print "ddddd_to_yyyymmdd("DDDDD")"
  }

  yyyy = ddddd = reduce(DDDDD)
  if (opt_v) print "yyyy = ddddd = "ddddd
  sub(/-.*$/,"", yyyy); yyyy  += 0 # "+= 0" ensures numeric context
  sub(/^.*-/,"",ddddd); ddddd += 0
  if (opt_v)
  {
    print "yyyy  = |"yyyy"|"
    print "ddddd = |"ddddd"|"
  }

  if (leap_year(yyyy))
    for (i in julian_leap)
      julian[i] = julian_leap[i]
  else
    for (i in julian_days)
      julian[i] = julian_days[i]

  #------------------------------------------------------------#
  # Reduce ddddd to month and day (we already have the year).  #
  #------------------------------------------------------------#
  for (i=13; i>0; i--)
  {
    if (opt_v)
    {
      print "if (julian["i"] < "ddddd")"
      print "if ("julian[i]" < "ddddd")"
    }
    if (julian[i] < ddddd)
    {
      ddddd -= julian[i]
      mmdd = sprintf("%02d%02d", i, ddddd)
      break
    }
  }

  if (opt_v)
  {
    print "return (yyyy\"\"mmdd)"
    print "return ("yyyy""mmdd")"
  }
           return ( yyyy""mmdd )
} # function ddddd_to_yyyymmdd

#----------------------------------------------------------------------#
function julian_table()
#----------------------------------------------------------------------#
{
  split("0 31 59 90 120 151 181 212 243 273 304 334 365", julian_days)
  split("0 31 60 91 121 152 182 213 244 274 305 335 366", julian_leap)
}

#----------------------------------------------------------------------#
function leap_year(YYYY) # YYYY = year.  Returns true|false (1|0).     #
#----------------------------------------------------------------------#
{
  return (((YYYY%4 == 0 && YYYY%100 != 0) || (YYYY%400 == 0)) ? 1 : 0)
} # function leap_year

#----------------------------------------------------------------------#
function reduce(DDDDD,           yyyy,ddddd,cc,leapdays,cc_leapdays,i) #
#----------------------------------------------------------------------#
{
  if (opt_v)
  {
    print "reduce(DDDDD)"
    print "reduce("DDDDD")"
  }

  for (i=1; ; i++)
  {                                            ;if (opt_v) print i". DDDDD      =|"DDDDD      "|"
    yyyy        = int(DDDDD / 365) - i         ;if (opt_v) print i". yyyy       =|"yyyy       "|"
    ddddd       = DDDDD - yyyy * 365           ;if (opt_v) print i". ddddd      =|"ddddd      "|"
    cc          = int(yyyy / 100)              ;if (opt_v) print i". cc         =|"cc         "|"
    leapdays    = int(yyyy / 4)                ;if (opt_v) print i". leapdays   =|"leapdays   "|"
    cc_leapdays = (cc > 0) ? (int(cc / 4)) : 0 ;if (opt_v) print i". cc_leapdays=|"cc_leapdays"|"
    leapdays    = leapdays - cc + cc_leapdays  ;if (opt_v) print i". leapdays   =|"leapdays   "|"
    ddddd      -= leapdays                     ;if (opt_v) print i". ddddd      =|"ddddd      "|"
    yyyy++                                     ;if (opt_v) print i". yyyy       =|"yyyy       "|"
    if (ddddd > 0) break
  }
  if (opt_v)
    print "return "yyyy"-"ddddd
           return  yyyy"-"ddddd
} # function reduce

#----------------------------------------------------------------------#
function shift_ARGV(i,j,k)                                             #
#----------------------------------------------------------------------#
{
  k = ARGC
  for (i=1; i<=ARGC; i++)
  {
    if (ARGV[i] == "")     # If the argument is empty, see is we
    {                      # can shift the next one down to it.
      for (j=i+1; j<=k; j++)
      {
        if (ARGV[j] == "") # If the next one is empty, try the one
          continue         # following that.
        ARGV[i] = ARGV[j]  # Once we find an argument, move it down,
        ARGV[j] = ""       # null where it was, decrement arg counter,
        break              # can do this with the next argument.
      }
    }
  }

  for (i=1; i<=k; i++)     # Adjust ARGC
    if (ARGV[i] == "")     # If the argument is empty,
      ARGC--               # decrement ARGC
  return ARGC
} # function shift_ARGV

#----------------------------------------------------------------------#
function sss_to_datetime(                                         \
                          SSS,                                    \
                          julian_days,julian_leap,days,sss,ddddd, \
                          yyyymmdd,yyyy,mm,dd,hh,mi,ss            \
                        )                                              #
                        # Global vars: julian_days and julian_leap)    #
#----------------------------------------------------------------------#
{ SSS -= 18000 # 18000 = 5 hour (ET) hour timezone adjustment from GMT
               # 21600 = 6 hour (CT)
               # 25200 = 7 hour (CT)
               # 28800 = 8 hour (PT)
  days = sprintf("%d",(SSS / 86400))
  sss  = sprintf("%d",(SSS % 86400))
  sub(/^-/,"",sss) # Remove any sign.
  int(sss)
  ddddd = (basedate(1970,01,01) + days)

  yyyymmdd = ddddd_to_yyyymmdd(ddddd)
  yyyy     = substr(yyyymmdd,1,4)
  mm       = substr(yyyymmdd,5,2)
  dd       = substr(yyyymmdd,7,2)

  hh  =  (sss / 3600.000000)
  sss =  (sss % 3600.000000)
  mi  =  (sss / 60.000000)
  ss  =  (sss % 60)
  return sprintf("%4s-%2s-%2s %02d:%02d:%02d", yyyy,mm,dd,hh,mi,ss)
} # function sss_to_datetime
