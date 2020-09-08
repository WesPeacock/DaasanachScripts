Check Complex Form Readme
=

Check Comp Form is a script for marking the complex forms in an SFM file that are Variants that should be converted to complex forms by the hackFwdata script.

Here\'s how to prepare and run the script:

Import your main SFM database into FLEx. Filter *Non-blanks* on the *Variant of* column.

Either select the records you want from within FLEx and export (as SFM) just those records, or export all the *Non-blank Variant of* records.

You can also *opl* and grep the exported file.

Set the values in the checkform.ini file:\
The *comparefilename* parameter is the name of the SFM file.

The *gentag* parameter is the SFM marker (without \\) followed by the tag that will be used to flag those entries for *hackFWdata.* It should be chosen according to the criteria for the modify tags in *HackFWdata*. (No modifytag can be a substring of another or of a modeltag).

Make a corresponding entry in the ini file for the *hackFWdata* script.

> \[checkcompform\]  
> comparefilename=VarofUnspecVerb.db  
> gentag=genmark AutoUnspecVerb

The corresponding entry in the *PromoteSubentries.ini* file might be like:

> modeltag51=zzz\_DefaultVerbCompform  
> modifytag51=AutoUnspecVerb  
