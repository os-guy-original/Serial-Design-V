#include "cpu_t-application.h"
#include "cpu_t-window.h"
#include "cpu_t-config.h"

struct _CpuTApplication
{
  AdwApplication parent_instance;
};

G_DEFINE_TYPE (CpuTApplication, cpu_t_application, ADW_TYPE_APPLICATION)

static void
cpu_t_application_finalize (GObject *object)
{
  G_OBJECT_CLASS (cpu_t_application_parent_class)->finalize (object);
}

static void
cpu_t_application_activate (GApplication *app)
{
  GtkWindow *window;

  /* Get the current window or create a new one if necessary */
  window = gtk_application_get_active_window (GTK_APPLICATION (app));
  if (window == NULL)
    window = g_object_new (CPU_T_TYPE_WINDOW,
                           "application", app,
                           NULL);

  /* Ask the window manager to present the window */
  gtk_window_present (window);
}

static void
cpu_t_application_class_init (CpuTApplicationClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GApplicationClass *app_class = G_APPLICATION_CLASS (klass);

  object_class->finalize = cpu_t_application_finalize;

  app_class->activate = cpu_t_application_activate;
}

static void
cpu_t_application_about_action (GSimpleAction *action G_GNUC_UNUSED,
                               GVariant      *parameter G_GNUC_UNUSED,
                               gpointer       user_data)
{
  CpuTApplication *self = CPU_T_APPLICATION (user_data);
  GtkWindow *window = NULL;
  const char *developers[] = {
    "Your Name <your.email@example.com>",
    NULL
  };

  window = gtk_application_get_active_window (GTK_APPLICATION (self));

  adw_show_about_window (window,
                         "application-name", "CPU-T",
                         "application-icon", "com.github.cpu-t",
                         "developer-name", "Your Name",
                         "version", "0.1.0",
                         "developers", developers,
                         "copyright", "© 2023 Your Name",
                         NULL);
}

static void
cpu_t_application_quit_action (GSimpleAction *action G_GNUC_UNUSED,
                              GVariant      *parameter G_GNUC_UNUSED,
                              gpointer       user_data)
{
  CpuTApplication *self = CPU_T_APPLICATION (user_data);

  g_application_quit (G_APPLICATION (self));
}

static const GActionEntry app_actions[] = {
  { "quit", cpu_t_application_quit_action, NULL, NULL, NULL, {0, 0, 0} },
  { "about", cpu_t_application_about_action, NULL, NULL, NULL, {0, 0, 0} },
};

static void
cpu_t_application_init (CpuTApplication *self)
{
  g_action_map_add_action_entries (G_ACTION_MAP (self),
                                   app_actions,
                                   G_N_ELEMENTS (app_actions),
                                   self);
  gtk_application_set_accels_for_action (GTK_APPLICATION (self),
                                        "app.quit",
                                        (const char *[]) { "<primary>q", NULL });
}

CpuTApplication *
cpu_t_application_new (const char        *application_id,
                      GApplicationFlags  flags)
{
  return g_object_new (CPU_T_TYPE_APPLICATION,
                       "application-id", application_id,
                       "flags", flags,
                       NULL);
} 