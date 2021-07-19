#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark w] [--hmmark hm]  [--cfmark cf] [--snmark sn] [--debug] [file.sfm]";
=pod

For Example

This script reads an ini file for:
	* a log file name
	* a key file name

It opl's the key file.
It grinds over the opl'ed key file
	building a hash of lines keyed by entry/homograph#

It opl's the input file
It grinds over the input file
If the input record contains the Match Marker it outputs the Summary Fields in the input file.
It generates a key from the input record. If it exists in the keyfile it outputs the Summary Fields for the matching key record.
=cut
use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);

sub buildlxkey {
# simple function that returns the contents of the record marker field
# assumes the homograph marker occurs only under the main record marker
# i.e., doesn't handle homographs on subentries
# $recmark and $hmmark do not have leading backslash
	my ($line, $recmark, $hmmark) =@_;
	my $lxkey = "";
	if ($line =~ /\\$recmark ([^\@]*)\@.*/) {
		$lxkey = $1;
		if ($line =~ /\\$hmmark ([^\@]*)\@/) {
			$lxkey .= $1;
			}
		}
	return $lxkey;
	}

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl
$USAGE =~ s/inifile\.ini/$scriptname.ini/;
use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "join"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "w"), # record marker, default w
	'hmmark:s' => \(my $hmmark = "hm"), # homograh number marker, default hm
	'cfmark:s' => \(my $cfmark = "cf"), # cross reference marker, default cf
	'snmark:s' => \(my $snmark = "sn"), # sense number marker, default sn
	'debug'       => \my $debug,
	) or die $USAGE;

# check your options and assign their information to variables here
$recmark =~ s/[\\ ]//g; # no backslashes or spaces in record marker

# if you need  a config file uncomment the following and modify it for the initialization you need.
# if you have set the $inifilename & $inisection in the options, you only need to set the parameter variables according to the parameter names
#=pod
use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $ErrorLogfilename = $config->{"$inisection"}->{ErrorLog};
open(LOGFILE, ">$ErrorLogfilename");
my $KeyFilefilename = $config->{"$inisection"}->{KeyFile};
open(KEYFILE, "<$KeyFilefilename");


$config->{"$inisection"}->{MatchMarkers} =~ s/ //g; # no spaces in the list
$config->{"$inisection"}->{MatchMarkers} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{MatchMarkers} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{MatchMarkers} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $MatchMarkers =$config->{"$inisection"}->{MatchMarkers};

$config->{"$inisection"}->{SummaryMarkers} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{SummaryMarkers} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{SummaryMarkers} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{SummaryMarkers} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $SummaryMarkers =$config->{"$inisection"}->{SummaryMarkers};
#say STDERR ":" if $debug;
say STDERR "inisection:$inisection" if $debug;
say STDERR "inifile:$inifilename" if $debug;
say STDERR "ErrorLogfilename:$ErrorLogfilename" if $debug;
say STDERR "KeyFilefilename:$KeyFilefilename" if $debug;
say STDERR "Match Markers:$MatchMarkers" if $debug;
say STDERR "Summary Markers:$SummaryMarkers" if $debug;
if ($debug) { say STDERR "config:", Dumper($config) }; 

say LOGFILE "Checking against: $KeyFilefilename";
my $temp = $MatchMarkers;
$temp =~ s/\|/, \\/g;
say LOGFILE "Checking for: \\$temp";
$temp = $SummaryMarkers;
$temp =~ s/\|/, \\/g;
say LOGFILE "Displaying: \\$temp";

#=cut

# generate array of the input file with one SFM record per line (opl)
my @opledkeyfile;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<KEYFILE>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/\ +$//;
	s/\@/\_\_at\_\_/g;
	$_ .= "\@";
	if (/^\\$recmark /) {
		$line =~ s/\@$/\n/;
		push @opledkeyfile, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledkeyfile, $line;
my %keyfilehash; # hash of opl'd key file keyed by \lx(\hm)
for my $keyline (@opledkeyfile) {
# build hash
	my $lxkey = buildlxkey($keyline, $recmark, $hmmark);
	# next if !($keyline =~  /\\($MatchMarkers)/);
	say STDERR "key:$lxkey\nline:$keyline" if $debug;
	$keyfilehash{$lxkey} = $keyline if $lxkey;
	}
# erase the keyfile array after it's hashed
@opledkeyfile=();
undef @opledkeyfile;

say STDERR "keyfilehash:", Dumper(\%keyfilehash) if $debug;

my @opledfile_in;

$line = ""; # accumulated SFM record
$linecount = 0 ;
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/\ +$//;
	s/\@/\_\_at\_\_/g;
	$_ .= "\@";
	if (/^\\$recmark /) {
		$line =~ s/\@$/\n/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;

for my $oplline (@opledfile_in) {
	my $lxkey = buildlxkey($oplline, $recmark, $hmmark);
	next if !($oplline =~  /\\($MatchMarkers)/);
#	say LOGFILE "Input record: $lxkey";
	print LOGFILE "found:";
	while ($oplline =~ /\\($SummaryMarkers) [^\@]*@/g) {
		print LOGFILE $MATCH;
		};
	say LOGFILE "";
	if (exists $keyfilehash{$lxkey} ) {
		my $keyfileline = $keyfilehash{$lxkey};
		print LOGFILE "match:";
		while ($keyfileline =~ /\\($SummaryMarkers) [^\@]*@/g) {
			print LOGFILE $MATCH;
			};
		say LOGFILE "";
		}
	else {
		say LOGFILE "no match in $KeyFilefilename";
		}
	say LOGFILE "";
	}
#=pod

