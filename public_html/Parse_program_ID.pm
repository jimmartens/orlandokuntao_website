#!/usr/local/bin/perl -w
#
# SccsId[] = "%W% (Perl user module) %G%"
#
#----------------------------------------------------------------------#
#                           Parse_program_ID.pm                        #
# -------------------------------------------------------------------- #
#   Function documentation located at the bottom (follows __END__).    #
#----------------------------------------------------------------------#
  package Parse_program_ID;

  use strict;
  use Exporter;

  use vars qw(@ISA @EXPORT);
  @ISA       = qw(Exporter); # Inheritance Specifier Array
  @EXPORT    = qw(parse_program_ID);
# @EXPORT_OK = qw();

#----------------------------------------------------------------------#
sub parse_program_ID # The following code seems awfully clunky to me.  #
#----------------------------------------------------------------------#
{
  local $_; # Saves $_ and restores it on subroutine exit.
  use Cwd;                              # Req'd for cwd()
  use File::Basename;                   # Req'd for dirname & basename
  my $ID    = basename($0,"");          # $ID is used throughout.
  my $drive = ($0 =~ /^[A-Za-z]:/) ? $& : ""; # (e.g. 'c:')
  my $name  = $ID;                      # Executable's filename
     $name  =~ s/\..*$//;               #   less its .ext
  my $path  = dirname($0);              # Executable's path (relative?)
     $path  =~ s/^$drive//;             #   from the rest of the
     $path  = cwd() if ($path eq ".");  # Replace '.' with cwd()
  my $n     = $path =~ s|(\.\.)|$1|g;   # Count '../' (parent dirs)
  my $wd    = cwd();                    # Save current working dir (cwd)

  #------------------------------------------------------------------#
  # We try to resolve simple relative pathing to absolute here.  If  #
  # one or more sequential "../" are in $path, substitute them with  #
  # subdirectories from cwd() by first, removing $n leading "../"    #
  # from $path, then removing $n trailing subdirectories from $wd,   #
  # and finally recreating $path with "$wd/$path".                   #
  #------------------------------------------------------------------#
  if ($n > 0)
  {
    $path =~ s/^(\.\.\/){$n}//;
    $wd   =~ s/(\/\w+){$n}$//;
    $path = "$wd/$path";
  }

  if ($path !~ /^\//) # If path doesn't begin with a slash,
  {                   # then we have some sort of relative path.
    if ($path =~ /^((\.)?(\.\/)?)/)     # Replace 0|1 "./"s found
    {                                   # at the beginning of the
      $path =~ s|^(\./)?(.*)|${wd}/$2|; # line with cwd path info.
    }
  }

  $path =~ s|/(\.\.)*$||;  # Remove any trailing '/..'
  $path =~ s|(/?\./?)*||g; # Remove all '/./'
  $path =~ s|/$||;         # Remove trailing slashes
  $path =~ s/\/+/\//g;     # Squeese multiple slashes
  $path =~ s|^/*|/|;       # Prefix a leading slash if missing
  return ($ID, "${drive}$path", $name);
} # sub parse_program_ID
1;

__END__
=pod

=head1 NAME

 parse_program_ID -- parse and return program ID and path
                     (program ID returned with and without
                     its path).

=head1 SYNOPSIS

 parse_program_ID();

=head1 EXAMPLE

 ($progID, $progpath, $progname) = parse_program_ID();

=head1 DESCRIPTION

 Return list consisting of program ID ($0 less path),
 $0's path (resolving relative paths), and $0's filename
 (less any ".xxx*" extension).

=head1 AUTHOR

 Bob Orlando (Bob@OrlandoKuntao.com http://www.OrlandoKuntao.com)

=head1 DATE/VERSION

 %G% / %I%

=head1 HISTORY

 2002-09-11 Bob Orlando
    v1.4  * Previous change used regexp extension syntax
            available in Perl 5.005 and higher.  Because
            we have hosts running 5.004, I replaced the
            regexp in question with one that is backward
            compatible.

 2002-09-06 Bob Orlando
    v1.3  * Improve (hopefully) how we resolve relative
            path when parsing $0.

 2002-01-02 Bob Orlando
    v1.2  * Correct comments in the "NAME" section
            of our Perl documentation (POD).

 2001-06-05 Bob Orlando
    v1.1  * Initial release.

=cut
