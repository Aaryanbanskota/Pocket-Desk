#include "include/audioplayers_linux/audioplayers_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#define AUDIOPLAYERS_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), audioplayers_linux_plugin_get_type(), \
                              AudioplayersLinuxPlugin))

struct _AudioplayersLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AudioplayersLinuxPlugin,
              audioplayers_linux_plugin,
              g_object_get_type())

static void audioplayers_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(audioplayers_linux_plugin_parent_class)->dispose(object);
}

static void audioplayers_linux_plugin_class_init(
    AudioplayersLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = audioplayers_linux_plugin_dispose;
}

static void audioplayers_linux_plugin_init(AudioplayersLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  g_autoptr(FlValue) result = fl_value_new_int(1);
  g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  fl_method_call_respond(method_call, response, nullptr);
}

void audioplayers_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  AudioplayersLinuxPlugin* plugin = AUDIOPLAYERS_LINUX_PLUGIN(
      g_object_new(audioplayers_linux_plugin_get_type(), nullptr));

  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      messenger, "xyz.luan/audioplayers", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_autoptr(FlStandardMethodCodec) globalCodec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) globalChannel = fl_method_channel_new(
      messenger, "xyz.luan/audioplayers.global", FL_METHOD_CODEC(globalCodec));

  fl_method_channel_set_method_call_handler(
      globalChannel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
