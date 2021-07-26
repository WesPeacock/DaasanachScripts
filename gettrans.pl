#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark w] [--hmmark hm] [--debug] [file.sfm]";
=pod

For Example

This script reads an ini file for:
	* a log file name
	* a key file name

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
	'section:s'   => \(my $inisection = "gettrans"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "w"), # record marker, default w
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
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $ErrorLogfilename = $config->{"$inisection"}->{ErrorLog};
open(LOGFILE, ">$ErrorLogfilename");
my $KeyFilefilename = $config->{"$inisection"}->{KeyFile};
open(KEYFILE, "<$KeyFilefilename");


$config->{"$inisection"}->{MatchMarker} =~ s/ //g; # no spaces in the list
$config->{"$inisection"}->{MatchMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{MatchMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{MatchMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $MatchMarker =$config->{"$inisection"}->{MatchMarker};

$config->{"$inisection"}->{TransMarker} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{TransMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{TransMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{TransMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $TransMarker =$config->{"$inisection"}->{TransMarker};

$config->{"$inisection"}->{OutputMarker} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{OutputMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{OutputMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{OutputMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $OutputMarker =$config->{"$inisection"}->{OutputMarker};


#say STDERR ":" if $debug;
say STDERR "inisection:$inisection" if $debug;
say STDERR "inifile:$inifilename" if $debug;
say STDERR "ErrorLogfilename:$ErrorLogfilename" if $debug;
say STDERR "KeyFilefilename:$KeyFilefilename" if $debug;
say STDERR "Match Marker:$MatchMarker" if $debug;
say STDERR "Trans Marker:$TransMarker" if $debug;
say STDERR "Output Marker:$OutputMarker" if $debug;
if ($debug) { say STDERR "config:", Dumper($config) }; 

#=cut

# generate array of the key file with one SFM record per line (opl)
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
my %keyfilehash; # hash of MatchMarker keys
for my $keyline (@opledkeyfile) {
# build hash
	next if !($keyline =~  /\\($MatchMarker) [^\@]+\@\\($TransMarker) [^\@]+\@/);
	while ($keyline =~ /\\($MatchMarker) [^\@]+\@\\($TransMarker) [^\@]+\@/g) {
		my $MatchPair = $MATCH;
		$keyline =~ m/\\($MatchMarker) [^\@]+/;
		my $MatchField = $MATCH;
		$keyline =~ m/\\($TransMarker) [^\@]+/;
		my $TransField = $MATCH;
		$TransField =~ s/\\($TransMarker) /\\$OutputMarker /;
		next if ! $MatchField;
		if (exists $keyfilehash{$MatchField}) {
			my $already = $keyfilehash{$MatchField};
			say LOGFILE qq[Sentence:"$MatchField"];
			say LOGFILE qq[Already has Translation:"$already"];
			say LOGFILE qq[Will Ignore Translation:"$TransField"];
			say LOGFILE "";
			}
		else {
			$keyfilehash{$MatchField} = $TransField;
			}
		
		say STDERR "key:$MatchField\nTrans:$TransField" if $debug;
		}
	}
# erase the keyfile array after it's hashed
@opledkeyfile=();
undef @opledkeyfile;
say STDERR "keyfilehash:", Dumper(\%keyfilehash) if $debug;

while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	say $_;
	next if ! exists $keyfilehash{$_};
	say  $keyfilehash{$_};
	}
