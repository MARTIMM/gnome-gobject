## Release notes
* 2021-12-08 0.19.3
  * Bugfix; removed a type on argument in Type module

* 2021-11-15 0.19.2
  * Adding a type test and change a part of methods `.get-properties()` and `.set-properties()`.

* 2021-11-11 0.19.1
  * Missing documentation on new().
  * Callback must return info.

* 2021-11-09 0.19.0
  * Added a module which is kept very minimal. Just enough to get other modules working like **Gnome::Gtk3::AccelGroup**.

* 2021-09-23 0.18.1
  * Add gboolean to type checks in `set-data()` and `get-data()`.

* 2021-09-20 0.18.0
  * Add new methods to **Gnome::GObject::Object**. The methods `.set-data()` and `.get-data()` are added and improved.

* 2021-08-01 0.17.0
  * Add new methods to **Gnome::GObject::Object**. The methods `.set-properties()` and `.get-properties()` are alternative ways to set properties on objects using methods `get-property()` and `set-property()`.

* 2021-07-13 0.16.24
  * Improve docs of **Gnome::GObject::Type** and add methods.
  * Idem for **Gnome::GObject::Value**.

* 2021-06-17 0.16.23
  * Improve `.get-data()` and `.set-data()` in **Gnome::GObject::Object**.

* 2021-05-18 0.16.22
  * Add `.steal-data()` method to remove object data.

* 2021-05-15 0.16.21
  * Add some new methods to **Gnome::GObject::Object**. The methods `.set-data()` and `.get-data()` are used to associate data to a native object.

* 2021-04-30 0.16.20
  * Doc changes in **Gnome::GObject::Object** and **Gnome::GObject::Signal**.
  * Some more type substitutions for the callback handler registered with `.register-signal()`. Native types are the glib types which are mapped to raku native types using **Gnome::N::GlibToRakuTypes**.

  Raku type | Native glib type | Native Raku type
  ----------|------------------|-----------------
  Bool      | gboolean         | int32
  UInt      | guint            | uint32/uint64
  Int       | gint             | int32/int64
  Num       | gfloat           | num32
  Rat       | gdouble          | num64

* 2021-03-01 0.16.19
  * Modified **Gnome::GObject::Object** to check for initialization. In the past, it was always done automatically. Now, it is not always necessary when the Application module from Gtk3 and Gio is used because those modules also do that. Care must be taken that the build of the GUI must only take place after initializing the Application.

* 2021-02-27 0.16.18
  * Improved `.register-signal()`. It now also delivers the native object to the signal call handler in `:_native-object`. This comes in handy when Raku objects needs to be cleaned up to save some memory. If so, the handler resieves an invalid Raku object in `:_widget`. With the native object one is that able to rebuild this object like so (example of a Button signal);
    ```
      method some-handler (
        …,
        Gnome::Gtk3::Button :_widget($button) is copy,
        N-GObject :_native-object($no)
      ) {
        $button .= new(:native-object($no)) unless $w.is-valid;
        …
      }
    ```

* 2021-02-15 0.16.17
  * Modified **Gnome::GObject::Object** and **Gnome::GObject::Signal** to remove the interface call from Object. Furtermore, cleanup documentation and added tests.
  * Method `.start-tread()` is symplified. Parameter `$priority` is no longer used.

* 2020-12-11 0.16.16
  * Bugfixes in **Gnome::GObject::Value**. Also in test was a wrong assumption that a long type should have a 64 bit size.

* 2020-11-28 0.16.15
  * Conversions of types using the type mapping from **Gnome::N::GlibToRakuTypes**.
  * Enums module is taken out temporarily (maybe forever...).

* 2020-11-24 0.16.14
  * Bugfix in **Gnome::GObject::Type**. Types returned from several methods are uint32. However, they might turn negative when they are read into Int typed values and their most significant bit is set. `.get-parameter()` has now added code to handle this. Other places should still be checked where this might pose a problem.

* 2020-10-14 0.16.13
  * Bugfixes in Object and Signal. The return value of a signal handler set using `.register-signal()` was processed wrong.
  * Added some more debug information.

* 2020-10-14 0.16.12
  * Moved Gtk initialization higher up in hierargy from **Gnome::N::TopLevelClassSupport** into **Gnome::GObject::Object**. It is not needed e.g. for Cairo and Glib.

* 2020-10-11 0.16.11
  * Turned **Gnome::GObject::Signal** into a role and inherited it in **Gnome::GObject::Object**.

* 2020-08-15 0.16.10
  * Improved return value handling of user signal handlers in **Gnome::GObject::Object** and **Gnome::GObject::Signal** classes.

* 2020-08-04 0.16.9
  * Rename **GdkEvent** into **N-GdkEvent** in an signal example.
  * Use of `:_widget` and `:_handler-id` in examples.
  * Bugfix: Somehow with newer Raku version the parameter list to `g_signal_connect_object()` went berserk and got exceptions from **NativeCall**.

* 2020-05-20 0.16.8
  * provide user of a handler id not only from return of `register-signal()` but also in de named argument :$\_handler-id.
  * The named argument to the user callback from `.register-handler()` and also `.start-thread()` `:widget` is deprecated and is renamed to `:_widget`. This is done to give the user more freedom for their own named arguments. Also in all routines handling callbacks, the extra provided arguments, if any, are prefixed with a dash ('\_'), so do not use that type of names.

* 2020-05-15 0.16.7
  * Add catch block to `.start-thread()` just before calling user code in **Object**.
  * Improve and bugfixing `.emit_by_name()`. Also improved pod doc.

* 2020-04-28 0.16.6
  * Method register-signal() now returns an integer instead of a boolean. This integer is a handler-id which can be used to disconnect the signal using g_signal_handler_disconnect(). When handler is 0, the registration failed. The other method to connect a signal is g_signal_connect_object() which will also return a handler id.

* 2020-04-12 0.16.5
  * Improved `register-signal()` in Object such that an exception can be caught and and a stack can be shown. See also [issue here](https://github.com/rakudo/rakudo/issues/3592) for information. Raku gets improved in later versions that it can show a stackdump all by itself but will always terminate.
  * Improved `start-thread()` in Object

* 2020-04-12 0.16.4
  * Improved `.emit_by_name()` in Signal. Also improved a message in `.register-signal()` in Object.

* 2020-04-05 0.16.3
  * Added method g_type_name_from_instance() to the Type module

* 2020-04-05 0.16.2
  * Removed a level of exception catching.

* 2020-04-01 0.16.1:
  * Many bugfizes. The biggest mistake was the use of DESTROY to clear a native object.
  * Remove of the Param class for the time being. There was no use of it at the present moment.
  * Add check in `g_object_unref()` for floating objects when unreferencing an object.

* 2020-03-25 0.16.0:
  * Object and Boxed are now inheriting from **Gnome::N::TopLevelClassSupport**.

* 2020-03-21 0.15.15:
  * In preparation to use TopLevelClassSupport, $!gobject-is-valid is renamed to $!is-valid. This makes it possible to change child class BUILDs, such that these can become inheritable.

* 2020-03-07 0.15.14:
  * Removed CALL-ME() methods.
  * Improved FALLBACK methods.

* 2020-03-05 0.15.13:
  * Moved code from FALLBACK in Object to Gnome::N::X

* 2020-02-14 0.15.12:
  Add possibility to use named arguments on functions to native calls. A native call does not handle named arguments but a native sub is sometimes wrapped in another sub. The wrapper sub can handle those arguments to do special work. An example of this is `gtk_container_foreach()` where a user provided callback routine is called. This routine can get those named arguments as extra info.

* 2020-01-18 0.15.11:
  * renaming calls to `*native-gobject()` and `*native-gboxed()`.
  * rename `:widget` to `:native-object`.
  * remove `:empty` and use empty options hash instead
  * rename `:gvalue` to `:native-object`. and add `clear-object()` and `DESTROY()`.

* 2020-01-16 0.15.10:
  * Remove `:D` on type in call to `set-native-object()` to prevent program to crash. If statement in code added to prevent saving undefined objects.
  * Remove test in Boxed.BUILD to accept empty options hash as being `:empty`.
  * `native-gboxed()` and `set-native-gboxed()` are deprecated in Boxed in favor of `set-native-object()` and `get-native-object()`.
  * Object now checks for `:native-object` and deprecates the use of `:widget`.
  *  `native-gobject()` and `set-native-gobject()` are deprecated in Object in favor of `set-native-object()` and `get-native-object()`.
  * Remove test in Object.BUILD to accept empty options hash as being `:empty`.

* 2020-01-10 0.15.9:
  * Bugfixed; There was still use of another `g_object_get_property()` from **Gnome::Gtk3**. This api was inhibited because I failed to see that a `proto () {}` was needed.

* 2020-01-09 0.15.8.1:
  * Repo renaming. Perl6 to Raku.

* 2020-01-09 0.15.8:
  * Bugfixes in Gnome::GObject::Value, improved doc and more tests

* 2019-12-13 0.15.7:
  * Bugfixes in Gnome::GObject::Object

* 2019-12-13 0.15.6:
  * Bugfixes in Gnome::GObject::Object and Gnome::GObject::Type

* 2019-12-03 0.15.5:
  * Documentation changes

* 2019-11-24 0.15.4
  * Changed order of tests in `_fallback()` routines.

* 2019-11-24 0.15.3
  * Bugfixed; Caching mechanism of sub addresses must have more information to select the proper sub from the right class.

* 2019-11-13 0.15.2
  * Added `get-parameter()` to Type. A method to get a perl6 Parameter from a a given GType and optionally an object.
  * Improved and retested get/set object properties.

* 2019-11-10 0.15.1
  * Review of Type and Value.
  * bugfixed N-GType had a wrong size

* 2019-10-30 0.15.0
  * Add new module Enums. A base class for all types for Glib and GObject.

* 2019-10-26 0.14.10
  * Removed Interface module. Was already empty. It also imposes an inheritance problem when two interface modules are needed.

* 2019-10-24 0.14.9
  * Remove \_query_interfaces() because it doesn't work using `require &:(xyz)`. Interface modules must be queried directly from the using class. Because of this, the Interface module used by the interface modules is not needed anymore. It is kept however so common utilities could be stored there.

* 2019-10-21 0.14.8
  * Add one more debug message.
  * Add caching of found sub addresses

* 2019-10-13 0.14.7
  * Changes in Object and Boxed for checks on GdkRGBA. Module is changed in Gdk3 package.

* 2019-10-11 0.14.6
  * Bugfixes in Object

* 2019-10-06 0.14.5
  * Added g_object_get_property() again. Added method counterparts get-property(). get-property() will use methods, get_property(), g-object-get-property() and g_object_get_property() use subs.

* 2019-10-06 0.14.4
  * Changes in Boxed to save the class name and type.
  * Add get-native-gboxed() in Boxed and changed native-gboxed().
  * Add get-native-gobject() in Object and changed native-gobject().

* 2019-09-30 0.14.3
  * improve register signal to prevent a problem in user provided :widget() in named arguments list.

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
