use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;

#-------------------------------------------------------------------------------
subtest 'create gobject', {
  throws-like(
    { my Gnome::GObject::Object $o .= new; },
    X::AdHoc, 'Missing package Gnome::Gtk3',
    :message(/:s Please install 'Gnome::Gtk3'/)
  );
}

#-------------------------------------------------------------------------------
done-testing;
