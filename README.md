![gtk logo][logo]

# Gnome GObject - Data structures and utilities for C programs

[![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)

# Description

# Documentation

| Pdf from pod | Link to Gnome Developer ||
|-------|--------------|----|
| Gnome::GObject::Boxed ||
| Gnome::GObject::InitiallyUnowned ||
| Gnome::GObject::Interface ||
| [Gnome::GObject::Object][Gnome::GObject::Object pdf] | [The base object type][Object]|
| [Gnome::GObject::Signal][Gnome::GObject::Signal pdf]  | [Signal handling][Signal]|
| Gnome::GObject::Type | [Type Information][Type1] | [ Basic Types][Type2]
| Gnome::GObject::Value | [Generic values][Value1] | [ Parameters and Values][Value2]

## Release notes
* [Release notes][changes]

# Installation
Do not install this package on its own. Instead install `Gnome::Gtk3`.

`zef install Gnome::Gtk3`


# Author

Name: **Marcel Timmerman**
Github account name: **MARTIMM**

# Issues

There are always some problems! If you find one please help by filing an issue at [my Gnome::Gtk3 github project][issues].

# Attribution
* The inventors of Perl6 of course and the writers of the documentation which help me out every time again and again.
* The builders of the GTK+ library and the documentation.
* Other helpful modules for their insight and use.

[//]: # (---- [refs] ----------------------------------------------------------)
[changes]: https://github.com/MARTIMM/perl6-gnome-gobject/blob/master/CHANGES.md
[logo]: https://martimm.github.io/perl6-gnome-gtk3/content-docs/images/gtk-perl6.png
[issues]: https://github.com/MARTIMM/perl6-gnome-gtk3/issues

[InitiallyUnowned]: https://developer.gnome.org/gtk3/stable/ch02.html
[Interface]: https://developer.gnome.org/gobject/stable/GTypeModule.html
[Object]: https://developer.gnome.org/gobject/stable/gobject-The-Base-Object-Type.html
[Signal]: https://developer.gnome.org/gobject/stable/gobject-Signals.html
[Type1]: https://developer.gnome.org/gobject/stable/gobject-Type-Information.html
[Type2]: https://developer.gnome.org/glib/stable/glib-Basic-Types.html
[Value1]: https://developer.gnome.org/gobject/stable/gobject-Generic-values.html
[Value2]: https://developer.gnome.org/gobject/stable/gobject-Standard-Parameter-and-Value-Types.html

[//]: # (Pod documentation rendered with)
[//]: # (pod-render.pl6 --pdf --g=MARTIMM/perl6-gnome-gobject lib)

[Gnome::GObject::Object html]: https://nbviewer.jupyter.org/github/MARTIMM/perl6-gnome-gobject/blob/master/doc/Object.html
[Gnome::GObject::Object pdf]: https://nbviewer.jupyter.org/github/MARTIMM/perl6-gnome-gobject/blob/master/doc/Object.pdf
[Gnome::GObject::Signal html]: https://nbviewer.jupyter.org/github/MARTIMM/perl6-gnome-gobject/blob/master/doc/Signal.html
[Gnome::GObject::Signal pdf]: https://nbviewer.jupyter.org/github/MARTIMM/perl6-gnome-gobject/blob/master/doc/Signal.pdf
