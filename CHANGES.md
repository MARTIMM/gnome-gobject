## Release notes

* 2019-09-02 0.14.2
  * System changes to have a general way of handling all types of signals
  * added _query_interfaces() to Object
  * added _interface() to Interface.

* 2019-08-25 0.14.1
  * Object extended and documented a bit
  * Type extended and documented a bit and added test file.

* 2019-08-09 0.14.0
  * Object modified to better check for undefined values before casting.
  * Added module `Param` to handle N-GParamSpec native objects.
  * All fallback() methods renamed to \_fallback()

* 2019-08-03 0.13.15
  * Boxed modified to have a check if named arguments are passed.

* 2019-07-25 0.13.14
  * Bug fix. remove use of Gdk3 module from Object.

* 2019-07-24 0.13.13
  * Declaration of several signal subs moved from Gnome::GObject::Signal to Gnome::GObject::Object to simplify things.

* 2019-07-20 0.13.12
  * bug fixed, Value had some wrong specified subs.

* 2019-07-20 0.13.11
  * it has been shown in several C-source examples that gtk objects need casts to set proper types of arguments, e.g.
    ```
    GtkWidget *menu = gtk_menu_new ();
    GtkWidget *menu_item = gtk_menu_item_new_with_label (buf);
    gtk_menu_shell_append (GTK_MENU_SHELL (menu), menu_item);
    ```
    Here, the menu is a GtkWidget. to use gtk_menu_shell_append(), the first argument must be a GtkMenuShell type object, hence the cast GTK_MENU_SHELL (menu).
    This casting is now implemented in Gnome::GObject::Object.
  * Added g_type_check_instance_cast to Gnome::GObject::Type.

* 2019-07-17 0.13.10
  * Bugfixes in pod documentation.
  * Didn't work out the way I intended: Initializing widgets using :widget or :build is moved from Gnome::GObject::Object to Gnome::Gtk3::Widget. So it is back to its old place.

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
