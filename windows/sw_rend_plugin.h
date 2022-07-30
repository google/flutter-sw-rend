#ifndef FLUTTER_PLUGIN_SW_REND_PLUGIN_H_
#define FLUTTER_PLUGIN_SW_REND_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <map>
#include <memory>
#include <tuple>
#include <vector>

namespace sw_rend {

	class PixelTextureObject {
	public:
		PixelTextureObject(int width, int height, flutter::TextureRegistrar& texture_reg);
		virtual ~PixelTextureObject();

		PixelTextureObject(const PixelTextureObject& other) = delete;
		PixelTextureObject& operator=(const PixelTextureObject& other) = delete;

		void invalidate();
		std::vector<uint8_t>& get_pixels();
		std::tuple<int32_t, int32_t> get_size() const;
		void draw(int x, int y, int width, int height, const std::vector<uint8_t>& pixels);

		inline int64_t get_texture_id() { return _texture_id; };

	private:
		int _width, _height;
		std::vector<uint8_t> _pixels;
		std::unique_ptr<FlutterDesktopPixelBuffer> _fdpb;
		std::unique_ptr<flutter::TextureVariant> _texture;
		int64_t _texture_id;
		flutter::TextureRegistrar& _texture_reg;
	};

	class SwRendPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

		SwRendPlugin(
			flutter::PluginRegistrarWindows& registrar,
			std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel
		);

		virtual ~SwRendPlugin();

		// Disallow copy and assign.
		SwRendPlugin(const SwRendPlugin&) = delete;
		SwRendPlugin& operator=(const SwRendPlugin&) = delete;

	private:
		// Called when a method is called on this plugin's channel from Dart.
		using Args = const flutter::EncodableValue*;
		using Return = std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>&;
		using ExposedFunction = void(SwRendPlugin::*)(Args, Return);
		void HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
		void initialize(Args, Return);
		void draw(Args, Return);
		void invalidate(Args, Return);
		void get_pixels(Args, Return);
		void get_size(Args, Return);
		void dispose(Args, Return);
		void list_textures(Args, Return);
		flutter::PluginRegistrarWindows& registrar;
		flutter::TextureRegistrar& texture_reg;
		std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;
		std::vector<uint8_t> pixels;
		std::unique_ptr<flutter::TextureVariant> texture;
		std::unique_ptr<FlutterDesktopPixelBuffer> fdpb;
		int height;
		int width;
		int64_t texture_id;
		std::map<int64_t, std::unique_ptr<PixelTextureObject>> textures;
		std::map<std::string, ExposedFunction> functions;
	};

}  // namespace sw_rend

#endif  // FLUTTER_PLUGIN_SW_REND_PLUGIN_H_
