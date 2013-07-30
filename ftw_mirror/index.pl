#!/usr/bin/perl -w
#
# this file is licenced under the
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
# Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#
#

use 5.010;

use strict;
use warnings;

use CGI;
use HTML::Template;
use utf8;
use CGI::Carp qw( fatalsToBrowser warningsToBrowser );

# set to your liking
use constant s_stylesheet    => 'style.css';
use constant s_header        => 'FTW Mirror';
use constant s_subheader     => 'FTP-to-WWW mirror scripts';
use constant s_title         => 'FTW Mirror';

use constant s_datadir       => '/home/keios/test/ftw_mirror/data';
use constant s_errormsg      => '/home/keios/test/ftw_mirror/error.msg';

my $s_showdiskfree  = 0;

# leave these alone
my $m_errstring = '';

my $m_cgi = CGI->new;
my $m_template = HTML::Template->new( filename => "index.template", associate => + $m_cgi );

#
# functions
#

sub process_error_messages {
    my ( $fh ) = @_;
    my $fs = -s $fh;
    if ( $fs ) {
        $m_template->param(
            t_errors => "TODO: error messages go here",
        );
    }
}

sub show_free_diskspace {
# TODO
}

sub check_data_dir {
# return values: 0 = not empty, 1 = empty, -1 = not existent
  my ( $dir ) = @_;
  my $file;
  opendir my $dfh, $dir or die "Could not open dir: $!";
  if ( $dfh ){
      while ( defined( $file = readdir $dfh ) ){
          next if $file eq '.' or $file eq '..';
          closedir $dfh;
          return 1;
      }
     closedir $dfh;
     return 0;
  } else {
     return -1;
  }
}

#
# code
#

process_error_messages(s_errormsg);

if ( check_data_dir(s_datadir) ){
    my @m_filelist <s_datadir/*>;

    foreach my $m_file (@m_filelist) {
        print $m_cgi->p($m_file),
              $m_cgi->br();
    }
} elsif ( check_data_dir(s_datadir) eq -1 ){
    die "Could not open data directory: $!";
} else {
    print $m_cgi->p("data dir is empty!");
}

$m_template->param(
    t_style     => s_stylesheet,
    t_title     => s_title,
    t_header    => s_header,
    t_subheader => s_subheader,
);

print $m_cgi->header;
print $m_template->output;
