---
layout: post
title: Word count of LaTeX documents
categories:
- blog
---

A rough word count of a LaTeX document can be achieved using a combination of the detex and wc command line utilities [source](http://tex.stackexchange.com/questions/534/is-there-any-way-to-do-a-correct-word-count-of-a-latex-document source)

This method has the advantage that it will follow `\input` and `\include` commands in the target document. Thus performing word counts on large, multi-source, documents very quickly.

General usage is to use detex to strip all tex markup from a document, then word count the resulting text. For example with the 'wc' command line utility:

{% highlight bash %}
$ detex MacbethThesis.tex | wc -w
> 31412
{% endhighlight %}

Note that this method seems more accurate to the alternative of copy and pasting the contents of the output pdf file into a text editor and word counting that file. This method splits up hyphenated words into two, and counts page numbers etc. As an example, take the following which converts the same document as above to text and word counts the result:

{% highlight bash %}
$ pdftotext MacbethThesis.pdf - | wc -w
> 66641
{% endhighlight %}
