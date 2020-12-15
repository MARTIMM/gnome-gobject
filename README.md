![gtk logo][logo]
<!--
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/MARTIMM/gnome-gobject?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true)](https://ci.appveyor.com/project/MARTIMM/gnome-gobject/branch/master)
-->
# Gnome GObject - Data structures and utilities for C programs

![T][travis-svg] ![A][appveyor-svg] ![L][license-svg]

[travis-svg]: https://travis-ci.org/MARTIMM/gnome-gobject.svg?branch=master
[travis-run]: https://travis-ci.org/MARTIMM/gnome-gobject

[appveyor-svg]: https://ci.appveyor.com/api/projects/status/github/MARTIMM/gnome-gobject?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true
[appveyor-run]: https://ci.appveyor.com/project/MARTIMM/gnome-gobject/branch/master

[license-svg]: http://martimm.github.io/label/License-label.svg
[licence-lnk]: http://www.perlfoundation.org/artistic_license_2_0

<!--
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
-->
## Documentation
[ 🔗 Website](https://martimm.github.io/gnome-gtk3/content-docs/reference-gobject.html)
[ 🔗 Travis-ci run on master branch][travis-run]
[ 🔗 Appveyor run on master branch][appveyor-run]
[ 🔗 License document][licence-lnk]
[ 🔗 Release notes][changes]

# Installation
Do not install this package on its own. Instead install `Gnome::Gtk3`.

`zef install Gnome::Gtk3`


# Author

Name: **Marcel Timmerman**
Github account name: **MARTIMM**

# Issues

There are always some problems! If you find one please help by filing an issue at [my Gnome::Gtk3 github project][issues].

# Attribution
* The inventors of Raku, formerly known as Perl 6, of course and the writers of the documentation which helped me out every time again and again.
* The builders of the GTK+ library and the documentation.
* Other helpful modules for their insight and use.

[//]: # (---- [refs] ----------------------------------------------------------)
[changes]: https://github.com/MARTIMM/gnome-gobject/blob/master/CHANGES.md
[logo]: https://martimm.github.io/gnome-gtk3/content-docs/images/gtk-raku.png
[issues]: https://github.com/MARTIMM/gnome-gtk3/issues

[InitiallyUnowned]: https://developer.gnome.org/gtk3/stable/ch02.html
[Interface]: https://developer.gnome.org/gobject/stable/GTypeModule.html
[Object]: https://developer.gnome.org/gobject/stable/gobject-The-Base-Object-Type.html
[Signal]: https://developer.gnome.org/gobject/stable/gobject-Signals.html
[Type1]: https://developer.gnome.org/gobject/stable/gobject-Type-Information.html
[Type2]: https://developer.gnome.org/glib/stable/glib-Basic-Types.html
[Value1]: https://developer.gnome.org/gobject/stable/gobject-Generic-values.html
[Value2]: https://developer.gnome.org/gobject/stable/gobject-Standard-Parameter-and-Value-Types.html

[//]: # (Pod documentation rendered with)
[//]: # (pod-render.pl6 --pdf --g=MARTIMM/gnome-gobject lib)

[Gnome::GObject::Object html]: https://nbviewer.jupyter.org/github/MARTIMM/gnome-gobject/blob/master/doc/Object.html
[Gnome::GObject::Object pdf]: https://nbviewer.jupyter.org/github/MARTIMM/gnome-gobject/blob/master/doc/Object.pdf
[Gnome::GObject::Signal html]: https://nbviewer.jupyter.org/github/MARTIMM/gnome-gobject/blob/master/doc/Signal.html
[Gnome::GObject::Signal pdf]: https://nbviewer.jupyter.org/github/MARTIMM/gnome-gobject/blob/master/doc/Signal.pdf
