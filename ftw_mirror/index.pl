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
use URI::Encode;
use Encode qw(encode decode);
use utf8;

# set to your liking

# html style options
use constant s_stylesheet    => 'style.css';
use constant s_header        => 'FTW Mirror';
use constant s_subheader     => 'FTP-to-WWW mirror scripts';
use constant s_title         => 'FTW Mirror';

# path options
use constant s_datadir       => '/var/www/ftw_mirror/data';
use constant s_errormsg      => '/var/www/ftw_mirror/error.msg';

# show used disk space progress bar
use constant s_showdiskfree  => 1;

# leave these alone
my $m_errstring = '';
my $m_baselink  = '';
my $m_fsize     = '';
my $m_filesize  = '';
my $m_permalink = '';
my $m_enc       = 'utf-8';

my $m_cgi       = CGI->new;
my $m_uri       = URI::Encode->new(encode_reserved => 0);
my $m_template  = HTML::Template->new(filename => "index.template",
                                      loop_context_vars => 1,
                                      associate => + $m_cgi);

#
# functions
#
sub process_error_messages {
    my ($file) = @_;
    my $fh;
    my $fs = -s $file;
    my $errormsg = '';
    if ($fs) {
        $errormsg = do {
            local $/ = undef;
            open($fh, '+<:encoding(UTF-8)', $file) or die "Could not open file: $!\n";
            <$fh>;
        };
    truncate($fh, "0") or die "Could not empty $fh: $!\n";
    close($fh);
    $errormsg =~ s/\n/\<br \/\>/g;
    }
    return $errormsg;
}

sub process_df_output {
# yes, i do know Filesys::DiskSpace exists. firstly, it calls df internally.
# i can do that too. secondly, it doesn't seem stable yet. also it's broken.
    my ($dfh) = @_;
    my $output = `df -h --output=used,avail,pcent "$dfh" | tail -1`;
    my ($used, $avail, $pcent) = split(' ', $output);
    return $used, $avail, $pcent;
}

sub format_filesize {
    my $size = shift;
    my $exp = 0;
    state $units = [qw( B K M G )];
    for (@$units) {
        last if $size < 1024;
        $size /= 1024;
        $exp++;
    }
    return wantarray ? ($size, $units->[$exp]) : sprintf("%.2f %s", $size, $units->[$exp]);
}

sub check_data_dir {
# return values: 0 = not empty, 1 = empty, -1 = not existent
  my ($dir) = @_;
  my $file;
  opendir( my $dfh, $dir ) or die "Could not open $dir: $!\n";
  binmode $dfh, ':encoding(UTF-8)';
  if ($dfh){
      while (defined($file = readdir $dfh)){
          next if $file eq '.' or $file eq '..'
                or $file eq '.htaccess' or $file eq '.htpasswd';
          closedir($dfh);
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
$m_errstring = process_error_messages(s_errormsg);
$m_template->param("t_errors" => "$m_errstring");

if (check_data_dir(s_datadir)){
    opendir my $m_dfh, s_datadir or die "Could not open s_datadir: $!\n";
    binmode $m_dfh, ':encoding(UTF-8)';
    my @m_filelist = readdir $m_dfh;
    sort @m_filelist;
    my @m_loop;

    $m_baselink = s_datadir;
    $m_baselink =~ s/$ENV{DOCUMENT_ROOT}/$ENV{HTTP_HOST}\//;

    foreach my $m_file (@m_filelist) {
        next if $m_file eq '.' or $m_file eq '..'
                or $m_file eq '.htaccess' or $m_file eq '.htpasswd';

        $m_file = decode($m_enc, $m_file);

        $m_fsize = (-s s_datadir ."/". $m_file);
        $m_filesize = format_filesize($m_fsize);

        $m_permalink = "http://" . $m_baselink . "/" . $m_file;
        $m_permalink = $m_uri->encode($m_permalink);

        my %m_line = (
            t_itemname => $m_file,
            t_itemsize => $m_filesize,
            t_itemlink => $m_cgi->a({ -href => "$m_permalink",
                                      -title => "$m_file", },
                                      "http://"."$m_baselink"."/"."$m_file"),
        );
        push(@m_loop, \%m_line);
    }
    $m_template->param(t_dirlisting => \@m_loop);
} elsif (check_data_dir(s_datadir) eq -1 ){
    die "Could not open s_datadir: $!\n";
} else {
    $m_template->param('t_empty' => 'true');
}

if (s_showdiskfree){
    my ($m_used, $m_avail, $m_pcent) = process_df_output(s_datadir);
    $m_template->param(
        t_percent => "$m_pcent",
        t_used    => "$m_used",
        t_avail   => "$m_avail",
    );
}

$m_template->param(
    t_style     => s_stylesheet,
    t_title     => s_title,
    t_header    => s_header,
    t_subheader => s_subheader,
);

print $m_cgi->header;
print $m_template->output;
