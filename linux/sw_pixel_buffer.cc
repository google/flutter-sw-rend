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

#include "include/sw_rend/sw_pixel_buffer.h"

#include <cstdint>
#include <cstring>
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

//#define MIN(a, b) (((a)<(b))?(a):(b))
//#define MAX(a, b) (((a)>(b))?(a):(b))

#define SW_PIXEL_BUFFER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), sw_pixel_buffer_get_type(), \
                              SwPixelBuffer))

G_DEFINE_TYPE(SwPixelBuffer, sw_pixel_buffer, fl_pixel_buffer_texture_get_type())

static gboolean sw_pixel_buffer_copy_pixels(FlPixelBufferTexture* texture, const uint8_t** dst, uint32_t* width, uint32_t *height, GError** error) {
  SwPixelBuffer* buffer = SW_PIXEL_BUFFER(texture);
  *dst = buffer->buffer;
  *width = buffer->width;
  *height = buffer->height;
  return TRUE;
}

static void _sw_pixel_buffer_dispose(GObject* object) {
  SwPixelBuffer* buffer = SW_PIXEL_BUFFER(object);
  g_print("Disposing of SwPixelBuffer at %p\n", buffer);
  if (buffer->buffer != nullptr) {
    g_free(buffer->buffer);
    buffer->buffer = nullptr;
  }
  G_OBJECT_CLASS(sw_pixel_buffer_parent_class)->dispose(object);
}

static void sw_pixel_buffer_class_init(SwPixelBufferClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = _sw_pixel_buffer_dispose;
  klass->parent_class.copy_pixels = sw_pixel_buffer_copy_pixels;
}

static void sw_pixel_buffer_init(SwPixelBuffer* buffer) {
  buffer->width = -1;
  buffer->height = -1;
  buffer->buffer = nullptr;
}

SwPixelBuffer* sw_pixel_buffer_new(int64_t width, int64_t height) {
  SwPixelBuffer* buffer = SW_PIXEL_BUFFER(g_object_new(sw_pixel_buffer_get_type(), nullptr));
  buffer->width = width;
  buffer->height = height;
  buffer->buffer = g_new0(uint8_t, width * height * 4);
  return buffer;
}

void sw_pixel_buffer_dispose(SwPixelBuffer* buffer) {
  g_object_unref(buffer);
}

void sw_pixel_buffer_draw_rect(SwPixelBuffer* buffer, const uint8_t* pixels, int64_t x, int64_t y, int64_t width, int64_t height) {
  int64_t num_rows = MIN(height, buffer->height - y);
  int64_t num_cols = MIN(width, buffer->width - x);
  for (int dy = 0; dy < num_rows; dy++) {
    uint8_t* dst = buffer->buffer + 4 * ((y + dy) * buffer->width + x);
    const uint8_t* src = pixels + 4 * (dy * width);
    memcpy(dst, src, 4 * num_cols);
  }
}
