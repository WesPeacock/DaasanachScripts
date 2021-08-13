# usage: perl -pf opl.pl <input.lex |perl -pf numberps.pl |perl -pf de_opl.pl >output.lex
# numberps.pl - a script to adds an outline level to the front each sense marker when the part of speech changes
# e.g.
# \lx lex
# \ps n
# \sn 1 -> \sn 1<nl>\sn 1.1
# \de ndef1
# \sn 2	 -> \sn 1.2
# \de ndef2
# \sn 3 -> \sn 1.3
# \de ndef3
# \ps v
# \sn 1 -> \sn 2<nl>\sn 2.1
# \de vdef1
# \sn 2 -> \sn 2.2
# \de vdef2
# \sn 3 -> \sn 2.3
# \de vdef3
# 

my $debug=0;
# if (! /\\ps .*?#\\ps /) { #ignore if only one ps
# 	say STDERR "no" if $debug;
# 	next;
# 	}
/(.*?)\\ps\ /; # get stuff before first  ps
my $outline = $1;
say STDERR "head:$outline" if $debug;
my $pscount = 0;
while (/(\\ps .*?)(?=(\\ps |$))/g) {
	my $pstext = $1;
	$pscount += 1;
	$pstext =~ s/\\sn /\\sn $pscount\./g;
	$outline = $outline . $pstext;
	}
$_=$outline;