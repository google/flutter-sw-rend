/*
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

#include "include/sw_rend/sw_rend_plugin.h"
#include "include/sw_rend/sw_pixel_buffer.h"

#include <gmodule.h>
#include <glib-object.h>
#include <glib.h>

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define SW_REND_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), sw_rend_plugin_get_type(), \
                              SwRendPlugin))

struct _SwRendPlugin {
  GObject parent_instance;
  GHashTable* textures;
  FlTextureRegistrar* registrar;
};

G_DEFINE_TYPE(SwRendPlugin, sw_rend_plugin, g_object_get_type())

typedef FlMethodResponse* (*MethodCallback)(SwRendPlugin* plugin, FlValue* arguments);

static FlMethodResponse* sw_rend_plugin_method_init(SwRendPlugin* plugin, FlValue* arguments){
  FlValue *ptr = fl_value_lookup_string(arguments, "width");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify width", fl_value_new_null()));
  }
  int width = fl_value_get_int(ptr);
  ptr = fl_value_lookup_string(arguments, "height");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify height", fl_value_new_null()));
  }
  int height = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = sw_pixel_buffer_new(width, height);
  gboolean success = fl_texture_registrar_register_texture(plugin->registrar, (FlTexture*)(&buffer->parent_instance));
  if(!success) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Failed to register texture", fl_value_new_null()));
  }
  int64_t buffer_id = sw_pixel_buffer_get_id(buffer);
  g_hash_table_insert(plugin->textures, (gpointer)buffer_id, (gpointer)buffer);
  g_autoptr(FlValue) result = fl_value_new_int(buffer_id);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* sw_rend_plugin_method_dispose(SwRendPlugin* plugin, FlValue* arguments) {
  FlValue *ptr = fl_value_lookup_string(arguments, "texture");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify texture ID", fl_value_new_null()));
  }
  int64_t buffer_id = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = (SwPixelBuffer*)g_hash_table_lookup(plugin->textures, (gpointer)buffer_id);
  if (buffer == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID", "Texture ID is not registered", fl_value_new_null()));
  }
  fl_texture_registrar_unregister_texture(plugin->registrar, (FlTexture*)(&buffer->parent_instance));
  sw_pixel_buffer_dispose(buffer);
  g_hash_table_remove(plugin->textures, (gpointer)buffer_id);
  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* sw_rend_plugin_method_draw(SwRendPlugin* plugin, FlValue* arguments) {
  FlValue *ptr = fl_value_lookup_string(arguments, "texture");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify texture ID", fl_value_new_null()));
  }
  int64_t buffer_id = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = (SwPixelBuffer*)g_hash_table_lookup(plugin->textures, (gpointer)buffer_id);
  if (buffer == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID", "Texture ID is not registered", fl_value_new_null()));
  }
  ptr = fl_value_lookup_string(arguments, "pixels");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must supply pixel data", fl_value_new_null()));
  }
  const uint8_t* pixels = fl_value_get_uint8_list(ptr);
  ptr = fl_value_lookup_string(arguments, "x");
  int64_t x = 0, y = 0, width = buffer->width, height = buffer->height;
  if (ptr != nullptr) {
    x = fl_value_get_int(ptr);
  }
  ptr = fl_value_lookup_string(arguments, "y");
  if (ptr != nullptr) {
    y = fl_value_get_int(ptr);
  }
  ptr = fl_value_lookup_string(arguments, "width");
  if (ptr != nullptr) {
    width = fl_value_get_int(ptr);
  }
  ptr = fl_value_lookup_string(arguments, "height");
  if (ptr != nullptr) {
    height = fl_value_get_int(ptr);
  }
  sw_pixel_buffer_draw_rect(buffer, pixels, x, y, width, height);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* sw_rend_plugin_method_invalidate(SwRendPlugin* plugin, FlValue* arguments) {
  FlValue *ptr = fl_value_lookup_string(arguments, "texture");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify texture ID", fl_value_new_null()));
  }
  int64_t buffer_id = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = (SwPixelBuffer*)g_hash_table_lookup(plugin->textures, (gpointer)buffer_id);
  if (buffer == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID", "Texture ID is not registered", fl_value_new_null()));
  }
  fl_texture_registrar_mark_texture_frame_available(plugin->registrar, (FlTexture*)(&buffer->parent_instance));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

static FlMethodResponse* sw_rend_plugin_method_read(SwRendPlugin* plugin, FlValue* arguments) {
  FlValue *ptr = fl_value_lookup_string(arguments, "texture");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify texture ID", fl_value_new_null()));
  }
  int64_t buffer_id = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = (SwPixelBuffer*)g_hash_table_lookup(plugin->textures, (gpointer)buffer_id);
  if (buffer == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID", "Texture ID is not registered", fl_value_new_null()));
  }
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_uint8_list(buffer->buffer, buffer->width * buffer->height * 4)));
}

static FlMethodResponse* sw_rend_plugin_method_get_size(SwRendPlugin* plugin, FlValue* arguments) {
  FlValue *ptr = fl_value_lookup_string(arguments, "texture");
  if (ptr == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("MISSING", "Must specify texture ID", fl_value_new_null()));
  }
  int64_t buffer_id = fl_value_get_int(ptr);
  SwPixelBuffer* buffer = (SwPixelBuffer*)g_hash_table_lookup(plugin->textures, (gpointer)buffer_id);
  if (buffer == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("INVALID", "Texture ID is not registered", fl_value_new_null()));
  }
  int32_t size[2] = {(int32_t)buffer->width, (int32_t)buffer->height};
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int32_list(size, 2)));
}

static FlMethodResponse* sw_rend_plugin_method_list(SwRendPlugin* plugin, FlValue* arguments) {
  uint32_t size = g_hash_table_size(plugin->textures);
  int64_t* textures = g_new(int64_t, size);
  GHashTableIter iter;
  gpointer key;
  g_hash_table_iter_init(&iter, plugin->textures);
  for (int i = 0; i < size; i++) {
    g_hash_table_iter_next(&iter, &key, nullptr);
    textures[i] = (int64_t)key;
  }
  FlMethodResponse* response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int64_list(textures, size)));
  g_free(textures);
  return response;
}

static GHashTable* methods = nullptr;

// Called when a method call is received from Flutter.
static void sw_rend_plugin_handle_method_call(
    SwRendPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  MethodCallback func = (MethodCallback)g_hash_table_lookup(methods, method);
  if (func == nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  } else {
    FlValue* args = fl_method_call_get_args(method_call);
    response = func(self, args);
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void sw_rend_plugin_dispose(GObject* object) {
  g_print("Disposing of SW REND plugin\n");
  SwRendPlugin* plugin = SW_REND_PLUGIN(object);
  GHashTableIter iter;
  g_hash_table_iter_init(&iter, plugin->textures);
  gpointer key, value;
  while(g_hash_table_iter_next(&iter, &key, &value)) {
    sw_pixel_buffer_dispose((SwPixelBuffer*)value);
  }
  g_hash_table_destroy(plugin->textures);
  G_OBJECT_CLASS(sw_rend_plugin_parent_class)->dispose(object);
}

static void sw_rend_plugin_class_init(SwRendPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = sw_rend_plugin_dispose;
}

static void sw_rend_plugin_init(SwRendPlugin* self) {
  self->textures = g_hash_table_new(g_direct_hash, g_direct_equal);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  SwRendPlugin* plugin = SW_REND_PLUGIN(user_data);
  sw_rend_plugin_handle_method_call(plugin, method_call);
}

void sw_rend_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  // Set up methods
  if (methods == nullptr) {
    methods = g_hash_table_new(g_str_hash, g_str_equal);
    g_hash_table_insert(methods, (gpointer)"init", (gpointer)sw_rend_plugin_method_init);
    g_hash_table_insert(methods, (gpointer)"dispose", (gpointer)sw_rend_plugin_method_dispose);
    g_hash_table_insert(methods, (gpointer)"draw", (gpointer)sw_rend_plugin_method_draw);
    g_hash_table_insert(methods, (gpointer)"invalidate", (gpointer)sw_rend_plugin_method_invalidate);
    g_hash_table_insert(methods, (gpointer)"get_pixels", (gpointer)sw_rend_plugin_method_read);
    g_hash_table_insert(methods, (gpointer)"get_size", (gpointer)sw_rend_plugin_method_get_size);
    g_hash_table_insert(methods, (gpointer)"list_textures", (gpointer)sw_rend_plugin_method_list);
  }

  SwRendPlugin* plugin = SW_REND_PLUGIN(
      g_object_new(sw_rend_plugin_get_type(), nullptr));

  // Get texture registrar
  plugin->registrar = fl_plugin_registrar_get_texture_registrar(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "com.funguscow/sw_rend",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_print("Registering plugin and channel \"com.funguscow/sw_rend\"\n");

  g_object_unref(plugin);
}
