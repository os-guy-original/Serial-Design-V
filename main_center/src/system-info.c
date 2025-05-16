#include "system-info.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>

struct _SystemInfo
{
  GObject parent_instance;
  
  /* CPU information */
  char *cpu_model;
  int   cpu_cores;
  int   cpu_threads;
  double cpu_frequency;
  
  /* Memory information */
  double memory_total;
  double memory_used;
  double memory_free;
  
  /* System information */
  char *hostname;
  char *kernel;
  char *os;
  long  uptime;
};

G_DEFINE_TYPE (SystemInfo, system_info, G_TYPE_OBJECT)

static void
system_info_finalize (GObject *object)
{
  SystemInfo *self = SYSTEM_INFO (object);
  
  g_free (self->cpu_model);
  g_free (self->hostname);
  g_free (self->kernel);
  g_free (self->os);
  
  G_OBJECT_CLASS (system_info_parent_class)->finalize (object);
}

static void
system_info_class_init (SystemInfoClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  
  object_class->finalize = system_info_finalize;
}

static void
system_info_init (SystemInfo *self)
{
  self->cpu_model = NULL;
  self->cpu_cores = 0;
  self->cpu_threads = 0;
  self->cpu_frequency = 0.0;
  
  self->memory_total = 0.0;
  self->memory_used = 0.0;
  self->memory_free = 0.0;
  
  self->hostname = NULL;
  self->kernel = NULL;
  self->os = NULL;
  self->uptime = 0;
}

static void
update_cpu_info (SystemInfo *self)
{
  FILE *cpuinfo;
  char line[256];
  int cores = 0;
  int threads = 0;
  gboolean model_found = FALSE;
  
  g_free (self->cpu_model);
  self->cpu_model = NULL;
  
  cpuinfo = fopen ("/proc/cpuinfo", "r");
  if (cpuinfo)
    {
      while (fgets (line, sizeof (line), cpuinfo))
        {
          if (strncmp (line, "model name", 10) == 0 && !model_found)
            {
              char *value = strchr (line, ':');
              if (value)
                {
                  value += 2; /* Skip ": " */
                  value[strcspn (value, "\n")] = 0; /* Remove newline */
                  self->cpu_model = g_strdup (value);
                  model_found = TRUE;
                }
            }
          
          if (strncmp (line, "cpu cores", 9) == 0)
            {
              char *value = strchr (line, ':');
              if (value)
                cores = atoi (value + 2);
            }
          
          if (strncmp (line, "processor", 9) == 0)
            {
              threads++;
            }
        }
      fclose (cpuinfo);
    }
  
  self->cpu_cores = cores;
  self->cpu_threads = threads;
  
  /* Get CPU frequency */
  double frequency = 0.0;
  FILE *scaling_freq = fopen ("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", "r");
  if (scaling_freq)
    {
      if (fscanf (scaling_freq, "%lf", &frequency) == 1)
        {
          self->cpu_frequency = frequency / 1000000.0; /* Convert to GHz */
        }
      fclose (scaling_freq);
    }
  else
    {
      /* If scaling_cur_freq is not available, try with cpuinfo_max_freq */
      FILE *max_freq = fopen ("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq", "r");
      if (max_freq)
        {
          if (fscanf (max_freq, "%lf", &frequency) == 1)
            {
              self->cpu_frequency = frequency / 1000000.0; /* Convert to GHz */
            }
          fclose (max_freq);
        }
    }
}

static void
update_memory_info (SystemInfo *self)
{
  struct sysinfo info;
  
  if (sysinfo (&info) == 0)
    {
      double total_ram = (double)info.totalram * info.mem_unit / (1024.0 * 1024.0 * 1024.0); /* GB */
      double free_ram = (double)info.freeram * info.mem_unit / (1024.0 * 1024.0 * 1024.0); /* GB */
      
      self->memory_total = total_ram;
      self->memory_free = free_ram;
      self->memory_used = total_ram - free_ram;
    }
}

static void
update_system_info (SystemInfo *self)
{
  struct utsname uts;
  
  if (uname (&uts) == 0)
    {
      g_free (self->hostname);
      g_free (self->kernel);
      
      self->hostname = g_strdup (uts.nodename);
      self->kernel = g_strdup_printf ("%s %s", uts.sysname, uts.release);
    }
  
  /* Get OS info from /etc/os-release */
  FILE *os_release = fopen ("/etc/os-release", "r");
  if (os_release)
    {
      char line[256];
      gboolean found_name = FALSE;
      g_free (self->os);
      self->os = NULL;
      
      while (fgets (line, sizeof (line), os_release) && !found_name)
        {
          if (strncmp (line, "PRETTY_NAME=", 12) == 0)
            {
              char *value = line + 12;
              if (value[0] == '"')
                {
                  value++; /* Skip leading quote */
                  value[strcspn (value, "\"\n")] = 0; /* Remove trailing quote and newline */
                  self->os = g_strdup (value);
                  found_name = TRUE;
                }
            }
        }
      fclose (os_release);
    }
  
  /* Get uptime */
  FILE *uptime_file = fopen ("/proc/uptime", "r");
  if (uptime_file)
    {
      double uptime_seconds = 0.0;
      if (fscanf (uptime_file, "%lf", &uptime_seconds) == 1)
        {
          self->uptime = (long)uptime_seconds;
        }
      fclose (uptime_file);
    }
}

SystemInfo *
system_info_new (void)
{
  SystemInfo *self = g_object_new (SYSTEM_TYPE_INFO, NULL);
  system_info_update (self);
  return self;
}

void
system_info_update (SystemInfo *self)
{
  g_return_if_fail (SYSTEM_IS_INFO (self));
  
  update_cpu_info (self);
  update_memory_info (self);
  update_system_info (self);
}

const char *
system_info_get_cpu_model (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), NULL);
  return self->cpu_model;
}

int
system_info_get_cpu_cores (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0);
  return self->cpu_cores;
}

int
system_info_get_cpu_threads (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0);
  return self->cpu_threads;
}

double
system_info_get_cpu_frequency (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0.0);
  return self->cpu_frequency;
}

double
system_info_get_memory_total (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0.0);
  return self->memory_total;
}

double
system_info_get_memory_used (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0.0);
  return self->memory_used;
}

double
system_info_get_memory_free (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0.0);
  return self->memory_free;
}

const char *
system_info_get_hostname (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), NULL);
  return self->hostname;
}

const char *
system_info_get_kernel (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), NULL);
  return self->kernel;
}

const char *
system_info_get_os (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), NULL);
  return self->os;
}

long
system_info_get_uptime (SystemInfo *self)
{
  g_return_val_if_fail (SYSTEM_IS_INFO (self), 0);
  return self->uptime;
}

void
system_info_format_uptime (SystemInfo *self, GString *str)
{
  g_return_if_fail (SYSTEM_IS_INFO (self));
  g_return_if_fail (str != NULL);
  
  long uptime = self->uptime;
  long days = uptime / (60 * 60 * 24);
  long hours = (uptime / (60 * 60)) % 24;
  long minutes = (uptime / 60) % 60;
  long seconds = uptime % 60;
  
  g_string_truncate (str, 0);
  
  if (days > 0)
    g_string_append_printf (str, "%ld days, ", days);
    
  g_string_append_printf (str, "%02ld:%02ld:%02ld", hours, minutes, seconds);
} 