# Perl Array and Hash examples

Perl Hash is known generally as an "associative array"
Python calls it a *dictionary*.
Gory details:https://en.wikipedia.org/wiki/Associative_array

### Example Spreadsheet with English/Pig Latin

| English      | Igpay Atinlay    |
| ------------ | ---------------- |
| hi there        | ihay erethay          |
| hello        | ellohay          |
| Good Morning | oodgay orningMay |
| G'day        | dayGay           |
| Howdy        | owdyhay          |

In the spreadsheet:

a2=hi there b2=ihay erethay

...



An array is similar to a column in a spreadsheet
$a[n] means the nth instance of the array (Perl arrays first element is always zero)

a[0] = hi there<br>
a[1] = hello<br>
a[2] = Good Morning<br>
a[3] = G'day<br>
a[4] = Howdy<br>

b[0] = ihay erethay<br>
b[1] = ellohay<br>
b[2] = oodgay orningmay<br>
b[3] = daygay<br>
b[4] = owdyhay<br>



You can access the element by an index

n=2;<br>
a[n] = "Good Morning”"



A *hash* allows indexes that are not numbers:

With the hash *%h*<br>
$h{"key"} means the element in the hash that corresponds to "key"

With the above example, we could use a Perl hash:

$h{"hi there"} = "ihay erethay"

With the Lika example expressed as SFM (the  Perl script *trans.pl* actually reads a *csv* file)

\lx abala wa pa yangba<br>
\neworth aɓala wa pa yangba<br>
\gn fiancé<br>

The Lika Perl script *trans.pl*, has a hash *%neworth* where the old orthography is the key:

$neworth{"abala wa pa yangba"} = "aɓala wa pa yangba"