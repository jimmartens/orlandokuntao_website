#!/usr/local/bin/perl -w
#
# SccsId[] = "%W% (Perl user module) %G%"
#
#----------------------------------------------------------------------#
#                         Validate_yyyymmdd.pm                         #
# -------------------------------------------------------------------- #
#   Function documentation located at the bottom (follows __END__).    #
#----------------------------------------------------------------------#
  package Validate_yyyymmdd;

  use strict;
  use Exporter;

# use lib "$ENV{HOME}/perl_usr_lib"; ## T E S T ##
  use lib "/usr/local/perl_usr_lib"; ## Host's function library

  use vars qw(@ISA @EXPORT);
  @ISA       = qw(Exporter); # Inheritance Specifier Array
  @EXPORT    = qw(validate_yyyymmdd);
# @EXPORT_OK = qw();

#----------------------------------------------------------------------#
sub validate_yyyymmdd # Args: [-qx] yyyymmdd                           #
#----------------------------------------------------------------------#
{
  my $fn_name = "validate_yyyymmdd";
  use POSIX qw(uname);
  my $host =  (uname)[1];

  local $_; # Saves $_ and restores it on subroutine exit.

  my $opt_q = "";
  my $opt_x = "";
  foreach (@_)
  {
    shift if (/^$/);
    if (/^-/)
    {
      if    (/^-q/) { $opt_q = shift; }
      elsif (/^-x/) { $opt_x = shift; }
    }
  }

  my $surname  = "\U$host\E $0:$fn_name()";
  my $fn_usage = "Usage: $fn_name([-qx,] yyyymmdd)";
  my $msg      ;
  my $sp       = ' ' x 20; # Spaces

  #----------------------------------#
  # Rudmentary argument validation.  #
  #----------------------------------#
  if ($#_ < 0)
  {
     $msg = "${sp}$surname Insufficient args!\n${sp}$fn_usage\n";
     print "$msg" unless ($opt_q);
     ($opt_x) && exit 1 || return 0;
  }
  elsif ($_[0] !~ /^\d+$/ || length($_[0]) < 8)
  {
     $msg = "${sp}$surname Invalid date arg!\n${sp}$fn_usage\n";
     print "$msg" unless ($opt_q);
     ($opt_x) && exit 1 || return 0;
  }

  my @month_names =
  (
    "", # This element allows one-based usage.
    "January",  "February",  "March",
    "April",    "May",       "June",
    "July",     "August",    "September",
    "October",  "November",  "December"
  );

  #----------------------------------------#
  # Parse yyyy, mm, and dd from argument.  #
  #----------------------------------------#
  $_[0] =~ /^(\d{4})(\d{2})(\d{2})/;
  my $yyyy = $1;
  my $mm   = $2;
  my $dd   = $3;
  my $mm_days;

  #------------------------------------------------------#
  # Validate the month and day.  Start by determining    #
  # the maximum possible days for the month.  Then, see  #
  # if the day for the month given exceeds its maximum.  #
  #------------------------------------------------------#
  $mm_days = days_in_month($yyyy, $mm);
  if ($mm_days == 0)
  {
    $msg = "${sp}$surname Invalid month ($mm)!\n${sp}$fn_usage\n";
    print "$msg" unless ($opt_q);
    ($opt_x) && exit 1 || return 0;
  }

  if ($dd > $mm_days)
  {
    $msg = "${sp}$surname Invalid day!"
         . "\n${sp}$month_names[$mm], $yyyy does not have $dd days!"
         . "\n${sp}$fn_usage\n";
    ($opt_x) && exit(1) || return 0;
  }
  return 1; # Ahhh, the sweet smell of success.

  #====================================================================#
  #   I N T E R N A L    S U B R O U T I N E S  /  F U N C T I O N S   #
  #                      (in alphabetical order)                       #
  #--------------------------------------------------------------------#
  sub days_in_month # Args: yyyy and Month number 1-12 or 01-12
  #--------------------------------------------------------------------#
  {
    my ($yyyy, $mm) = @_;
    my $mm_days     = 0;

    if ($mm =~ /^0?(1|3|5|7|8|10|12)$/)
    {
      $mm_days = 31;
    }
    elsif ($mm =~ /^0?(4|6|9|11)$/)
    {
      $mm_days = 30;
    }
    elsif ($mm == 2)
    {
      $mm_days =
        ((($yyyy%4==0 && $yyyy%100!=0) || ($yyyy%400==0)) ? 29 : 28);
    }
    return $mm_days;
  } # sub days_in_month
}
1;

__END__
=pod

=head1 NAME

 validate_yyyymmdd - Tests validity of yyyymmdd

=head1 SYNOPSIS

 validate_yyyymmdd(['-qx',] yyyymmdd)

   -q = Quits/returns quietly on error.
   -x = Exits with '1' status on error.

=head1 EXAMPLES

 if (! validate_yyyymmdd("$yyyymmdd"))
 {
    print "$surname Bogus date ($yyyymmdd)!\n",
          "Usage: $fn_name(yyyymmdd)!\n";
    return 9;
 }

 --- or ---

 return (validate_yyyymmdd("$yyyymmdd")); # Return true or false.

 --- or ---

 validate_yyyymmdd('-x', "20010229"); # Exits as this is invalid.
 validate_yyyymmdd('-q', "20010229"); # Quietly returns zero (false).

=head1 RETURNS

 Returns 1 on true
      or 0 on false or error.

=head1 AUTHOR

 Bob Orlando (Bob@OrlandoKuntao.com http://www.OrlandoKuntao.com)

=head1 DATE/VERSION

 %G% / %I%

=head1 HISTORY

 2004-11-20 Bob Orlando
    v1.4  * Remove code that e-mails error notification.
          * Make module as standalone as possible by
            removing calls to other local modules.
=cut
