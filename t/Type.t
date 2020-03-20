use v6;
use NativeCall;
use Test;

use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::GObject::Type;
use Gnome::GObject::Object;


#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
sub _new_button ( Str $label )
  returns N-GObject
  is native(&gtk-lib)
  is symbol('gtk_button_new_with_label')
  { * }

sub _initialize_gtk ( CArray[int32] $argc, CArray[CArray[Str]] $argv )
  returns int32
  is native(&gtk-lib)
  is symbol('gtk_init_check')
  { * }

my $argc = CArray[int32].new;
$argc[0] = 1 + @*ARGS.elems;

my $arg_arr = CArray[Str].new;
my Int $arg-count = 0;
$arg_arr[$arg-count++] = $*PROGRAM.Str;
for @*ARGS -> $arg {
  $arg_arr[$arg-count++] = $arg;
}

my $argv = CArray[CArray[Str]].new;
$argv[0] = $arg_arr;

_initialize_gtk( $argc, $argv);


#-------------------------------------------------------------------------------
subtest 'ISA test', {
  my Gnome::GObject::Type $t .= new;
  isa-ok $t, Gnome::GObject::Type;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  my N-GObject $n-button = _new_button("Stop");
  isa-ok $n-button, N-GObject;

#note $n-button;
#  my N-GTypeInfo $info .= new(
#    :class_size(),
#    :instance_size(), :n_preallocs(0),
#  );

#Gnome::N::debug(:on);
  my Gnome::GObject::Type $t .= new;
#  $t.register-static( );
  my Int $gtype = $t.from-name('GtkButton');
  is $t.g-type-name($gtype), 'GtkButton',
     "gtype 0x$gtype.base(16) is a GtkButton type";

  my Int $x-gtype = $t.g-type-parent($gtype);
  is $t.g-type-name($x-gtype), 'GtkBin',
     "gtype 0x$x-gtype.base(16) is a GtkBin type";

  $x-gtype = $t.g-type-parent($x-gtype);
  is $t.g-type-name($x-gtype), 'GtkContainer',
     "gtype 0x$x-gtype.base(16) is a GtkContainer type";

  $x-gtype = $t.g-type-parent($x-gtype);
  is $t.g-type-name($x-gtype), 'GtkWidget',
     "gtype 0x$x-gtype.base(16) is a GtkWidget type";

  is $t.g-type-depth($gtype), 6, 'GtkButton typedepth is 6';
  is $t.g-type-depth($x-gtype), 3, 'GtkWidget typedepth is 3';

  # cast button object into a widget object (last $x-type is that of a widget)
  my N-GObject $cast-object = $t.check-instance-cast( $n-button, $x-gtype);
  is $t.check-instance-is-a( $cast-object, $x-gtype), 1,
     'new object is a GtkWidget';
  is $t.is-a( $gtype, $x-gtype), 1, 'GtkButton is a GtkWidget';
}

#-------------------------------------------------------------------------------
done-testing;
