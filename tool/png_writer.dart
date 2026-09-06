import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A minimal PNG encoder.
///
/// Written rather than taken from a package: `03-ARCHITECTURE.md` section 4
/// keeps the dependency list closed, and the only thing needed here is 8-bit
/// RGBA with no interlacing, which is a few dozen lines on top of the zlib
/// codec `dart:io` already provides.
abstract final class PngWriter {
  static const List<int> _signature = [137, 80, 78, 71, 13, 10, 26, 10];

  /// Encodes [pixels], four bytes per pixel in RGBA order, row-major.
  static Uint8List encode({
    required int width,
    required int height,
    required Uint8List pixels,
  }) {
    if (pixels.length != width * height * 4) {
      throw ArgumentError(
        'Expected ${width * height * 4} bytes, got ${pixels.length}.',
      );
    }

    // Every scanline is prefixed with filter type 0 (none). Filtering would
    // shrink the file, and at these sizes it is not worth the code.
    final raw = Uint8List(height * (width * 4 + 1));
    var offset = 0;
    for (var y = 0; y < height; y++) {
      raw[offset++] = 0;
      raw.setRange(offset, offset + width * 4, pixels, y * width * 4);
      offset += width * 4;
    }

    final header = BytesBuilder()
      ..add(_be32(width))
      ..add(_be32(height))
      ..add([8, 6, 0, 0, 0]); // 8-bit depth, RGBA, no compression or interlace.

    return Uint8List.fromList([
      ..._signature,
      ..._chunk('IHDR', header.takeBytes()),
      ..._chunk('IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw))),
      ..._chunk('IEND', Uint8List(0)),
    ]);
  }

  static List<int> _chunk(String type, Uint8List data) {
    final typeBytes = ascii.encode(type);
    final body = Uint8List.fromList([...typeBytes, ...data]);
    return [..._be32(data.length), ...body, ..._be32(_crc32(body))];
  }

  static List<int> _be32(int value) => [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  static final List<int> _crcTable = List<int>.generate(256, (i) {
    var c = i;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
