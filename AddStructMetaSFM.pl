# perl -pf opl.pl FileName.SFM |perl -CS -pf AddStructMetaSFM.pl |perl -pf de_opl.pl
# Adds an SFM with a list of the other SFMs in the record
# You probably want a
#   grep -v '\\struct '
# at the start of the pipe to delete pre-existing \struct fields
#    grep -v '\\struct ' FileName.SFM |perl -pf opl.pl |perl -CS -pf AddStructMetaSFM.pl |perl -pf de_opl.pl
my $sfms = "";
while (/\\[^ ]* /g) {$sfms = $sfms . $&};
# ignore some fields in the Syriac database
$sfms =~ s/\\entry //; #ignore number
$sfms =~ s/\\lx-rm //; #ignore roman lex
$sfms =~ s/\\de (\\de )+/\\de+ /g; #multiple \de ->\de+
$sfms =~ s/\\raw .*//; #ignore raw & notes
$sfms =~ tr/\\/%/; #use % instead of \ to make life easier
s/\\raw/\\struct $sfms#\\raw/;