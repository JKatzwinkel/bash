bash
====

screenshot
-----

I use this script as the launch application for the compiz screenshot 
functionality. It simply stores all screenshot files in a custom directory,
gives them a name indicating when it was taken and keeps track of them in
a text file.

lookup
----

Command line search tool for PDF files

Takes one or more command line parameters as search terms and greps the 
text contents of every pdf file in the current directory. Default behaviour 
prints every occurrence of *any* of the terms. Using the option `-a` as the
last parameter switches to AND mode, in which only occurrences of *all* terms
within a single line are matched. 
