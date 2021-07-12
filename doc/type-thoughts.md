```
#-------------------------------------------------------------------------------
#--[ Code from c-source to study casting ]--------------------------------------
#-------------------------------------------------------------------------------

#define GTK_TYPE_MENU_SHELL             (gtk_menu_shell_get_type ())

GType    gtk_menu_shell_get_type       (void) G_GNUC_CONST;

===> my Gnome::GObject::Type $type .= new;
===> my int32 $gtype = $type.g_type_from_name('GtkMenuShell');


#define GTK_MENU_SHELL(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_TYPE_MENU_SHELL, GtkMenuShell))

#define G_TYPE_CHECK_INSTANCE_CAST(instance, g_type, c_type) \
        (_G_TYPE_CIC ((instance), (g_type), c_type))

#define _G_TYPE_CIC(ip, gt, ct) \
        ((ct*) g_type_check_instance_cast ((GTypeInstance*) ip, gt))

===> my Gnome::Gtk3::Menu $menu .= new;
===> my $type.check-instance-cast( $menu(), $gtype)
===> my Gnome::Gtk3::MenuShell $menu-shell .= new(
       :native-object($type.check-instance-cast( $menu(), $gtype))
     );

===> $menu-shell.gtk_menu_shell_append($menu_item);


#-------------------------------------------------------------------------------
Study for creating new classes and types

G_DEFINE_TYPE(TN, t_n, T_P)
    ===> G_DEFINE_TYPE_EXTENDED (TN, t_n, T_P, 0, {})

 * @TN: The name of the new type, in Camel case. E.g. GtkMenuShell
 * @t_n: The name of the new type, in lowercase, with words
 *  separated by '_'. E.g. gtk_menu_shell
 * @T_P: The #GType of the parent type. E.g. type from GtkContainer

G_DEFINE_TYPE_EXTENDED(TN, t_n, T_P, _f_, _C_)
    ===> _G_DEFINE_TYPE_EXTENDED_BEGIN (TN, t_n, T_P, _f_) {_C_;}
         _G_DEFINE_TYPE_EXTENDED_END()

_G_DEFINE_TYPE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PARENT, flags)
    ===> _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT)
         _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \

#define _G_DEFINE_INTERFACE_EXTENDED_BEGIN(TypeName, type_name, TYPE_PREREQ) \
\
static void     type_name##_default_init        (TypeName##Interface *klass); \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0; \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = \
        g_type_register_static_simple (G_TYPE_INTERFACE, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Interface), \
                                       (GClassInitFunc)(void (*)(void)) type_name##_default_init, \
                                       0, \
                                       (GInstanceInitFunc)NULL, \
                                       (GTypeFlags) 0); \
      if (TYPE_PREREQ != G_TYPE_INVALID) \
        g_type_interface_add_prerequisite (g_define_type_id, TYPE_PREREQ); \
      { /* custom code follows */
#define _G_DEFINE_INTERFACE_EXTENDED_END()	\
        /* following custom code */		\
      }						\
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }						\
  return g_define_type_id__volatile;			\
} /* closes type_name##_get_type() */

#define _G_DEFINE_TYPE_EXTENDED_BEGIN_PRE(TypeName, type_name, TYPE_PARENT) \
\
static void     type_name##_init              (TypeName        *self); \
static void     type_name##_class_init        (TypeName##Class *klass); \
static GType    type_name##_get_type_once     (void); \
static gpointer type_name##_parent_class = NULL; \
static gint     TypeName##_private_offset; \
\
_G_DEFINE_TYPE_EXTENDED_CLASS_INIT(TypeName, type_name) \
\
G_GNUC_UNUSED \
static inline gpointer \
type_name##_get_instance_private (TypeName *self) \
{ \
  return (G_STRUCT_MEMBER_P (self, TypeName##_private_offset)); \
} \
\
GType \
type_name##_get_type (void) \
{ \
  static volatile gsize g_define_type_id__volatile = 0;
  /* Prelude goes here */

/* Added for _G_DEFINE_TYPE_EXTENDED_WITH_PRELUDE */
#define _G_DEFINE_TYPE_EXTENDED_BEGIN_REGISTER(TypeName, type_name, TYPE_PARENT, flags) \
  if (g_once_init_enter (&g_define_type_id__volatile))  \
    { \
      GType g_define_type_id = type_name##_get_type_once (); \
      g_once_init_leave (&g_define_type_id__volatile, g_define_type_id); \
    }					\
  return g_define_type_id__volatile;	\
} /* closes type_name##_get_type() */ \
\
G_GNUC_NO_INLINE \
static GType \
type_name##_get_type_once (void) \
{ \
  GType g_define_type_id = \
        g_type_register_static_simple (TYPE_PARENT, \
                                       g_intern_static_string (#TypeName), \
                                       sizeof (TypeName##Class), \
                                       (GClassInitFunc)(void (*)(void)) type_name##_class_intern_init, \
                                       sizeof (TypeName), \
                                       (GInstanceInitFunc)(void (*)(void)) type_name##_init, \
                                       (GTypeFlags) flags); \
    { /* custom code follows */
#define _G_DEFINE_TYPE_EXTENDED_END()	\
      /* following custom code */	\
    }					\
  return g_define_type_id; \
} /* closes type_name##_get_type_once() */




#========
#define G_TYPE_FROM_INSTANCE(instance)                          (G_TYPE_FROM_CLASS (((GTypeInstance*) (instance))->g_class))

#define G_TYPE_FROM_CLASS(g_class)                              (((GTypeClass*) (g_class))->g_type)

GTypeClass


#========
GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);
#define GTK_WIDGET_CLASS(klass)
		    (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_TYPE_WIDGET, GtkWidgetClass))

#define GTK_TYPE_WIDGET			  (gtk_widget_get_type ())

#define G_TYPE_CHECK_CLASS_CAST(g_class, g_type, c_type)
        (_G_TYPE_CCC ((g_class), (g_type), c_type))

#define _G_TYPE_CCC(cp, gt, ct) \
    ((ct*) g_type_check_class_cast ((GTypeClass*) cp, gt))

sub g_type_check_class_cast ( Pointer $cp, N-GType $gt --> CArray[CType] )



GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
#define G_OBJECT_CLASS(class)
        (G_TYPE_CHECK_CLASS_CAST ((class), G_TYPE_OBJECT, GObjectClass))

#define G_TYPE_OBJECT			G_TYPE_MAKE_FUNDAMENTAL (20)
#define G_TYPE_FUNDAMENTAL(type)	(g_type_fundamental (type))
```
