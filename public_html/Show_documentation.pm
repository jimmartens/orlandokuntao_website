#!/usr/local/bin/perl -w
#
# SccsId[] = "%W% (Perl user module) %G%"
#
#----------------------------------------------------------------------#
#                         Show_documentation.pm                        #
# -------------------------------------------------------------------- #
#   Function documentation located at the bottom (follows __END__).    #
#----------------------------------------------------------------------#
  package Show_documentation;

  use strict;
  use Exporter;

  use vars qw(@ISA @EXPORT);
  @ISA       = qw(Exporter); # Inheritance Specifier Array
  @EXPORT    = qw(show_documentation);
# @EXPORT_OK = qw();

#----------------------------------------------------------------------#
sub show_documentation # Display program documentation at bottom.      #
#----------------------------------------------------------------------#
{                        # +--- $-sign must NOT preceed main::DATA
  my $n = 0;             # |
  foreach (my @doc_lines = <main::DATA>)
  {
    print "$_";
  }
  exit $n;
} # sub show_documentation
1;

__END__
=pod

=head1 NAME

 show_documentation -- Display inline documentation.

=head1 SYNOPSIS

 show_documentation();

=head1 EXAMPLE

 show_documentation() if ($opt_H);

=head1 DESCRIPTION

 Beginning at the __END__ constant in main, read and
 display all lines via DATA filehandle (to EOF).

=head1 RETURNS

 Number of lines displayed.

=head1 AUTHOR

 Bob Orlando (Bob@OrlandoKuntao.com http://www.OrlandoKuntao.com)

=head1 DATE/VERSION

 %G% / %I%

=head1 HISTORY

 2001-06-06 Bob Orlando
    v1.1  * Initial release.

=cut
