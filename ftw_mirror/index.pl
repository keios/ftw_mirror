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
use URI::Encode;
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
my $m_baselink = '';
my $m_fsize = '';
my $m_filesize = '';
my $m_permalink = '';

my $m_cgi = CGI->new;
my $m_uri = URI::Encode->new( encode_reserved => 0 );
my $m_template = HTML::Template->new( filename => "index.template",
                                      loop_context_vars => 1,
                                      associate => + $m_cgi );

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

sub format_filesize {
    my $size = shift;
    my $exp = 0;
    state $units = [qw( B KB MB GB )];
    for ( @$units ) {
        last if $size < 1024;
        $size /= 1024;
        $exp++;
    }
    return wantarray ? ( $size, $units->[$exp] ) : sprintf( "%.2f %s", $size, $units->[$exp] );
}

sub check_data_dir {
# return values: 0 = not empty, 1 = empty, -1 = not existent
  my ( $dir ) = @_;
  my $file;
  opendir my $dfh, $dir or die "Could not open dir: $!\n";
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
print $m_cgi->header;
process_error_messages(s_errormsg);

if ( check_data_dir(s_datadir) ){
    opendir my $m_dfh, s_datadir or die "Could not open dir: $!\n";
    my @m_filelist = readdir $m_dfh;
    sort @m_filelist;
    my @m_loop;

    $m_baselink = '/srv/www/te st/ftw_mirror/data';
    $m_baselink =~ s/$ENV{DOCUMENT_ROOT}/$ENV{HTTP_HOST}\//;

    foreach my $m_file (@m_filelist) {
        next if $m_file eq '.' or $m_file eq '..';

        $m_fsize = ( -s s_datadir ."/". $m_file);
        $m_filesize = format_filesize($m_fsize);

        $m_permalink = $m_uri->encode($m_baselink);
        $m_permalink = "http://" . $m_permalink;

        my %m_line = (
            t_itemname => $m_file,
            t_itemsize => $m_filesize,
            t_itemlink => $m_cgi->a( { -href => "$m_permalink",
                                       -title => "$m_file", },
                                        "http://"."$m_baselink"."/"."$m_file" ),
        );
        push(@m_loop, \%m_line);
    }
    $m_template->param(t_dirlisting => \@m_loop);
} elsif ( check_data_dir(s_datadir) eq -1 ){
    die "Could not open data directory: $!\n";
} else {
    $m_template->param( 't_empty' => 'true' );
}

$m_template->param(
    t_style     => s_stylesheet,
    t_title     => s_title,
    t_header    => s_header,
    t_subheader => s_subheader,
);

print $m_template->output;
