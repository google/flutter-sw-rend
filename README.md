# SwRend

A plugin for direct pixel rendering of Textures.

## Support
SwRend plugin currently has support for Windows, Android, and Linux.

## `SoftwareTexture`
`SoftwareTexture` represents a texture of pixel data that the software can display.
When creating a `SoftwareTexture`, pass its size in pixels as a `Size` to the constructor.
Before the `SoftwareTexture` can be used, you must call `generateTexture`, which calls the
platform-specific functionality to create the texture on the device and retrieve the texture ID.
Each `SoftwareTexture` contains a `Uint8List` named `buffer`, which stores its pixel data as
a list of unsigned 8-bit integers in row-major, RGBA order. Calling `draw` will push the contents
of `buffer` to the pixel data of the underlying device texture and, if the optional parameter
`redraw` is not specified as `false`, will redraw the texture. The contents of a `SoftwareTexture`
can be displayed in a `Texture` widget using the `textureID` of the `SoftwareTexture`. 
