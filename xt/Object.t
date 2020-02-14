use v6;
#use lib '../gnome-gtk3/lib';
use NativeCall;
use Test;

use Gnome::GObject::Type;
use Gnome::GObject::Value;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
subtest 'properties', {

  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  my Gnome::GObject::Value $v = $b.get-property( 'label', G_TYPE_STRING);
  is $v.get-string, 'Start', '.get-property( Str, GType)';
  $v.g_value_unset;

  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.get-property( 'use-underline', $v);
  is $v.get-boolean, 0, '.get-property( Str, Gnome::GObject::Value)';
  $v.g_value_unset;
#`{{
  $v = $b.g-object-get-property( 'always-show-image', G_TYPE_BOOLEAN);
  is $v.get-boolean, 1, '.g-object-get-property( Str, GType)';
  $v.g_value_unset;

  $v .= new(:init(G_TYPE_BOOLEAN));
  $b.g-object-get-property( 'label', $v);
  is $v.get-string, 'Start', '.g-object-get-property( Str, GValue)';
  $v.g_value_unset;
}}

  $v .= new( :type(G_TYPE_STRING), :value<stop>);
  $b.set-property( 'label', $v);
  $v.g_value_unset;
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
  method cb ( $nw, :$test = '???' ) {
    my Gnome::Gtk3::Widget $w .= new(:native-object($nw));
    is $w.widget-get-name(), 'GtkLabel', 'the one and only widget in a button';

    my Gnome::Gtk3::Label $l .= new(:native-object($nw));
    is $l.get-text, $test, 'label is ok';
  }
}

subtest 'container', {
  my Gnome::Gtk3::Button $b .= new(:label<Start>);
  $b.container-foreach( X.new, 'cb', :test<Start>, :test2<x>, :test3<y>);
}

#-------------------------------------------------------------------------------
done-testing;
