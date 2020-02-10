#!/usr/local/bin/perl -w
#
# SccsId[] = "%W% (Perl user module) %G%"
#
#----------------------------------------------------------------------#
#                            Print_hash.pm                             #
# -------------------------------------------------------------------- #
#   Function documentation located at the bottom (follows __END__).    #
#----------------------------------------------------------------------#
   package Print_hash;

   use strict;
   use Exporter;

## use lib "$ENV{HOME}/perl_usr_lib"; ## T E S T ##
   use lib "/usr/local/perl_usr_lib"; ## Host's function library

   use EXIT;
   use Echo;
   use Email;
   use Interactive;

   use vars qw(@ISA @EXPORT);
   @ISA       = qw(Exporter); # Inheritance Specifier Array
   @EXPORT    = qw(print_hash);
 # @EXPORT_OK = qw();

#----------------------------------------------------------------------#
sub print_hash # Expects hash name (e.g. "\%par [, ..]").              #
#----------------------------------------------------------------------#
{
   my $fn_name = "print_hash";
   use POSIX qw(uname);
   my $host =  (uname)[1];
   my $opt_x=0; ($opt_x, @_) = @_ if ($_[0] eq '-x'); # Function option.
   my $progID;
      $progID = (defined($main::progID)) ? $main::progID : $0;
   my $opt_v  ;
      $opt_v  = (defined($main::opt_v )) ? $main::opt_v  :  0;

   local $_; # Saves $_ and restores it on subroutine exit.

   my $surname  = "\U$host\E $progID:$fn_name()";
   my $fn_usage = "Usage: $fn_name(\\\%hashname)!\n";
   my $args     = @_;
   my $msg      ;
   my $sp       = ' ' x 20; # Spaces

   my $notify;
   if    (defined($main::notify )) { $notify = $main::notify  }
   elsif (defined($main::support)) { $notify = $main::support }
   elsif (defined($ENV{LOGNAME} )) { $notify = $ENV{LOGNAME}  }
   else                            { $notify = $ENV{USER}     }

   echo("Printing hash.\n") if ($opt_v);
   if ($args < 1)
   {
      $msg = "${sp}$surname Insufficient args!\n${sp}$fn_usage\n";
      if (interactive())
         { print "$msg"; }
      else
         { email("$surname", "$msg", $notify); }
      ($opt_x) && EXIT(1) || return 0;
   }

   my $m  = 0;
   my $n  = 0;
   my $hash;
   my ($key, $value); # These two are meant for each other ;)

 #---------------------------------------------------------------#
 # First, find length of longest key in all hashes given to us.  #
 #---------------------------------------------------------------#
   foreach (@_)
   {
      $hash = $_;
      while (($key, $value) = each %{$hash})
      {
         $m = length("$key");  # Length of current key
         $n = $m if ($n < $m); # Compare to longest thus far.
      }
   }

 #-------------------------------------------------#
 # Using the length value assigned to $n (above),  #
 # print a list of hash keys and values.           #
 #-------------------------------------------------#
   foreach (@_)
   {
      $hash = $_;
      while (($key, $value) = each %{$hash})
      {
         printf("${sp}%-$n.${n}s = %s\n", "$key", "$value");
      }
   }
   return 1;
} # sub print_hash
1;

__END__
=pod

=head1 NAME

 print_hash - print tabular list of keys and values.

=head1 SYNOPSIS

 print_hash(['-x',] \%hashname, ...);

=head1 EXAMPLE

 echo("\%par and \%logins hash arrays:\n");
 print_hash(\%par, \%logins);

=head1 DESCRIPTION

 Print an indented (20 spaces) tabular list of keys and
 contents like the following:

   2001-04-19 13:14:38 %par and %logins hash arrays:
                       notify      = Bob@OrlandoKuntao.com # From %par
                       support     = orlando@cfer.com      #  ''   ''
                       working_dir = /gcchome/orlando      #  ''   ''
                       Orlando     = Stoopid!              # True :)

 Key (name) column self-adjusts to sufficient width to
 accommodate the widest variable name.

=head1 RETURNS

 Returns 1 on success.
      or 0 on error.

 Optionally (-x option), exits with '1' status on error.

=head1 GLOBAL VARIABLES

 $main::progID  - Program name.
 $main::notify  - Who ya gonna call?
 $main::support - In case $main::notify is undefined.

=head1 AUTHOR

 Bob Orlando (Bob@OrlandoKuntao.com www.OrlandoKuntao.com)

=head1 DATE/VERSION

 %G% / %I%

=head1 HISTORY

 2002-09-03 Bob Orlando
    v1.3  * Add 'use lib "$ENV{HOME}/perl_usr_lib";'
            for development Perl macro library (it is
            commented out for production in favor of
            'use lib "/usr/local/perl_usr_lib";'.

 2002-05-13 Bob Orlando
    v1.2  * Change
               echo("Printing hash.\n");
            to
               echo("Printing hash.\n") if ($opt_v);

 2001-06-06 Bob Orlando
    v1.1  * Initial release.

=cut
