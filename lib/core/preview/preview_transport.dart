/// The browser boundary for the private, in-memory preview channel.
abstract interface class PreviewTransport {
  /// Starts receiving checked messages from the configured parent only.
  void listen(void Function(Map<String, dynamic>) receive);

  /// Sends a protocol message to that exact parent origin.
  void send(String type, Map<String, dynamic> payload);

  /// Removes the browser listener.
  void dispose();
}
