use v6;
#use lib '../gnome-gtk3/lib';
use NativeCall;
use Test;

use Gnome::N::N-GObject;

use Gnome::GObject::Type;
use Gnome::GObject::Value;

use Gnome::Gtk3::Window;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'properties', {

  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  ok $b.is-floating, '.is-floating() is floating no ownership';

  my Gnome::Gtk3::Window $w .= new;
  $w.container-add($b);
  ok !$b.is-floating, '.is-floating() not floating -> parent is window';

  my Gnome::GObject::Value $v = $b.get-property( 'label', G_TYPE_STRING);
  is $v.get-string, 'Start', '.get-property( \'label\', G_TYPE_STRING)';
  $v.clear-object;
  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.get-property( 'use-underline', $v);
  is $v.get-boolean, 0,
     '.get-property( \'use-underline\', Gnome::GObject::Value)';
  $v.clear-object;
#`{{
  $v = $b.g-object-get-property( 'always-show-image', G_TYPE_BOOLEAN);
  is $v.get-boolean, 1, '.g-object-get-property( Str, GType)';
  $v.clear-object;

  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.g-object-get-property( 'label', $v);
  is $v.get-string, 'Start', '.g-object-get-property( Str, GValue)';
  $v.clear-object;
}}

  $v .= new( :type(G_TYPE_STRING), :value<stop>);
  $b.set-property( 'label', $v);
  $v.clear-object;
  $v .= new(:init(G_TYPE_STRING));
  $b.get-property( 'label', $v);
  is $v.get-string, 'stop', '.set-property( Str, Gnome::GObject::Value)';

#`{{
  my @pv = $b.g-object-get( 'label', 'use-underline', 'always-show-image');
  is @pv[0].string, 'stop', '.g-object-get() string';
  is @pv[0].bool, 1, '.g-object-get() boolean';
}}
}

#-------------------------------------------------------------------------------
class X {
  method cb ( N-GObject $nw, :$test = '???' ) {
    my Gnome::Gtk3::Widget $w .= new(:native-object($nw));
    if $w.widget-get-name() eq 'GtkLabel' {
      ok 1, 'the one and only widget in a button';

      my Gnome::Gtk3::Label $l .= new(:native-object($nw));
      is $l.get-text, $test, 'label is ok';
    }
  }

  method click ( :_widget($w) ) {
    note 'clicked ...';
  }
}

subtest 'container', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  $b.container-foreach( X.new, 'cb', :test<Start>, :test2<x>, :test3<y>);

  # button was floating and causes an error when cleared. Sink it will
  # increase ref or remove floats. in below call, returned object is thrown.
  $b.ref-sink;
  $b.clear-object;
  ok !$b.is-valid, '.clear-object() object cleared';
}

#`{{
#-------------------------------------------------------------------------------
subtest 'signals', {

  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  my Int $hid = $b.register-signal( X.new, 'click', 'clicked');
  my Int $sid = $b.g_signal_lookup('clicked');
  is $sid, $hid, '.signal-lookup(): ' ~ $hid;
  $b.emit-by-name('clicked');
  is $b.signal-name($sid), 'clicked', '.signal-name()';
  $b.handler_disconnect($hid);

  $hid = $b.register-signal( X.new, 'click', 'clicked');
  is $b.g_signal_lookup('clicked'), $hid, '.signal-lookup(): ' ~ $hid;
Gnome::N::debug(:on);
  is $b.signal-lookup('clicked'), $hid, '.signal-lookup(): ' ~ $hid;
}
}}

#-------------------------------------------------------------------------------
done-testing;
