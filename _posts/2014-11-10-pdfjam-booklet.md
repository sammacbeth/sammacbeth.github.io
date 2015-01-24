---
layout: post
title: PDFJam for creating A5 booklets
categories:
- blog
---

[PDFJam](http://go.warwick.ac.uk/pdfjam) is a collection of scripts which provide an interface to the pdfpages package. There are tools for creating booklets and appending together PDF documents.

### Creating Booklets

The `pdfbook` command reorganises an input document such that when printed it will be in booklet form (after being folded in half).

A simple example of creating an A5 booklet from an A4 input PDF:

{% highlight bash %}
$ pdfbook --a4paper Input.pdf
{% endhighlight %}
