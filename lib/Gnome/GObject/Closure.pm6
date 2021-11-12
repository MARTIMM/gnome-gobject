#TL:1:Gnome::GObject::Closure:

#`{{
See also;
  https://affect.media.mit.edu/projectpages/iCalm/myAffect%20Install/Python%20Install/2.0/share/gtk-doc/html/gobject/gobject-Closures.html

  https://github.com/bstpierre/gtk-examples/blob/master/c/accel.c
  https://askubuntu.com/questions/110532/how-to-use-accelerators-in-gtk
}}

use v6;
#-------------------------------------------------------------------------------
=begin pod

=head1 Gnome::GObject::Closure

Functions as first-class objects


=comment ![](images/X.png)


=head1 Description

A B<Gnome::GObject::Closure> represents a callback supplied by the programmer. It will generally comprise a function of some kind and a marshaller used to call it. It is the responsibility of the marshaller to convert the arguments for the invocation from B<Gnome::GObject::Values> into a suitable form, perform the callback on the converted arguments, and transform the return value back into a B<Gnome::GObject::Value>.

B<Note>: This module is kept very simple because Raku does not need an implementation of a closure in C, which Raku can do that very neatly. So this closure is only created to provide a callback which is needed in some cases. The other items provided in the C closure class like controlling the marshaller, providing data to the closure, the destroy function for that data, etcetera, is not supported by the Raku module.

=begin comment
In the case of C programs, a closure usually just holds a pointer to a function and maybe a data argument, and the marshaller converts between B<Gnome::GObject::Value> and native C types. The GObject library provides the B<Gnome::GObject::CClosure> type for this purpose. Bindings for other languages need marshallers which convert between B<Gnome::GObject::Values> and suitable representations in the runtime of the language in order to use functions written in that language as callbacks. Use C<set-marshal()> to set the marshaller on such a custom closure implementation.

Within GObject, closures play an important role in the implementation of signals. When a signal is registered, the I<c-marshaller> argument to C<g-signal-new()> specifies the default C marshaller for any closure which is connected to this signal. GObject provides a number of C marshallers for this purpose, see the g-cclosure-marshal-*() functions. Additional C marshallers can be generated with the [glib-genmarshal][glib-genmarshal] utility.  Closures can be explicitly connected to signals with C<g-signal-connect-closure()>, but it usually more convenient to let GObject create a closure automatically by using one of the g-signal-connect-*() functions which take a callback function/user data pair.

Using closures has a number of important advantages over a simple callback function/data pointer combination:

=item Closures allow the callee to get the types of the callback parameters, which means that language bindings don't have to write individual glue for each callback type.

=item The reference counting of B<Gnome::GObject::Closure> makes it easy to handle reentrancy right; if a callback is removed while it is being invoked, the closure and its parameters won't be freed until the invocation finishes.

=item C<invalidate()> and invalidation notifiers allow callbacks to be automatically removed when the objects they point to go away.
=end comment

=head1 Synopsis
=head2 Declaration

  unit class Gnome::GObject::Closure;
  also is Gnome::GObject::Boxed;


=comment head2 Uml Diagram

=comment ![](plantuml/.svg)


=begin comment
=head2 Inheriting this class

Inheriting is done in a special way in that it needs a call from new() to get the native object created by the class you are inheriting from.

  use Gnome::GObject::Closure;

  unit class MyGuiClass;
  also is Gnome::GObject::Closure;

  submethod new ( |c ) {
    # let the Gnome::GObject::Closure class process the options
    self.bless( :GClosure, |c);
  }

  submethod BUILD ( ... ) {
    ...
  }

=end comment


=head2 Example

The following example is translated from L<the example here|https://github.com/bstpierre/gtk-examples/blob/master/c/accel.c>. It shows an empty window where you can type two control commands C< <ctrl>A > and C< <ctrl><shift>C >. The first shows a message on the console and the second stops the program.


  use v6;

  use Gnome::GObject::Closure;

  use Gnome::Gtk3::Window;
  use Gnome::Gtk3::Main;
  use Gnome::Gtk3::AccelGroup;

  use Gnome::Gdk3::Types;
  use Gnome::Gdk3::Keysyms;


  class CTest {
    method accelerator-pressed ( Str :$arg1 ) {
      note "accelerator pressed, user argument = '$arg1'";
    }

    method stop-test ( ) {
      note "program stopped";
      Gnome::Gtk3::Main.new.quit;
    }
  }

  my CTest $ctest .= new;


  with my Gnome::Gtk3::AccelGroup $accel-group .= new {
    .connect(
      GDK_KEY_A, GDK_CONTROL_MASK, 0,
      Gnome::GObject::Closure.new(
        :handler-object($ctest), :handler-name<accelerator-pressed>,
        :handler-opts(:arg1<'foo'>)
      )
    );

    .connect(
      GDK_KEY_C, GDK_CONTROL_MASK +| GDK_SHIFT_MASK, 0,
      Gnome::GObject::Closure.new(
        :handler-object($ctest), :handler-name<stop-test>
      )
    );
  }

  with my Gnome::Gtk3::Window $window .= new {
    .add-accel-group($accel-group);
    .register-signal( $ctest, 'stop-test', 'destroy');
    .show;
  }

  Gnome::Gtk3::Main.new.main;

=end pod

#-------------------------------------------------------------------------------
use NativeCall;

#use Gnome::N::X;
use Gnome::N::NativeLib;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

use Gnome::GObject::Boxed;
use Gnome::GObject::Value;

#-------------------------------------------------------------------------------
unit class Gnome::GObject::Closure:auth<github:MARTIMM>:ver<0.1.0>;
also is Gnome::GObject::Boxed;

#-------------------------------------------------------------------------------
=begin pod
=head1 Types
=end pod

#-------------------------------------------------------------------------------
#`{{
=begin pod
=head2 class N-GClosure

A B<Gnome::GObject::Closure> represents a callback supplied by the programmer.

=item $.in-marshal: Indicates whether the closure is currently being invoked with C<invoke()>
=item $.is-invalid: Indicates whether the closure has been invalidated by  C<g-closure-invalidate()>

=end pod

:1 means 1 bit in an guint. second bit is in the same int.

typedef struct {
  volatile       	guint	 in_marshal : 1;
  volatile       	guint	 is_invalid : 1;
} GClosure;
}}

#TT:1:N-GClosure:
class N-GClosure is export is repr('CStruct') {

  # holds both bits
  has guint $.closure-info = 0;
#`{{
  method in-marshal ( --> Bool ) {
    ($!closure-info +& 0b01).Bool;
  }

  method is-invalid ( --> Bool ) {
    ($!closure-info +& 0b10).Bool;
  }
}}
}

#-------------------------------------------------------------------------------
#void (*GClosureNotify) (gpointer data, GClosure *closure);
#void (*GCallback) (void);

#subset GClosureNotify of Callable where * == \( Pointer, N-GClosure);
#subset GCallback of Callable ();

#subset GClosureNotify of Callable
#  where .signature ~~ :( gpointer $p, N-GClosure $c);

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GCClosure

=begin comment
A B<Gnome::GObject::CClosure> is a specialization of B<Gnome::GObject::Closure> for C function callbacks.

=item N-GClosure $closure: the native Closure object
=item gpointer $callback: the callback function
=end comment

=end pod

#`{{
typedef struct {
  GClosure	closure;
  gpointer	callback;
} GCClosure;
}}

# TT:0:N-GCClosure:
class N-GCClosure is export is repr('CStruct') {
  has gpointer $.data;
  has gpointer $.notify;      # GClosureNotify

  submethod BUILD (
    Callable $notify ( gpointer $data, N-GClosure $closure),
    gpointer $!data
  ) {
    $!notify = nativecast( Pointer, $notify);
  }
}
}}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 class N-GVaClosureMarshal

This is the signature of va-list marshaller functions, an optional
marshaller that can be used in some situations to avoid
marshalling the signal argument into GValues.


=item N-GObject $.closure: the B<Gnome::GObject::Closure> to which the marshaller belongs
=item ---return-value: (nullable): a B<Gnome::GObject::Value> to store the return value. May be C<undefined> if the callback of I<closure> doesn't return a value.
=item ---instance: (type GObject.TypeInstance): the instance on which the closure is invoked.
=item ---args: va-list of arguments to be passed to the closure.
=item ---marshal-data: (nullable): additional data specified when registering the marshaller, see C<set-marshal()> and C<g-closure-set-meta-marshal()>
=item ---n-params: the length of the I<param-types> array
=item ---param-types: (array length=n-params): the B<Gnome::GObject::Type> of each argument from I<args>.


=end pod

# TT:0:N-GVaClosureMarshal:
class N-GVaClosureMarshal is export is repr('CStruct') {
  has N-GObject $.closure;
  has gpointer $.callback;
}
}}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

=head3 :handler-object, :handler-name

Create a new Closure object. Minimizing the Closure to only setting of a callback method. The C<$handler-name> is the method which is defined in the user object C<$handler-object>. Optionally the user can provide some arguments to the handler.

  multi method new (
    Any:D :$handler-object!, Str:D :$handler-name!,
    :%handler-opts
  )


=head3 :native-object

Create a Closure object using a native object from elsewhere. See also B<Gnome::N::TopLevelClassSupport>.

  multi method new ( N-GObject :$native-object! )

=end pod

#TM:1:new():
#TM:4:new(:native-object):Gnome::N::TopLevelClassSupport
submethod BUILD ( *%options ) {

  # prevent creating wrong native-objects
  if self.^name eq 'Gnome::GObject::Closure' #`{{ or %options<GClosure> }} {

    # check if native object is set by a parent class
    if self.is-valid { }

    # check if common options are handled by some parent
    elsif %options<native-object>:exists { }

    # process all other options
    else {
      my $no;
      if ? %options<handler-object> and ? %options<handler-name> {
        die X::Gnome.new(:message(
            "Calback method '%options<handler-name>' not found in provided object"
          )
        ) unless %options<handler-object>.^can(%options<handler-name>);

        $no = _g_cclosure_new(
          -> {
            if %options<handler-opts>:exists {
              %options<handler-object>."%options<handler-name>"(
                |%options<handler-opts>
              )
            }

            else {
              %options<handler-object>."%options<handler-name>"()
            }
          },
          gpointer,
          -> gpointer $d, N-GClosure $c {
            note 'destroy: closure info is ', $c.closure-info.base(2)
              if $Gnome::N::x-debug;
          }
        );
      }

      ##`{{ use this when the module is not made inheritable
      # check if there are unknown options
      elsif %options.elems {
        die X::Gnome.new(
          :message(
            'Unsupported, undefined, incomplete or wrongly typed options for ' ~
            self.^name ~ ': ' ~ %options.keys.join(', ')
          )
        );
      }
      #}}

      ##`{{ when there are no defaults use this
      # check if there are any options
      elsif %options.elems == 0 {
        die X::Gnome.new(:message('No options specified ' ~ self.^name));
      }
      #}}

      #`{{ when there are defaults use this instead
      # create default object
      else {
        $no = g_closure_new();
      }
      }}

      self.set-native-object($no);
    }

    # only after creating the native-object, the gtype is known
    self.set-class-info('GClosure');
  }
}

#-------------------------------------------------------------------------------
method native-object-ref ( $n-native-object --> Any ) {
  _g_closure_ref($n-native-object)
}

#-------------------------------------------------------------------------------
method native-object-unref ( $n-native-object ) {
  _g_closure_unref($n-native-object)
}

#`{{
#-------------------------------------------------------------------------------
# TM:0:add-finalize-notifier:
=begin pod
=head2 add-finalize-notifier

Registers a finalization notifier which will be called when the reference count of I<closure> goes down to 0. Multiple finalization notifiers on a single closure are invoked in unspecified order. If a single call to C<unref()> results in the closure being both invalidated and finalized, then the invalidate notifiers will be run before the finalize notifiers.

  method add-finalize-notifier ( Pointer $notify_data, GClosureNotify $notify_func )

=item Pointer $notify_data; (closure notify-func): data to pass to I<notify-func>
=item GClosureNotify $notify_func; the callback function to register
=end pod

method add-finalize-notifier ( Pointer $notify_data, GClosureNotify $notify_func ) {

  g_closure_add_finalize_notifier(
    self.get-native-object-no-reffing, $notify_data, $notify_func
  );
}

sub g_closure_add_finalize_notifier (
  N-GObject $closure, gpointer $notify_data, Callable $notify_func ( gpointer $data, N-GClosure $closure)
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:add-invalidate-notifier:
=begin pod
=head2 add-invalidate-notifier

Registers an invalidation notifier which will be called when the I<closure> is invalidated with C<invalidate()>. Invalidation notifiers are invoked before finalization notifiers, in an unspecified order.

  method add-invalidate-notifier ( Pointer $notify_data, GClosureNotify $notify_func )

=item Pointer $notify_data; (closure notify-func): data to pass to I<notify-func>
=item GClosureNotify $notify_func; the callback function to register
=end pod

method add-invalidate-notifier ( Pointer $notify_data, GClosureNotify $notify_func ) {

  g_closure_add_invalidate_notifier(
    self.get-native-object-no-reffing, $notify_data, $notify_func
  );
}

sub g_closure_add_invalidate_notifier (
  N-GObject $closure, gpointer $notify_data, Callable $notify_func ( gpointer $data, N-GClosure $closure)
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:add-marshal-guards:
=begin pod
=head2 add-marshal-guards

Adds a pair of notifiers which get invoked before and after the closure callback, respectively. This is typically used to protect the extra arguments for the duration of the callback. See C<g-object-watch-closure()> for an example of marshal guards.

  method add-marshal-guards ( Pointer $pre_marshal_data, GClosureNotify $pre_marshal_notify, Pointer $post_marshal_data, GClosureNotify $post_marshal_notify )

=item Pointer $pre_marshal_data; (closure pre-marshal-notify): data to pass to I<pre-marshal-notify>
=item GClosureNotify $pre_marshal_notify; a function to call before the closure callback
=item Pointer $post_marshal_data; (closure post-marshal-notify): data to pass to I<post-marshal-notify>
=item GClosureNotify $post_marshal_notify; a function to call after the closure callback
=end pod

method add-marshal-guards ( Pointer $pre_marshal_data, GClosureNotify $pre_marshal_notify, Pointer $post_marshal_data, GClosureNotify $post_marshal_notify ) {

  g_closure_add_marshal_guards(
    self.get-native-object-no-reffing, $pre_marshal_data, $pre_marshal_notify, $post_marshal_data, $post_marshal_notify
  );
}

sub g_closure_add_marshal_guards (
  N-GObject $closure, gpointer $pre_marshal_data, GClosureNotify $pre_marshal_notify, gpointer $post_marshal_data, GClosureNotify $post_marshal_notify
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g-cclosure-marshal-generic:
=begin pod
=head2 g-cclosure-marshal-generic

A generic marshaller function implemented via [libffi](http://sourceware.org/libffi/).

Normally this function is not passed explicitly to C<g-signal-new()>, but used automatically by GLib when specifying a C<undefined> marshaller.

  method g-cclosure-marshal-generic ( N-GObject $return_gvalue, UInt $n_param_values, N-GObject $param_values, Pointer $invocation_hint, Pointer $marshal_data )

=item N-GObject $return_gvalue; A B<Gnome::GObject::Value> to store the return value. May be C<undefined> if the callback of closure doesn't return a value.
=item UInt $n_param_values; The length of the I<param-values> array.
=item N-GObject $param_values; An array of B<Gnome::GObject::Values> holding the arguments on which to invoke the callback of closure.
=item Pointer $invocation_hint; The invocation hint given as the last argument to C<invoke()>.
=item Pointer $marshal_data; Additional data specified when registering the marshaller, see C<set-marshal()> and C<g-closure-set-meta-marshal()>
=end pod

method g-cclosure-marshal-generic ( $return_gvalue is copy, UInt $n_param_values, $param_values is copy, Pointer $invocation_hint, Pointer $marshal_data ) {
  $return_gvalue .= get-native-object-no-reffing unless $return_gvalue ~~ N-GObject;
  $param_values .= get-native-object-no-reffing unless $param_values ~~ N-GObject;

  g_cclosure_marshal_generic(
    self.get-native-object-no-reffing, $return_gvalue, $n_param_values, $param_values, $invocation_hint, $marshal_data
  );
}

sub g_cclosure_marshal_generic (
  N-GObject $closure, N-GObject $return_gvalue, guint $n_param_values, N-GObject $param_values, gpointer $invocation_hint, gpointer $marshal_data
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g-cclosure-marshal-generic-va:
=begin pod
=head2 g-cclosure-marshal-generic-va

A generic B<Gnome::GObject::VaClosureMarshal> function implemented via [libffi](http://sourceware.org/libffi/).

  method g-cclosure-marshal-generic-va ( N-GObject $return_value, Pointer $instance, va_list $args_list, Pointer $marshal_data, Int() $n_params, N-GObject $param_types )

=item N-GObject $return_value; a B<Gnome::GObject::Value> to store the return value. May be C<undefined> if the callback of I<closure> doesn't return a value.
=item Pointer $instance; (type GObject.TypeInstance): the instance on which the closure is invoked.
=item va_list $args_list; va-list of arguments to be passed to the closure.
=item Pointer $marshal_data; additional data specified when registering the marshaller, see C<set-marshal()> and C<g-closure-set-meta-marshal()>
=item Int() $n_params; the length of the I<param-types> array
=item N-GObject $param_types; (array length=n-params): the B<Gnome::GObject::Type> of each argument from I<args-list>.
=end pod

method g-cclosure-marshal-generic-va ( $return_value is copy, Pointer $instance, va_list $args_list, Pointer $marshal_data, Int() $n_params, $param_types is copy ) {
  $return_value .= get-native-object-no-reffing unless $return_value ~~ N-GObject;
  $param_types .= get-native-object-no-reffing unless $param_types ~~ N-GObject;

  g_cclosure_marshal_generic_va(
    self.get-native-object-no-reffing, $return_value, $instance, $args_list, $marshal_data, $n_params, $param_types
  );
}

sub g_cclosure_marshal_generic_va (
  N-GObject $closure, N-GObject $return_value, gpointer $instance, va_list $args_list, gpointer $marshal_data, int $n_params, N-GObject $param_types
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:0:g-signal-type-cclosure-new:
=begin pod
=head2 g-signal-type-cclosure-new

Creates a new closure which invokes the function found at the offset I<struct-offset> in the class structure of the interface or classed type identified by I<itype>.

Returns: a floating reference to a new B<Gnome::GObject::CClosure>

  method g-signal-type-cclosure-new ( N-GObject $itype, UInt $struct_offset --> N-GObject )

=item N-GObject $itype; the B<Gnome::GObject::Type> identifier of an interface or classed type
=item UInt $struct_offset; the offset of the member function of I<itype>'s class structure which is to be invoked by the new closure
=end pod

method g-signal-type-cclosure-new ( $itype is copy, UInt $struct_offset --> N-GObject ) {
  $itype .= get-native-object-no-reffing unless $itype ~~ N-GObject;

  g_signal_type_cclosure_new(
    self.get-native-object-no-reffing, $itype, $struct_offset
  )
}

sub g_signal_type_cclosure_new (
  N-GObject $itype, guint $struct_offset --> N-GObject
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:invalidate:
=begin pod
=head2 invalidate

Sets a flag on the closure to indicate that its calling environment has become invalid, and thus causes any future invocations of C<invoke()> on this I<closure> to be ignored. Also, invalidation notifiers installed on the closure will be called at this point. Note that unless you are holding a reference to the closure yourself, the invalidation notifiers may unref the closure and cause it to be destroyed, so if you need to access the closure after calling C<g-closure-invalidate()>, make sure that you've previously called C<g-closure-ref()>.

Note that C<g-closure-invalidate()> will also be called when the reference count of a closure drops to zero (unless it has already been invalidated before).

  method invalidate ( )

=end pod

method invalidate ( ) {
  my N-GClosure $no = self.get-native-object-no-reffing;
  g_closure_invalidate($no);
  _g_closure_sink($no);
  _g_closure_ref($no);
  self.clear-object;
}

sub g_closure_invalidate (
  N-GClosure $closure
) is native(&gobject-lib)
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:invoke:
=begin pod
=head2 invoke

Invokes the closure, i.e. executes the callback represented by the I<closure>.

  method invoke (  $GValue /*out*/ *return_value, UInt $n_param_values, N-GObject $param_values, Pointer $invocation_hint )

=item  $GValue /*out*/ *return_value; a B<Gnome::GObject::Value> to store the return value. May be C<undefined> if the callback of I<closure> doesn't return a value.
=item UInt $n_param_values; the length of the I<param-values> array
=item N-GObject $param_values; (array length=n-param-values): an array of B<Gnome::GObject::Values> holding the arguments on which to invoke the callback of I<closure>
=item Pointer $invocation_hint; a context-dependent invocation hint
=end pod

method invoke (  ) {
  $param_values .= get-native-object-no-reffing unless $param_values ~~ N-GObject;

  g_closure_invoke(
    self.get-native-object-no-reffing, N-GValue, $n_param_values, $param_values, $invocation_hint
  );
}

sub g_closure_invoke (
  N-GObject $closure,  $GValue /*out*/ *return_value, guint $n_param_values, N-GObject $param_values, gpointer $invocation_hint
) is native(&gobject-lib)
  { * }
}
}}

#-------------------------------------------------------------------------------
#TM:1:_g_closure_ref:
#`{{
=begin pod
=head2 ref

Increments the reference count on a closure to force it staying alive while the caller holds a pointer to it.

Returns: The I<closure> passed in, for convenience

  method ref ( --> N-GObject )

=end pod

method ref ( --> N-GObject ) {

  g_closure_ref(
    self.get-native-object-no-reffing,
  )
}
}}

sub _g_closure_ref (
  N-GClosure $closure --> N-GClosure
) is native(&gobject-lib)
  is symbol('g_closure_ref')
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:remove-finalize-notifier:
=begin pod
=head2 remove-finalize-notifier

Removes a finalization notifier.

Notice that notifiers are automatically removed after they are run.

  method remove-finalize-notifier ( Pointer $notify_data, GClosureNotify $notify_func )

=item Pointer $notify_data; data which was passed to C<add-finalize-notifier()> when registering I<notify-func>
=item GClosureNotify $notify_func; the callback function to remove
=end pod

method remove-finalize-notifier ( Pointer $notify_data, GClosureNotify $notify_func ) {

  g_closure_remove_finalize_notifier(
    self.get-native-object-no-reffing, $notify_data, $notify_func
  );
}

sub g_closure_remove_finalize_notifier (
  N-GObject $closure, gpointer $notify_data, Callable $notify_func ( gpointer $data, N-GClosure $closure)
) is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
# TM:0:remove-invalidate-notifier:
=begin pod
=head2 remove-invalidate-notifier

Removes an invalidation notifier.

Notice that notifiers are automatically removed after they are run.

  method remove-invalidate-notifier ( Pointer $notify_data, GClosureNotify $notify_func )

=item Pointer $notify_data; data which was passed to C<add-invalidate-notifier()> when registering I<notify-func>
=item GClosureNotify $notify_func; the callback function to remove
=end pod

method remove-invalidate-notifier ( Pointer $notify_data, GClosureNotify $notify_func ) {

  g_closure_remove_invalidate_notifier(
    self.get-native-object-no-reffing, $notify_data, $notify_func
  );
}

sub g_closure_remove_invalidate_notifier (
  N-GObject $closure, gpointer $notify_data, Callable $notify_func ( gpointer $data, N-GClosure $closure)
) is native(&gobject-lib)
  { * }
}}
#`{{
#-------------------------------------------------------------------------------
# TM:0:set-marshal:
=begin pod
=head2 set-marshal

Sets the marshaller of I<closure>. The `marshal-data` of I<marshal> provides a way for a meta marshaller to provide additional information to the marshaller. (See C<set-meta-marshal()>.) For GObject's C predefined marshallers (the g-cclosure-marshal-*() functions), what it provides is a callback function to use instead of I<closure>->callback.

  method set-marshal ( GClosureMarshal $marshal )

=item GClosureMarshal $marshal; a B<Gnome::GObject::ClosureMarshal> function
=end pod

method set-marshal ( GClosureMarshal $marshal ) {

  g_closure_set_marshal(
    self.get-native-object-no-reffing, $marshal
  );
}

sub g_closure_set_marshal (
  N-GObject $closure, GClosureMarshal $marshal
) is native(&gobject-lib)
  { * }

#-------------------------------------------------------------------------------
# TM:0:set-meta-marshal:
=begin pod
=head2 set-meta-marshal

Sets the meta marshaller of I<closure>. A meta marshaller wraps I<closure>->marshal and modifies the way it is called in some fashion. The most common use of this facility is for C callbacks. The same marshallers (generated by [glib-genmarshal][glib-genmarshal]), are used everywhere, but the way that we get the callback function differs. In most cases we want to use I<closure>->callback, but in other cases we want to use some different technique to retrieve the callback function.

For example, class closures for signals (see C<g-signal-type-cclosure-new()>) retrieve the callback function from a fixed offset in the class structure. The meta marshaller retrieves the right callback and passes it to the marshaller as the I<marshal-data> argument.

  method set-meta-marshal ( Pointer $marshal_data, GClosureMarshal $meta_marshal )

=item Pointer $marshal_data; (closure meta-marshal): context-dependent data to pass to I<meta-marshal>
=item GClosureMarshal $meta_marshal; a B<Gnome::GObject::ClosureMarshal> function
=end pod

method set-meta-marshal ( Pointer $marshal_data, GClosureMarshal $meta_marshal ) {

  g_closure_set_meta_marshal(
    self.get-native-object-no-reffing, $marshal_data, $meta_marshal
  );
}

sub g_closure_set_meta_marshal (
  N-GObject $closure, gpointer $marshal_data, GClosureMarshal $meta_marshal
) is native(&gobject-lib)
  { * }
}}

#-------------------------------------------------------------------------------
#TM:1:_g_closure_sink:
#`{{
=begin pod
=head2 sink

Takes over the initial ownership of a closure. Each closure is initially created in a "floating" state, which means that the initial reference count is not owned by any caller. C<sink()> checks to see if the object is still floating, and if so, unsets the floating state and decreases the reference count. If the closure is not floating, C<g-closure-sink()> does nothing. The reason for the existence of the floating state is to prevent cumbersome code sequences like:

  closure = g_cclosure_new (cb_func, cb_data);
  g_source_set_closure (source, closure);
  g_closure_unref (closure); // XXX GObject doesn't really need this

  Because C<g-source-set-closure()> (and similar functions) take ownership of the initial reference count, if it is unowned, we instead can write:

  g_source_set_closure (source, g_cclosure_new (cb_func, cb_data));

Generally, this function is used together with C<g-closure-ref()>. Ane example of storing a closure for later notification looks like:

  static GClosure *notify_closure = NULL;
  void
  foo_notify_set_closure (GClosure *closure)
  {
    if (notify_closure)
      g_closure_unref (notify_closure);
    notify_closure = closure;
    if (notify_closure)
      {
        g_closure_ref (notify_closure);
        g_closure_sink (notify_closure);
      }
  }


Because C<g-closure-sink()> may decrement the reference count of a closure (if it hasn't been called on I<closure> yet) just like C<g-closure-unref()>, C<g-closure-ref()> should be called prior to this function.

  method sink ( )

=end pod

method sink ( ) {
  g_closure_sink(
    self.get-native-object-no-reffing,
  );
}
}}

sub _g_closure_sink (
  N-GClosure $closure
) is native(&gobject-lib)
  is symbol('g_closure_sink')
  { * }

#-------------------------------------------------------------------------------
#TM:1:_g_closure_unref:
#`{{
=begin pod
=head2 unref

Decrements the reference count of a closure after it was previously incremented by the same caller. If no other callers are using the closure, then the closure will be destroyed and freed.

  method unref ( )

=end pod

method unref ( ) {

  g_closure_unref(
    self.get-native-object-no-reffing,
  );
}
}}

sub _g_closure_unref (
  N-GClosure $closure
) is native(&gobject-lib)
  is symbol('g_closure_unref')
  { * }

#-------------------------------------------------------------------------------
#TM:1:_g_cclosure_new:
#`{{
=begin pod
=head2 g-cclosure-new

Creates a new closure which invokes I<callback-func> with I<user-data> as the last parameter.

I<destroy-data> will be called as a finalize notifier on the B<Gnome::GObject::Closure>.

Returns: a floating reference to a new B<Gnome::GObject::CClosure>

  method g-cclosure-new ( GCallback $callback_func, Pointer $user_data, GClosureNotify $destroy_data --> N-GObject )

=item GCallback $callback_func; the function to invoke
=item Pointer $user_data; (closure callback-func): user data to pass to I<callback-func>
=item GClosureNotify $destroy_data; destroy notify to be called when I<user-data> is no longer used
=end pod
}}

#`{{
method g-cclosure-new ( GCallback $callback_func, Pointer $user_data, GClosureNotify $destroy_data --> N-GObject ) {
  g_cclosure_new(
    $callback_func, $user_data, $destroy_data
  )
}
}}

sub _g_cclosure_new (
  Callable $callback_func ( ), gpointer $user_data,
  Callable $destroy_data ( gpointer $data, N-GClosure $closure)
  --> N-GClosure
) is native(&gobject-lib)
  is symbol('g_cclosure_new')
  { * }

#`{{
#-------------------------------------------------------------------------------
# TM:0:g-cclosure-new-swap:
#`{{
=begin pod
=head2 g-cclosure-new-swap

Creates a new closure which invokes I<callback-func> with I<user-data> as the first parameter.

I<destroy-data> will be called as a finalize notifier on the B<Gnome::GObject::Closure>.

Returns: a floating reference to a new B<Gnome::GObject::CClosure>

  method g-cclosure-new-swap ( GCallback $callback_func, Pointer $user_data, GClosureNotify $destroy_data --> N-GObject )

=item GCallback $callback_func; the function to invoke
=item Pointer $user_data; (closure callback-func): user data to pass to I<callback-func>
=item GClosureNotify $destroy_data; destroy notify to be called when I<user-data> is no longer used
=end pod
}}

method g-cclosure-new-swap ( GCallback $callback_func, Pointer $user_data, GClosureNotify $destroy_data --> N-GObject ) {

  g_cclosure_new_swap(
    self.get-native-object-no-reffing, $callback_func, $user_data, $destroy_data
  )
}

sub g_cclosure_new_swap (
  Callable $callback_func ( ), gpointer $user_data,
  Callable $destroy_data ( gpointer $data, GClosure *closure) --> N-GObject
) is native(&gobject-lib)
  { * }
}}

#`{{
#-------------------------------------------------------------------------------
# TM:1:_g_closure_new_simple:
#`{{
=begin pod
=head2 _g_closure_new_simple

Allocates a struct of the given size and initializes the initial part as a B<Gnome::GObject::Closure>. This function is mainly useful when implementing new types of closures.

=begin comment
typedef struct _MyClosure MyClosure;
struct _MyClosure
{
  GClosure closure;
  // extra data goes here
};

static void
my_closure_finalize (gpointer  notify_data,
                     GClosure *closure)
{
  MyClosure *my_closure = (MyClosure *)closure;

  // free extra data here
}

MyClosure *my_closure_new (gpointer data)
{
  GClosure *closure;
  MyClosure *my_closure;

  closure = g_closure_new_simple (sizeof (MyClosure), data);
  my_closure = (MyClosure *) closure;

  // initialize extra data here

  g_closure_add_finalize_notifier (closure, notify_data,
                                   my_closure_finalize);
  return my_closure;
}

=end comment

Returns: a floating reference to a new B<Gnome::GObject::Closure>

  method _g_closure_new_simple ( UInt $sizeof_closure, Pointer $data --> N-GObject )

=item UInt $sizeof_closure; the size of the structure to allocate, must be at least `sizeof (GClosure)`
=item Pointer $data; data to store in the I<data> field of the newly allocated B<Gnome::GObject::Closure>
=end pod
}}

sub _g_closure_new_simple (
  guint $sizeof_closure, gpointer $data --> N-GObject
) is native(&gobject-lib)
  is symbol('g_closure_new_simple')
  { * }
}}
