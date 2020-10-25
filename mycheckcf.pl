#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark lx] [--hmmark hm]  [--cfmark cf] [--snmark sn] [--debug] [file.sfm]";
=pod

For Example

This script reads an ini file for:
	* a log file name

It opl's the SFM file.
It grinds over the opl'ed file
	building a hash of lines keyed by entry/homograph#
    It chokes if it finds an non-numeric homograph number
	It finds the largest homograph#
	If an entry has a homograph it adds that key to a flag hash

It grinds again over the opl'ed file checking cross-reference fields
    if the cross-reference hits on the main hash by entry/homograph# --good
		else if the cross-reference hits on the flag hash
			it matches multiple homographs
			log all the homographs for the matching cross-reference
		else log the cross-reference as a missing entry
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
	if ($line =~ /\\$recmark ([^#]*)#.*/) {
		$lxkey = $1;
		if ($line =~ /\\$hmmark ([^#]*)#/) {
			$lxkey .= $1;
			}
		}
	return $lxkey;
	}

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "Check_cf"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "lx"), # record marker, default lx
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
$config->{"$inisection"}->{SummaryMarkers} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{SummaryMarkers} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{SummaryMarkers} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{SummaryMarkers} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $SummaryMarkers =$config->{"$inisection"}->{SummaryMarkers};
#say STDERR ":" if $debug;
say STDERR "inisection:$inisection" if $debug;
say STDERR "inifile:$inifilename" if $debug;
say STDERR "ErrorLogfilename:$ErrorLogfilename" if $debug;
say STDERR "Summary Markers:$SummaryMarkers" if $debug;
if ($debug) { say STDERR "config:", Dumper($config) };

say LOGFILE "Cross references with issues";
#=cut

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/\ +$//;
	s/#/\_\_hash\_\_/g;
	$_ .= "#";
	if (/^\\$recmark /) {
		$line =~ s/#$/\n/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;

my %oplhash; # hash of opl'd file keyed by \lx(\hm)
my %hmentrieshash; # hash of entries with homographs keyed on \lx field contains flag text only
my %snentrieshash; # hash of entries with sense markers keyed by "\lx(\hm) \sn"
my $maxhm =""; # largest homograph number must be numeric string
for my $oplline (@opledfile_in) {
# build hashes, check homograph number and set maximum homograph number
	my $lxkey = buildlxkey($oplline, $recmark, $hmmark);
	$oplhash{$lxkey} = $oplline if $lxkey;
	if ($oplline =~ /\\$recmark ([^#]*)#.*?\\$hmmark ([^#]*)#/) {
		my $lxtext = $1;
		my $hmtxt = $2;
		$hmentrieshash{$lxtext} = '***HAS HOMOGRAPH***';
		$hmtxt =~ /^[0-9]/ || die "non-numeric homograph $hmtxt in entry $oplline";
		$maxhm = $hmtxt if $maxhm lt $hmtxt;
		}
	while ($oplline =~ /\\$snmark ([^#]+)#/g) {
		$snentrieshash{"$lxkey $1"} = "has sense $1";
		}
	}

#=pod
say STDERR "maxhm:$maxhm" if $debug;
say STDERR "hmentrieshash" if $debug;
say STDERR Dumper(\%hmentrieshash) if $debug;
say STDERR "";
say STDERR "snentrieshash" if $debug;
say STDERR Dumper(\%snentrieshash) if $debug;
say STDERR "";
say STDERR "oplhash" if $debug;
say STDERR Dumper(\%oplhash) if $debug;
#die "debugstmt" if $debug;
#=cut
for my $oplline (@opledfile_in) {
	my $lxkey = buildlxkey($oplline, $recmark, $hmmark);
say STDERR "lxkey:$lxkey" if $debug;
	while ($oplline =~ /\\$cfmark ([^#]+)#/g) {
		my $cftext = $1;
say STDERR "cftext:$cftext" if $debug;
		next if exists $oplhash{$cftext};
		next if exists $snentrieshash{$cftext};
		if (! exists $hmentrieshash{$cftext}) {
			say LOGFILE "Doesn't exist \"\\$cfmark $cftext\" found under $lxkey";
			}
		else {
			say LOGFILE "Missing homograph number for  \"$cfmark $cftext\" under $lxkey. Choose one of:";
			for (my $i= 1; $i <= $maxhm; $i++) {
				 if (exists $oplhash{$cftext.$i}) {
					 print LOGFILE "\t";
					 while ($oplhash{$cftext.$i} =~ /\\($SummaryMarkers) [^#]*#/g) {print LOGFILE $MATCH}
					say LOGFILE "";
					}
				}
			}
		}
	}
