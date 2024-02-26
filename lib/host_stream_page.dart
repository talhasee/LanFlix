import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class HostStreamPage extends StatefulWidget {
  const HostStreamPage({Key? key}) : super(key: key);

  @override
  _HostStreamPageState createState() => _HostStreamPageState();
}

class _HostStreamPageState extends State<HostStreamPage> {
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void dispose() {
    _localStream.dispose();
    _peerConnection.close();
    super.dispose();
  }

  Future<void> _initStreams() async {
    _localStream = await _createStream();
    _peerConnection = await _createPeerConnection();
    _peerConnection.addStream(_localStream);
  }

  Future<MediaStream> _createStream() async {
    final stream = await navigator.mediaDevices.getUserMedia({'video': true});
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final Map<String, dynamic> config = {
      'iceServers': [], // No STUN servers
    };
    final pc = await createPeerConnection(config, {});
    pc.onIceCandidate = (candidate) {
      // Send ice candidate to the other peer
    };
    pc.onAddStream = (stream) {
      // Handle incoming stream
    };
    return pc;
  }

  void _startStream() async {
    final offer = await _peerConnection.createOffer({});
    await _peerConnection.setLocalDescription(offer);
    // Send local description to other peer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Stream Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startStream,
          child: const Text('Start Stream'),
        ),
      ),
    );
  }
}
