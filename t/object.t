use v6;
use NativeCall;
use Test;

use Gnome::GObject::Object;

#-------------------------------------------------------------------------------
subtest 'create gobject', {
  throws-like(
    { my Gnome::GObject::Object $o .= new; },
    X::Gnome, 'no way to create empty object',
    :message("No options used to create or set the native widget")
  );
}

#-------------------------------------------------------------------------------
done-testing;
