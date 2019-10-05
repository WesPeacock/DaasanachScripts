#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark lx] [--hmmark hm] [--debug] [file.sfm]";
=pod
FLEx v 8.3 import flags cross-references that don't exist.

This script creates dummy entries based on the form that refers to them.
This is similar to MakeCompForm.pl but doesn't require two different fields.

This script reads an ini file for:
	* a list of main entry field Markers
	* probably only \mn (the default)

It opl's the SFM file.
It grinds over the opl'ed file building a hash of entry/homograph#
It grinds again finding entries without \ps markers.
	If the entry has a \mn marker look in the hash for its record
	get the \ps from the main record
	if the record has a \cm field put the \ps field after it
	else put the \ps field before the \ind field

The ini file should have sections with syntax like this:
[GetMnPs]
MnSFMs=mn1,mn2...
e.g.
MnSFMs=mn
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
	'section:s'   => \(my $inisection = "GetMnPs"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "lx"), # record marker, default lx
	'hmmark:s' => \(my $hmmark = "hm"), # homograh number marker, default hm
	'debug'       => \my $debug,
	) or die $USAGE;

# check your options and assign their information to variables here
$recmark =~ s/[\\ ]//g; # no backslashes or spaces in record marker

# if you need  a config file uncomment the following and modify it for the initialization you need.
# if you have set the $inifilename & $inisection in the options, you only need to set the parameter variables according to the parameter names
#=pod
use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
my $MnSFMs = "mn";
if ($config) {
	$MnSFMs = $config->{"$inisection"}->{MnSFMs};
	}
else {
	say STDERR "Couldn't find the INI file: $inifilename";
	say STDERR "Using \\mn to find the main record";
	}
$MnSFMs  =~ s/\,*$//; # no trailing commas
$MnSFMs  =~ s/ //g;  # no spaces
$MnSFMs  =~ s/\,/\|/g;  # use bars for or'ing
my $srchSFMs = qr/$MnSFMs/;
say STDERR "Search MnSFMs:$MnSFMs" if $debug;
#=cut
my $dt = (substr localtime(), 8,2) . "/" . (substr localtime(), 4,3) . "/" . (substr localtime(), 20,4); # " 2/Oct/2019"
$dt =~ s/ //g; # no leading space on day 1-9 of month
say STDERR "date:$dt" if $debug;

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line 
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
for my $oplline (@opledfile_in) {
# build hash
	my $lxkey = buildlxkey($oplline, $recmark, $hmmark);
	$oplhash{$lxkey} = $oplline if $lxkey;
	}
for my $oplline (@opledfile_in) {
	if ( !($oplline =~ /\\ps /) ) {
		if ($oplline =~ /\\$srchSFMs\ ([^#]+)/) {
			my $lxkey = buildlxkey($oplline, $recmark, $hmmark);
			my $mnlxkey = $1;
			if (exists $oplhash{$mnlxkey}) {
				my $mnoplline = $oplhash{$mnlxkey};
				$mnoplline =~ /\\ps\ ([^#]+)#/; #get the part of speech from the main record
				my $mnPS =$1;
				say STDERR "Setting \\ps for \\$recmark $lxkey: to \\ps $mnPS from \\$recmark $mnlxkey";
				if ($oplline =~ /(\\cm\ [^#]+#)/) {
					$oplline =~ s/(\\cm\ [^#]+#)/$1\\ps $mnPS\#/;
					}
				else {
					$oplline =~ s/(\\ind )/\\ps $mnPS#$1/;
					}
				}
			}
		}
say STDERR "oplline:", Dumper($oplline) if $debug;
#de_opl the (perhaps) modified line
	for ($oplline) {
		s/#/\n/g;
		s/\_\_hash\_\_/#/g;
		print;
		}
	}
