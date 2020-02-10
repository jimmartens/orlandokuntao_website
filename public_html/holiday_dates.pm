#!/usr/local/bin/perl -w
#
# SccsId[] = "@(#)holiday_dates.pm 1.3 12/23/05 (Holiday Dates and Business Day Perl Module)"
#
#----------------------------------------------------------------------#
#                           Holiday_dates.pm                           #
# -------------------------------------------------------------------- #
#                                                                      #
#   Copyright (c) 2003-2005 by Bob Orlando.  All rights reserved.      #
#                                                                      #
#   Permission to use, copy, modify and distribute this software       #
#   and its documentation for any purpose and without fee is hereby    #
#   granted, provided that the above copyright notice appear in all    #
#   copies, and that both the copyright notice and this permission     #
#   notice appear in supporting documentation, and that the name of    #
#   Bob Orlando not be used in advertising or publicity pertaining     #
#   to distribution of the software without specific, written prior    #
#   permission.  Bob Orlando makes no representations about the        #
#   suitability of this software for any purpose.  It is provided      #
#   "as is" without express or implied warranty.                       #
#                                                                      #
#   BOB ORLANDO DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS           #
#   SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY      #
#   AND FITNESS.  IN NO EVENT SHALL BOB ORLANDO BE LIABLE FOR ANY      #
#   SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES          #
#   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER    #
#   IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,     #
#   ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF     #
#   THIS SOFTWARE.                                                     #
#                                                                      #
# -------------------------------------------------------------------- #
#   Function documentation located at the bottom (follows __END__).    #
#----------------------------------------------------------------------#
  package Holiday_dates;

  use strict;
  use Exporter;

  use vars qw($VERSION);
  $VERSION = '%I%';

  use vars qw(@ISA @EXPORT @EXPORT_OK);
  @ISA       = qw(Exporter);        # Inheritance Specifier Array
  @EXPORT    = (
                'holiday_dates'   , # holiday_fileid [,yyyy]
                'holiday_yyyymmdd', # yyyymm, occurrence, wkday_num
                'is_holiday'      , # yyyy, mm, dd
                'business_day'    , # day, yyyymm, href
                'day_of_week'     , # yyyy, mm, dd
                'validate_date'   , # yyyy, mm, dd
               );

  @EXPORT_OK = (
                'days_in_month'   , # yyyy, mm
                'nth_day'         , # DayNum
                'rcalc_yyyymmdd'  , # Seconds
                'weekday_num'     , # yyyy, mm, dd
               );

#----------------------------------------------------------------------#
sub holiday_dates # Args: holiday_fileid [,yyyy]                       #
                  # Returns pointer to %holidays hash array.           #
#----------------------------------------------------------------------#
{
  local $_; # Saves $_ and restores it on subroutine exit.

  use Time::Local;
  use vars qw(%holidays);
  my $fn_name  = "holiday_dates";
  my $fn_usage = "Usage: $fn_name(holiday_fileid, [,yyyy])\n";
  my $msg      = "";
  my $yyyy         ;
  my $key          ;
  my $holiday_file ;

  #------------------------------------------------------------#
  # The following loop assigns variables essentially by type,  #
  # Leaving the user free to provide argumentss in any order.  #
  #------------------------------------------------------------#
  foreach (@_)
  {
    if ($_ =~ /^\d{4}$/)
     { $yyyy         = $_; }
    else
     { $holiday_file = $_; }
    next;
  }

  $holiday_file ||= "holidays"; # I'd really rather have one provided.
  $yyyy ||= (localtime(time))[5] + 1900; # Use curr year if not given.

  if (! -f $holiday_file)
  {
    $msg = "$fn_name: Holiday file ($holiday_file) not found!\n";
  }
  elsif (-z -f $holiday_file)
  {
    $msg = "$fn_name: Holiday file ($holiday_file) empty!\n";
  }

  #------------------------------------------------------------#
  # If $msg is assigned anywhere in the preceeding tests, then #
  # we let our exit/return status indicate we have a problem.  #
  #------------------------------------------------------------#
  if ($msg)
  {
    print "${msg}$0 terminated!\n";
    return 0;
  }

  unless (open(HOLIDAYS, "<$holiday_file"))
  {
    print "$fn_name: Open \"<$holiday_file\" failed!\n$0 terminated!\n";
    return 0;
  }

  while (<HOLIDAYS>)
  {
    my $sss           = 0;
    my $adj_sss       = 0;
    my $wkdy          = 7;
    my $yyyymmdd         ;
    my $next_yyyy        ;
    my $next_yyyymmdd    ;
    my $new_years_day = 0;
    #------------------------------------------------------------#
    # Run thru the file assigning valid lines to ref'd hash.     #
    #------------------------------------------------------------#
    chomp;
    $_ =~ s/\x23.*//;        # Trash everything after pound sign \x23.
    $_ =~ s/^\s+//;          # Remove leading blanks.
    $_ =~ s/\s+$//;          # Remove trailing blanks.
    next if ($_ =~ /^\s*$/); # Skip essentially blank lines.

    if    ($_ =~ /^([01]?[0-9])\s+(0?[1-5]|last)\.(\d+(\.\d+)*)\s+.*/)
    { #               m   m        Occurrence    . Wkd  .OoA    et al
      #             $1........|    $2.........|    $3.|$4...|
      $yyyymmdd = holiday_yyyymmdd("${yyyy}$1","$2","$3");
      return 0 if ($yyyymmdd == 0);
    }
    elsif ($_ =~ /^([01]?[0-9])\s+([0-3]?[0-9])\s+.*/)
    { #               m   m           d   d       holiday
      $yyyymmdd = sprintf("%4d%02d%02d", $yyyy, $1, $2);
      #----------------------------------------------------------#
      # Need New Year's day for next year for Dec. last bizday.  #
      #----------------------------------------------------------#
      if ($1 == 1 and $2 == 1)
      {
        $new_years_day = 1;
        $next_yyyy     = $yyyy + 1;
        $next_yyyymmdd = sprintf("%4d%02d%02d", $next_yyyy, $1, $2);
      }
      else
      {
        undef $next_yyyymmdd;
      }
    }

    foreach my $yyyymmdd ($yyyymmdd, $next_yyyymmdd)
    {
      next unless (defined($yyyymmdd));

      #------------------------------------------------------------#
      # If we have a pattern that looks like [0-6][+\-][0-9]+ (an  #
      # adjustment pattern), then convert $yyyymmdd (assigned just #
      # above) to epoch seconds, and convert those secs back to    #
      # the day of the week [0-6] on which our date falls.         #
      #------------------------------------------------------------#
      if ($_ =~ /\s+0?[0-6]?[+\-]\d{1,2}/)
      {
        $sss  = date_to_seconds($yyyymmdd);
        $wkdy = date_to_weekday($yyyymmdd);
      }

      if ($_ =~ /^(\d+)\s+(\d+|last)\.(\d+(\.\d+)*)\s+([0-6])([+\-]\d+)\s+(.*)/)
      {         # $1..|   $2.......|   $3|  . $4|     $5....| $6.......|   $7
                # Mm      N          . Wkdd .OoA      [0-6 ]   +|-$days   Holiday
        $adj_sss = $sss + (86400 * $6); # Convert days to seconds
        $key     = recalc_yyyymmdd($adj_sss);
        #----------------------------------------------------------#
        # If the weekday for that date ($wkday) actually falls     #
        # on the day of the week in question ($5), then use the    #
        # adjustment value ($6) to determine the business-observed #
        # holiday date.                                            #
        #----------------------------------------------------------#
        $holidays{$key} = $7 if ($wkdy == $5);
      }
      elsif ($_ =~ /^(\d+)\s+(\d+|last)\.(\d+(\.\d+)*)\s+([+\-]\d+)\s+(.*)/)
      {            #  $1      $2          $3     $4       $5           $6
                   #  Mm      N         . Wkd  . OnOr      +|-$days    Holiday
        $adj_sss = $sss + (86400 * $5); # Convert days to seconds
        $key     = recalc_yyyymmdd($adj_sss);
        $holidays{$key} = $6;
      }
      elsif ($_ =~ /^(\d+)\s+(\d+|last)\.(\d+(\.\d+)*)\s+(.*)/)
      {            #  $1      $2          $3   $4         $5
                   #  Mm      N         . Wkd  .OnOr      holiday-name
        $key = $yyyymmdd;
        $holidays{$key} = $5;
      }
      elsif ($_ =~ /^(\d+)\s+(\d+)\s+([0-6])([+\-]\d+)\s+(.*)/)
      {            #  $1      $2      $3     $4           $5
                   #  Mm      dd      [0-6]  +|-$days     Holiday
        #--------------------------------------------------------------#
        # If the weekday for that date ($wkday) actually falls on the  #
        # day of the week in question ($3), then use the adjustment    #
        # value ($4) to determine the business-observed holiday date.  #
        #--------------------------------------------------------------#
        if ($wkdy == $3)
        {
          $adj_sss = $sss + (86400 * $4); # Convert days to seconds
          $key     = recalc_yyyymmdd($adj_sss);
          $holidays{$key} = $5;
        }
      }
      elsif ($_ =~ /^(\d+)\s+(\d+)\s+(.*)/) # Simplest case.
      {            #  $1      $2      $3
                   #  Mm      dd      holiday-name
        $key = sprintf("%4d%02d%02d", $yyyy, $1, $2);
        $holidays{$key} = $3;
      }
      else
      {
        $msg = "$fn_name: $holiday_file line\n"
             . "'$_'\n"
             . "Does not match acceptable date parameter!\n"
             . "$0 terminated!\n";
        print "$msg";
        return 0;
      }
    } # foreach my $yyyymmdd ($yyyymmdd, $next_yyyymmdd)
  } # while (<HOLIDAYS>)

  unless (close(HOLIDAYS))
  { # No exit here--failure to close the file is not a show stopper.
    print "$fn_name: WARNING--Close $holiday_file failure! $!\n";
  }

  return \%holidays;
} # sub holiday_dates

#======================================================================#
#             S U B R O U T I N E S  /  F U N C T I O N S              #
#                       (in alphabetical order)                        #
#----------------------------------------------------------------------#
sub business_day # Args:    day, yyyymm, holidays_href                 #
                 # Returns: yyyymmdd for business day requested.       #
#----------------------------------------------------------------------#
{
  local $_; # Saves $_ and restores it on subroutine exit.
  my $fn_name  = "business_day";
  my $fn_usage = "Usage: $fn_name(day, yyyymm, holidays_href)\n"
               . "                 day = nth business day of yyyymm.\n"
               . "              yyyymm = year and month.\n"
               . "       holidays_href = Reference to holidays hash.\n";
  my $msg      ;
  my ($n, $yyyymm, $holidays_href) = @_;
  unless (%{$holidays_href})
  {
    $msg =   "#----------------------------------------------------#"
         . "\n| Calling '$fn_name($n, $yyyymm, $holidays_href)'"
         . "\n|    without benefit of a holidays hash array!"
         . "\n|"
         . "\n| For accurate business day determination, please"
         . "\n|    call &holiday_dates() with a holidays file"
         . "\n|   or otherwise populate a holidays hash first."
         . "\n|"
         . "\n| Without the holidays hash, only M-F days can be"
         . "\n| reported, with no assurance it is not a holiday."
         . "\n#----------------------------------------------------#"
         . "\n\nProcessing continues.\n";
    print STDERR $msg;
  }

  #----------------------------------------------------------------#
  # Rudimentary argument validation.                               #
  #----------------------------------------------------------------#
  if ($#_ < 2) # Three arguments required.
  {
    $msg = "Insufficient arguments!\n$fn_usage";
  }
  elsif ($yyyymm !~ /^\d{6}$/) # Must be six digits
  {
    $msg = "Invalid yyyymm date argument ($yyyymm)!\n$fn_usage\n";
  }
  elsif ($n !~ /^(-?\d+|last)$/i)
  {
    $msg = "Invalid day number ($n)!"
         . "\n(Must be [-]integer or 'last'.)\n$fn_usage\n";
  }

  #--------------------------------------------------------------#
  # If $msg is assigned anywhere along the preceeding if-blocks, #
  # then print $msg and return false (0).                        #
  #--------------------------------------------------------------#
  if ($msg)
  {
    print "$msg";
    return 0;
  }

  #--------------------------------------------------------------#
  # Since holidays are not likely to occur on the same day, we   #
  # can truncate each key to 8 characters (removing the sequence #
  # number that was appended to each).  This way they'll match   #
  # my "exists" test below.                                      #
  #--------------------------------------------------------------#
  my ($new_key, $key, $value);
  while (($key, $value) = each %{$holidays_href})
  {
    delete ${$holidays_href}{$key};       # Remove old key from hash.
    $new_key = $key;                      # Save original key
    $new_key =~ s/^(\d{8}).*/$1/;         # Truncate new key
    ${$holidays_href}{$new_key} = $value; # Assign new key to hash
  }

  #----------------------------------------------------#
  # Now we use holiday_yyyymmdd to determine if today  #
  # is nth workday or business day of the month.       #
  #----------------------------------------------------#
  my $bizday;
  my @bizdays;

  for (my $p=1; $p<6; $p++) # Occurrences (1-5)
  {
    for (my $q=1; $q<6; $q++)  # Weekday (1-5)
    {
      last unless ($bizday = holiday_yyyymmdd("$yyyymm", $p, $q));

      #------------------------------------------------------#
      # Unless it's a holiday or already in @bizdays array,  #
      # and $bizday to @bizdays.                             #
      #------------------------------------------------------#
      unless (exists ${$holidays_href}{$bizday} or grep(/$bizday/,@bizdays))
      {
        push(@bizdays, $bizday);
      }
    } # for ($q=1; ...
  } # for ($p=1; ...

  #----------------------------------------------------------------#
  # User requested "last" or negative business day, so adjust $n.  #
  #----------------------------------------------------------------#
  if ($n =~ /^last$/)
    { $n = $#bizdays + 1     ; } # @bizdays size + 1.
  elsif ($n < 0)
    { $n = $#bizdays + 1 + $n; } # @bizdays size + negative number.

  return (sort(@bizdays))[$n-1]; # Returns yyyymmdd
} # sub business_day

#----------------------------------------------------------------------#
sub date_to_seconds # Args: yyyymmdd                                   #
#----------------------------------------------------------------------#
{
  return (timelocal(
                     0, 0, 0,               # ss, mi, hh
                     substr($_[0],6,2),     # dd
                     substr($_[0],4,2)-1,   # mm (0-11)
                     substr($_[0],0,4)-1900 # yyyy
                   )
         );
} # sub date_to_seconds

#----------------------------------------------------------------------#
sub date_to_weekday # Args: yyyymmdd                                   #
#----------------------------------------------------------------------#
{
  return (localtime
           (timelocal(
                       0, 0, 0,               # ss, mi, hh
                       substr($_[0],6,2),     # dd
                       substr($_[0],4,2)-1,   # mm (0-11)
                       substr($_[0],0,4)-1900 # yyyy
                     )
           )
         )[6]; # Return only 6th offset, day of week (0-6)
} # sub date_to_weekday

#----------------------------------------------------------------------#
sub days_in_month # Args: yyyy, mm (mm = 1-12 or 01-12)                #
#----------------------------------------------------------------------#
{
  my ($yyyy, $mm) = @_;
  my $mm_days =     0;

  if ($mm =~ /^0?(1|3|5|7|8|10|12)$/)
  {
    $mm_days = 31;
  }
  elsif ($mm =~ /^0?(4|6|9|11)$/)
  {
    $mm_days = 30;
  }
  elsif ($mm == 2) # If February and leap year.
  {
    $mm_days =
      ((($yyyy%4==0 && $yyyy%100!=0) || ($yyyy%400==0)) ? 29 : 28);
  }
  return $mm_days;
} # sub days_in_month

#----------------------------------------------------------------------#
sub day_of_week # Args: yyyy, mm, dd. Returns 0-6 (Sunday-Saturday).   #
                # Calls: &validate_date                                #
#----------------------------------------------------------------------#
{
  my ($yyyy, $mm, $dd) = @_;

  return 0 if (validate_date($yyyy, $mm, $dd) == 0);

  #------------------------------------------------------------#
  # Calculate and return weekday number (0-6, Sunday-Saturday).#
  #------------------------------------------------------------#
  my $a = int((14 - $mm) / 12);
  my $y = $yyyy - $a;
  my $m = $mm + (12 * $a) - 2;
  return int(($dd+$y+int($y/4)-int($y/100)+int($y/400)+(31*$m)/12)%7);
} # sub day_of_week

#----------------------------------------------------------------------#
sub holiday_yyyymmdd # Args: yyyymm, occurrence|'last', wkday_num.OoA  #
                     #       (where 'OoA' means "On or After")         #
                     # Calls: &validate_date                           #
#----------------------------------------------------------------------#
{
  local $_; # Saves $_ and restores it on subroutine exit.

  my $fn_name  = "holiday_yyyymmdd";
  my $fn_usage = "Usage: $fn_name(yyyymm, occurrence|'last', "
               . "weekday_num)\n";

  use vars qw (@month_names);
  @month_names =
  (
    "", # Empty first (0th) element allows one-based dereferencing.
    "January",  "February",  "March",
    "April",    "May",       "June",
    "July",     "August",    "September",
    "October",  "November",  "December"
  );

  my $n            =  $_[1]; # 1st, 2nd, .. 5th or "last" day of the month.
     $n           +=  0 if ($n =~ /^\d+$/); # Drop leading zeros if numeric.
  my $day          =  $_[2];     # Weekday (0=Sunday, 1=Monday, etc.).
     $day          =~ s/\.+.*//; # Remove anything after '.'
     $day         +=  0;         # Drop leading zeros.
  my $on_or_after  =  $_[2] if ($_[2] =~ /\./);
     $on_or_after  =~ s/^.*\.// if ($on_or_after);
     $on_or_after  =  1     unless ($on_or_after);
  my $msg          = ""; # If it's "" when we're done, then we're OK.
  my $mm_days;
  my $status ;
  my $nth    ;
  my $yyyy   ;
  my $yy     ;
  my $mm     ;
  my $dd     ;

  #--------------------------------#
  # Validate args.                 #
  #--------------------------------#
  if ($#_ < 2)
  {
    $msg = "$fn_name(@_): Insufficient arguments!\n$fn_usage\n";
  }
  elsif ($_[0] !~ /^\d{6}$/) # yyyymm must be six digits
  {
    $msg = "$fn_name(@_): Invalid date argument ($_[0])!\n$fn_usage\n";
  }
  elsif ($day !~ /^\d$/)     # Must be single digit
  {
    $msg = "$fn_name(@_): Non-numeric week day number/argument!"
         . "\n$fn_usage\n";
  }
  elsif ($day > 6 || $day < 0)
  {
    $msg = "$fn_name(@_): Invalid day of the week ($day)!"
         . "\n(Must be an integer, 0-6.)\n$fn_usage\n";
  }
  elsif ($n =~ /^last$/i)
  {
    ; # This just lets you know we are handling "last"
  }
  elsif ($n !~ /^\d$/ && ($n > 5 || $n < 1))
  {
    $msg = "$fn_name(@_): Invalid occurrence ($n)!"
         . "\n(Must be an integer, 1-5 or \"last\".)"
         . "\n$fn_usage\n";
  }

  #------------------------------------------------------------#
  # If $msg is assigned anywhere in the preceeding tests, then #
  # we let our exit/return status indicate we have a problem.  #
  #------------------------------------------------------------#
  if ($msg)
  {
    print "$msg";
    return 0;
  }

  #---------------------------------#
  # Parse yyyy and mm from 1st arg. #
  #---------------------------------#
  $_[0] =~ /^(\d{4})(\d{2})/;
  $yyyy = $1;
  $mm   = $2;

  if ($mm < 0 || $mm > 12)
  {
    print "$fn_name: Invalid month number ($mm)!\n$fn_usage\n";
    return 0;
  }

  $mm_days = days_in_month($yyyy, $mm);

  #----------------------------------------------------------------#
  # Ensure $on_or_after + 7 does not exceed month's days.          #
  #----------------------------------------------------------------#
  unless ($on_or_after > 1 and $on_or_after+7 > days_in_month($yyyy,$mm))
  {
    #----------------------------------------------------------------#
    # Passed validation, return the day of the month.  If user wants #
    # the last N-day, then get the number of days for that month and #
    # calculate the day using it.                                    #
    #----------------------------------------------------------------#
    if ($n eq "last") # Last occurrence of day wanted.
    {
      for (my $n=5; $n>3; $n--)
      {
        $dd = $mm_days - (weekday_num($yyyy, $mm, $mm_days) - $day)%7;
        last if ($dd <= $mm_days);
      }
    }
    elsif ($n == 5) # 5th occurrence (not necessarily the "last").
    {
      $dd = $mm_days - (weekday_num($yyyy, $mm, $mm_days) - $day)%7;
    }
    else # User only wants the $n day of the month.
    {
      $dd = 1 + ($n-1)*7 + ($day - weekday_num($yyyy, $mm, 01))%7;
    }
    $dd += 7 if ($dd < $on_or_after);

    $dd = sprintf("%02d", $dd);
    return "${yyyy}${mm}$dd" if (validate_date($yyyy, $mm, $dd));
  }

  #--------------------------------------------------------------#
  # Reaching this point means that the 5th week date is invalid, #
  # so we inform the user and return 0 (failure)                 #
  #--------------------------------------------------------------#
  $nth = nth_day($n);
  $msg = "The $nth occurrence of day $day ";
  if ($on_or_after > 1)
  {
    $nth = nth_day($on_or_after);
    $msg .= "(on or after $month_names[$mm] $nth) ";
  }

  $msg .= "exceeds $month_names[$mm]\'s $mm_days days!\n";
  print "$msg";

  return 0;
} # sub holiday_yyyymmdd

#----------------------------------------------------------------------#
sub is_holiday # Args: yyyy, mm, dd,                                   #
               # Calls: &validate_date                                 #
#----------------------------------------------------------------------#
{
  my $fn_name  = "is_holiday";
  my $fn_usage = "Usage: $fn_name(yyyy, mm, dd)\n";
  my $msg;
  if ($#_ < 2)
  {
    print "$fn_name(@_): Insufficient arguments!\n$fn_usage\n";
    return 0;
  }

  my ($yyyy, $mm, $dd) = @_;

  return 0 unless (validate_date($yyyy, $mm, $dd));

  unless (%holidays)
  {
    $msg =   "#----------------------------------------------------#"
         . "\n| Calling '$fn_name(yyyy,mm,dd)' without benefit"
         . "\n|      of a holidays hash array (%holidays)!"
         . "\n|"
         . "\n| To determine if any date is a holiday, you must"
         . "\n|    call &holiday_dates() with a holidays file"
         . "\n|   or otherwise populate a holidays hash first."
         . "\n#----------------------------------------------------#"
         . "\n\n$fn_name terminated.\n";
    print STDERR $msg;
    return 0;
  }

  #----------------------------------------#
  # Using loop in case keys are suffixed.  #
  #----------------------------------------#
  foreach my $key (keys(%holidays))
   { return 1 if ($key =~ /^${yyyy}${mm}${dd}/); }
# return (exists %holidays{"${yyyy}${mm}${dd}"}) ? 1 : 0;
} # sub is_holiday

#----------------------------------------------------------------------#
sub nth_day # Args: Day number                                         #
#----------------------------------------------------------------------#
{
  my $n   = $_[0];
  my $nth = "${n}th"; # Assume "th" works unless changed below.
  if    ($n =~  /1$/ ) { $nth = "${n}st"; }
  elsif ($n =~  /2$/ ) { $nth = "${n}nd"; }
  elsif ($n =~  /3$/ ) { $nth = "${n}rd"; }
  elsif ($n eq "last") { $nth = "${n}"  ; }
  return $nth;
} # sub nth_day

#----------------------------------------------------------------------#
sub recalc_yyyymmdd # Returns yyyymmdd for the sss arg received.       #
#----------------------------------------------------------------------#
{
  my ($ss,$mi,$hh,$dd,$mm,$yy,$wdayn,$jjj,$dst) = localtime($_[0]);
  my $yyyy = $yy + 1900;
     $mm   = sprintf("%02d", $mm+1); # Convert to 2-digit 1-based $mm.
     $dd   = sprintf("%02d", $dd  ); # Convert to 2-digit $dd.
  return "${yyyy}${mm}${dd}";
} # sub recalc_yyyymmdd

#----------------------------------------------------------------------#
sub validate_date # Args: yyyy, mm, dd                                 #
                  # Global Vars: @month_names                          #
#----------------------------------------------------------------------#
{
  my $fn_name = "validate_date";
  my ($yyyy, $mm, $dd) = @_;
  my $mm_days;

  #----------------------------------------------------#
  # Validate the month and day.  Begin by determining  #
  # the maximum possible days for the month.           #
  #----------------------------------------------------#
  $mm_days = days_in_month($yyyy, $mm);
  if ($mm_days == 0)
  {
    print "$fn_name(@_): Invalid month ($mm)!\n";
    return 0;
  }

  #----------------------------------------------------#
  # See if $dd exceeds the given month's days?         #
  #----------------------------------------------------#
  if ($dd > $mm_days)
  {
    print "$fn_name(@_): Invalid day!",
          "\n$month_names[$mm], $yyyy does not have $dd days!\n\n";
    return 0;
  }

  return 1; # Ahhh, the sweet smell of success.
} # sub validate_date

#----------------------------------------------------------------------#
sub weekday_num # Args: yyyy, mm, dd.  Returns 0-6 (Sunday-Saturday).  #
                # Calls: &validate_date                                #
#----------------------------------------------------------------------#
{
  my ($yyyy, $mm, $dd) = @_;

  return 0 unless (validate_date($yyyy, $mm, $dd));

  #--------------------------------------------------------------#
  # Calculate and return weekday number (0-6, Sunday-Saturday).  #
  #--------------------------------------------------------------#
  my $a = int((14 - $mm) / 12);
  my $y = $yyyy - $a;
  my $m = $mm + (12 * $a) - 2;
  return int(($dd+$y+int($y/4)-int($y/100)+int($y/400)+(31*$m)/12)%7);
} # sub weekday_num
1;

__END__
=pod

=head1 NAME

 holiday_dates -- Loads holiday array from a holiday file.

=head1 AUTHOR

 Bob Orlando (Bob@OrlandoKuntao.com http://www.OrlandoKuntao.com)

=head1 SYNOPSIS

 holiday_dates(fileid [, yyyy])

            fileid = File containing holidays.
              yyyy = Optional year to use for date calculations.

=head1 DESCRIPTION

 Holiday_dates.pm is the Perl version of my holidays.awk program.
 It is a combination of three separate (earlier "personal") modules,
 Holiday_date.pm, Load_holiday_array.pm, and Business_day.pm.

 +-------------------------------------------------------------+
 |      * * * THIS MODULE CENTERS ON A HOLIDAY FILE * * *      |
 +-------------------------------------------------------------+

 Central to this program is a holiday file which provides the needed
 flexibility in the application without actually hard-coding holiday
 dates and names within the program.  For example, Martin Luther King
 Day need only be specified in the holidays file as the third Monday
 in January.  The Perl program returns that date along with all other
 date specifications found in the file.  Once the year's holidays are
 known, then requesting the nth business day of the month (another
 feature of this module) is easy.

 Using a holiday file (see "HOLIDAY FILE EXAMPLE" below), we first
 load a holidays hash array using the directives presented in the
 specified holidays file.  Holidays that fall on a nth week and
 nth day of that week of a given month like Martin Luther King Day,
 Memorial Day, Labor Day, and Thanksgiving, are handled using a date
 algorithm that takes a week.day value like "04.04" and returns the
 4th day in week number 4, or Thursday (days are 0-6, with Sunday
 being day zero).  This then, is how we calculate Thanksgiving Day.

 Business holiday adjustments for fixed-date holidays that fall on
 weekends are handled by specifying a weekday (0-6) and a positive
 or negative adjustment value.  For example, if Christmas falls on
 on a Saturday (day 6), the "6-1" (6 - 1 = 5) shifts the business
 observance back a day to Friday (day 5). If Christmas falls on a
 Sunday (day 0), the "0+1" advances the business observance to
 Monday (day 1).

=head1 EXAMPLES

 -------------------------------------------------------------------
 holiday_dates() # Returns pointer (hash reference) to holidays
                 # hash array or zero on error.

   # The following assumes the current year.
   my $holiday_href = holiday_dates($holiday_file);

   # This one provides the year as well.
   my $holiday_href = holiday_dates($yyyy, $holiday_file);

 -------------------------------------------------------------------
 holiday_yyyymmdd() # Returns yyyymmdd date or zero on error.

   $sav_time = holiday_yyyymmdd("${yyyy}04", 1,0); # 1st Sun.

   $std_time = holiday_yyyymmdd("${yyyy}10","last",0); # Last Sun.

   $election = holiday_yyyymmdd("${yyyy}11", 1,1)+1 # Tue after 1st Mon.

 -------------------------------------------------------------------
 is_holiday() # First call &holiday_dates to load holiday hash
              # if &is_holiday is to accurately report a holiday.

   if (is_holiday("$yyyy", "$mm", "$dd"))
   {
     print "Today is a holiday. Enjoy.\n";
   }

 -------------------------------------------------------------------
 business_day() # Call &holiday_dates to load holiday hash before
                # calling &business_day.

   $bizday = business_day(1,      "${yyyy}$mm", $holidays_href);

   $bizday = business_day("last", "${yyyy}$mm", $holidays_href);

=head1 RETURNS

 1 = success
 0 = error

=head1 HOLIDAY FILE EXAMPLE

 #-----------------------------------------------------------#
 #   DO NOT REMOVE   *   DO NOT REMOVE   *   DO NOT REMOVE   #
 #-----------------------------------------------------------#
 # This file contains values that allow any program to       #
 # calculate holidays using either fixed month and day or by #
 # specifying an occurrence in a month like the 4th Thursday #
 # in November or "last" Monday in May.  Adjustments also    #
 # are permitted for those fixed holiday dates that fall on  #
 # weekends but are observed either the Friday before or the #
 # Monday after, as well as days like the Friday after the   #
 # Thanksgiving Day observance (U.S.).                       #
 #                                                           #
 # Leading whitespace is ignored, as is everything following #
 # and including the octothorpe (#-sign).                    #
 #                                                           #
 # Mm N.D.OnOrA Adj Holiday name            # Comments       #
 # -- --------- --- ----------------------- ---------------- #
   01  1            New Year's              # M-F
   01  1        6-1 New Year's (pre-obs)    # Sat? Use Fri
 # 01  1        6+2 New Year's (post-obs)   # Sat? Some use Mon
   01  1        0+1 New Year's (post-obs)   # Sun? Use Mon
   01  3.1          M.L.King Jr. Birthday   # 3rd Mon in Jan
   05  last.1       Memorial Day            # Last Mon in May
   07  4            Independence            # M-F
   07  4        6-1 Independence (pre-obs)  # Sat? Use Fri
   07  4        0+1 Independence (post-obs) # Sun? Use Mon
   09  1.1          Labor Day               # 1st Mon in Sep
   11  4.4          Thanksgiving (US)       # 4th Thu in Nov
   11  4.4       +1 Thanksgiving Day II
   12 25            Christmas               # M-F
   12 25        6-1 Christmas (pre-obs)     # Sat? Use Fri
   12 25        0+1 Christmas (post-obs)    # Sun? Use Mon

 #-----------------------------------------------------------#
 # Other noteworthy U.S. dates (not necessarily holidays).   #
 #-----------------------------------------------------------#
 # 01 last.0        Superbowl Sunday        # Last Sun in Jan
 # 02 3.1           Washington's Birthday   # 3rd Mon in Feb
 # 04 1.0           Daylight Savings Time   # 1st Sun in Apr
 # 04 6             Army Day
 # 05 2.0           Mother's Day            # 2nd Sun in May
 # 05 3.6           Armed Forces Day        # 3rd Sat in May
 # 05 30            Memorial Day (Traditional)
 # 06 14            Flag Day
 # 06 3.0           Father's Day            # 3rd Sun in Jun
 # 06 4.0           Parent's Day            # 4th Sun in Jun
 # 08 1             Air Force Day
 # 08 4             Coast Guard Day
 # 09 11            Patriot's Day
 # 09 17            Constitution Day
 # 09 1.1        +6 Grandparent's Day       # 1st Sun after Labor Day
 # 10 2.1           Columbus Day            # 2nd Mon in Oct
 # 10 27            Navy Day
 # 10 last.0        Standard Time           # Last Sun in Oct
 # 11 1.1        +1 Election Day            # 1st Tue after 1st Mon
 # 11 10            Marine Corps Birthday   # 1775
 # 11 11            Veteran's Day

 #-----------------------------------------------------------#
 # Unique dates.                                             #
 #-----------------------------------------------------------#
 # 04  1.0.6        Falklands ST Begins     # 1st Sun on/after Apr 6
 # 09  1.0.8        Falklands DST Begins    # 1st Sun on/after Sep 8

=head1 DATE/VERSION

 %G% / %I%

=head1 NOTES

 This module is extensively documented using descriptive
 variable names.  I did this for two reasons: First, because
 I am a teacher.  I hope that what I have done here helps
 others learn.  Second, maintenance--I simply don't have to
 recall something I've written down.

=head1 CREDITS

 The algorithms used here are essentially those found
 at http://www.smart.net/~mmontes/ushols.html#ALG
 (Marcos J. Montes).  Montes himself credits Claus Tondering
 (http://www.tondering.dk/claus/calendar.html) for the
 algorithm, and Timothy Barmann and Bobby Cossum for
 their contributions in simplifying the equations used.
 Those gentlemen did the really hard work.

=head1 CHANGE HISTORY

 2005-12-23 Bob Orlando
    v1.3  * Change
              $on_or_after  =~ s/^.*\.//;
            to
              $on_or_after  =~ s/^.*\.// if ($on_or_after);

 2005-10-25 Bob Orlando
    v1.2  * Add an "on or after" extension to the "N.D
            field in the holidays file (i.e. "N.D.OnOrA")
            so the user can specify a given occurrence or
            week number (N) and the weekday (D) within
            that week, AND also indicate that the date
            must fall "on or after" a given day of the
            month (OnOrA).

 2004-12-30 Bob Orlando
    v1.1  * Bug fix: Add calculation of next year's New Year's
            holiday since that affects the calculation of the
            last business day in December.

 2004-11-27 Bob Orlando
    v1.0  * Initial Release
=cut
