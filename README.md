![gtk logo][logo]

# Gnome GObject - Data structures and utilities for C programs

![L][license-svg]

[license-svg]: http://martimm.github.io/label/License-label.svg
[licence-lnk]: http://www.perlfoundation.org/artistic_license_2_0

Note that all modules are now in `:api<1>`. This is done to prevent clashes with future distributions having the same class names only differing in this api string. So, add this string to your import statements and dependency modules of these classes in META6.json. Furthermore add this api string also when installing with zef.

## Documentation
<!--
* [ 🔗 Website](https://martimm.github.io/gnome-gtk3/content-docs/reference-gobject.html)
-->
* [ 🔗 License document][licence-lnk]
* [ 🔗 Release notes][changes]
* [ 🔗 Issues](https://github.com/MARTIMM/gnome-gtk3/issues)

# Installation
Do not install this package on its own. Instead install `Gnome::Gtk3:api<1>`.

`zef install 'Gnome::Gtk3:api<1>'`

# Author

Name: **Marcel Timmerman**
Github account name: **MARTIMM**

# Issues

There are always some problems! If you find one please help by filing an issue at [my Gnome::Gtk3 github project][issues].

# Attribution
* The developers of Raku of course and the writers of the documentation which helped me out every time again and again.
* The builders of the GTK+ library and its documentation.
* Other helpful modules for their insight and use.

[//]: # (---- [refs] ----------------------------------------------------------)
[changes]: https://github.com/MARTIMM/gnome-gobject/blob/master/CHANGES.md
[logo]: https://martimm.github.io/gnome-gtk3/content-docs/images/gtk-raku.png
[issues]: https://github.com/MARTIMM/gnome-gtk3/issues
