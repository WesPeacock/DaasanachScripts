#!/usr/bin/env perl
#  Usage: oplsfm infile.sfm |perl -pf  disambiguatent.pl |de_oplsfm outfile.sfm
# or as a one-liner
# oplsfm infile.sfm |perl -pE 's{(\\)([^\ ]+)([^#]+)#\\nt }{$1$2$3#\\nt_$2 } while /\\nt /;' |de_oplsfm >outfile.sfm
s/(\\)([^\ ]+)([^#]+)#\\nt /$1$2$3#\\nt_$2 / while /\\nt /;
