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

#include "sw_rend_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <functional>
#include <memory>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>

namespace sw_rend {

	PixelTextureObject::PixelTextureObject(
		int width,
		int height,
		flutter::TextureRegistrar& texture_reg
	) :
		_width(width),
		_height(height),
		_texture_reg(texture_reg)
	{
		_pixels.resize(_width * _height * 4);
		_fdpb = std::make_unique<FlutterDesktopPixelBuffer>();
		_fdpb->width = _width;
		_fdpb->height = _height;
		_fdpb->buffer = _pixels.data();
		_texture = std::make_unique<flutter::TextureVariant>(
			flutter::PixelBufferTexture(
				[=](size_t w, size_t h) -> const FlutterDesktopPixelBuffer* {
					return this->_fdpb.get();
				}
			)
			);
		_texture_id = _texture_reg.RegisterTexture(_texture.get());
	}

	PixelTextureObject::~PixelTextureObject() {
		_texture_reg.UnregisterTexture(_texture_id);
	}

	void PixelTextureObject::invalidate() {
		_texture_reg.MarkTextureFrameAvailable(_texture_id);
	}

	std::vector<uint8_t>& PixelTextureObject::get_pixels() {
		return _pixels;
	}

	std::tuple<int32_t, int32_t> PixelTextureObject::get_size() const {
		return std::tuple<int32_t, int32_t>(_width, _height);
	}

	void PixelTextureObject::draw(int x, int y, int width, int height, const std::vector<uint8_t>& pixels) {
		int row_size = min(width, _width - x);
		for (int dy = 0; dy < height && y + dy < _height; dy++) {
			std::memcpy(_pixels.data() + 4 * ((y + dy) * _width + x + x), pixels.data() + 4 * (dy * width + x), row_size * 4);
		}
	}

	// static
	void SwRendPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		auto channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "com.funguscow/sw_rend",
				&flutter::StandardMethodCodec::GetInstance());

		auto plugin = std::make_unique<SwRendPlugin>(
			*registrar,
			std::move(channel)
			);

		plugin->channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});

		registrar->AddPlugin(std::move(plugin));
	}

	SwRendPlugin::SwRendPlugin(
		flutter::PluginRegistrarWindows& registrar,
		std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel
	) : registrar(registrar), texture_reg(*registrar.texture_registrar()), channel(std::move(channel)) {
		functions = std::map<std::string, ExposedFunction>({
			{"init", &SwRendPlugin::initialize},
			{"draw", &SwRendPlugin::draw},
			{"invalidate", &SwRendPlugin::invalidate},
			{"get_pixels", &SwRendPlugin::get_pixels},
			{"get_size", &SwRendPlugin::get_size},
			{"dispose", &SwRendPlugin::dispose},
			{"list_textures", &SwRendPlugin::list_textures}
		});
	}

	SwRendPlugin::~SwRendPlugin() {}

	void SwRendPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		const flutter::EncodableValue* argvalue = method_call.arguments();
        auto found = functions.find(method_call.method_name());
        if (found == functions.end()) {
            result->NotImplemented();
        }
        else {
            ExposedFunction func = found->second;
            std::invoke(func, *this, argvalue, result);
        }
	}

	void SwRendPlugin::initialize(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		width = std::get<int>(args[flutter::EncodableValue("width")]);
		height = std::get<int>(args[flutter::EncodableValue("height")]);
		std::unique_ptr<PixelTextureObject> pto = std::make_unique<PixelTextureObject>(width, height, texture_reg);
		int64_t tex_id = pto->get_texture_id();
		textures[tex_id] = std::move(pto);
		result->Success(flutter::EncodableValue(tex_id));
	}

	void SwRendPlugin::draw(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		const int x0 = std::get<int>(args[flutter::EncodableValue("x")]);
		const int y0 = std::get<int>(args[flutter::EncodableValue("y")]);
		const int w = std::get<int>(args[flutter::EncodableValue("width")]);
		int h = std::get<int>(args[flutter::EncodableValue("height")]);
		std::vector<uint8_t> bytes = std::get<std::vector<uint8_t>>(args[flutter::EncodableValue("pixels")]);
		const int64_t tex_id = std::get<int64_t>(args[flutter::EncodableValue("texture")]);
		auto res = textures.find(tex_id);
		if (res == textures.end()) {
			result->Error("NO_TEX", "Unknown texture ID provided");
		}
		else {
			res->second->draw(x0, y0, w, h, bytes);
			result->Success(flutter::EncodableValue());
		}
	}

	void SwRendPlugin::invalidate(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		const int64_t tex_id = std::get<int64_t>(args[flutter::EncodableValue("texture")]);
		auto res = textures.find(tex_id);
		if (res == textures.end()) {
			result->Error("NO_TEX", "Unknown texture ID provided");
		}
		else {
			res->second->invalidate();
			result->Success(flutter::EncodableValue());
		}
	}

	void SwRendPlugin::get_pixels(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		const int64_t tex_id = std::get<int64_t>(args[flutter::EncodableValue("texture")]);
		auto res = textures.find(tex_id);
		if (res == textures.end()) {
			result->Error("NO_TEX", "Unknown texture ID provided");
		}
		else {
			result->Success(flutter::EncodableValue(res->second->get_pixels()));
		}
	}

	void SwRendPlugin::get_size(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		const int64_t tex_id = std::get<int64_t>(args[flutter::EncodableValue("texture")]);
		auto res = textures.find(tex_id);
		if (res == textures.end()) {
			result->Error("NO_TEX", "Unknown texture ID provided");
		}
		else {
			std::tuple<int32_t, int32_t> size = res->second->get_size();
			auto [w, h] = size;
			result->Success(flutter::EncodableValue(std::vector<int32_t>({ w, h })));
		}
	}

	void SwRendPlugin::dispose(Args argptr, Return result) {
		flutter::EncodableMap args = std::get<flutter::EncodableMap>(*argptr);
		const int64_t tex_id = std::get<int64_t>(args[flutter::EncodableValue("texture")]);
		auto res = textures.find(tex_id);
		if (res == textures.end()) {
			result->Error("NO_TEX", "Unknown texture ID provided");
		}
		else {
			textures.erase(res);
			result->Success(flutter::EncodableValue());
		}
	}

	void SwRendPlugin::list_textures(Args argptr, Return result) {
		std::vector<int64_t> keys;
		for (auto &it : textures) {
			keys.push_back(it.first);
		}
		result->Success(flutter::EncodableValue(keys));
	}

}  // namespace sw_rend
