## Release notes

* 2019-07-17 0.13.9
  * Removed dependency on Gnome::Gtk3::Main in Gnome::GObject::Object. Code needed to initialize is copied to Gnome::GObject::Object.
  * Initializing widgets using :widget or :build is moved from Gnome::GObject::Object to Gnome::Gtk3::Widget.

* 2019-07-12 0.13.8
  * EventTypes in Gnome::Gdk3 renamed to Events

* 2019-07-11 0.13.7
  * moved debug() in Object to Gnome::N.

* 2019-07-10 0.13.6
  * bugfixes

* 2019-06-09 0.13.5
  * additional check on object type to handle GdkRGBA separately

* 2019-05-28 0.13.4
  * Updating docs

* 2019-06-02 0.13.3
  * Bugfixes in Object and Signal

* 2019-05-28 0.13.2
  * Modified class names by removing the first 'G' from the name. E.g. GBoxed becomes Boxed.

* 2019-05-27 0.13.1
  * Refactored from project GTK::V3 at version 0.13.1
