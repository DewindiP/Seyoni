import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:seyoni/src/config/url.dart';
import 'package:seyoni/src/constants/constants_color.dart';
import 'package:seyoni/src/pages/provider/notification/notification_provider.dart';
import 'package:seyoni/src/pages/provider/service_process_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GoogleMapsTrackPage extends StatefulWidget {
  final LatLng seekerLocation;
  final String seekerName;
  final String seekerId;
  final String reservationId;

  const GoogleMapsTrackPage({
    required this.seekerLocation,
    required this.seekerName,
    required this.seekerId,
    required this.reservationId,
    super.key,
  });

  @override
  State<GoogleMapsTrackPage> createState() => _GoogleMapsTrackPageState();
}

class _GoogleMapsTrackPageState extends State<GoogleMapsTrackPage> {
  final loc.Location locationController = loc.Location();
  GoogleMapController? mapController;
  LatLng? currentPosition;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  bool _otpGenerated = false;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _fetchLocationUpdates();
    _sendOtpToSeeker();
  }

  @override
  void dispose() {
    locationController.onLocationChanged.drain();
    mapController?.dispose();
    super.dispose();
  }

  void _sendOtpToSeeker() {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://$url/ws/notification/'), // Ensure this URL is correct
    );
    channel.sink.add(jsonEncode({
      'type': 'send_otp',
      'seeker_id': widget.seekerId,
    }));
  }

  void _initializeMarkers() {
    markers.add(
      Marker(
        markerId: MarkerId('seeker'),
        position: widget.seekerLocation,
        infoWindow: InfoWindow(title: 'Seeker Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );
  }

  Future<void> _fetchLocationUpdates() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    final currentLocation = await locationController.getLocation();
    if (!mounted) return;
    setState(() {
      currentPosition =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _updateRoute();
    });

    locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (!mounted) return;
      setState(() {
        currentPosition =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _updateRoute();
        _checkProximity();
      });
    });
  }

  // google_map_track_page.dart

  void _checkProximity() async {
    if (currentPosition == null || _otpGenerated) return;

    final distance = _calculateDistance(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.seekerLocation.latitude,
      widget.seekerLocation.longitude,
    );

    if (distance <= 0.5) {
      try {
        final otp = _generateOtp();
        _otpGenerated = true;

        debugPrint('=======Proximity reached - Generating OTP: $otp==========');

        if (!mounted) return;

        final provider =
            Provider.of<NotificationProvider>(context, listen: false);

        // Initialize service with OTP
        await provider.initializeService(
          otp: otp,
          reservationId: widget.reservationId,
          seekerId: widget.seekerId,
        );

        // Navigate to service process page
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProcessPage(
              seekerName: widget.seekerName,
              otp: otp,
              reservationId: widget.reservationId,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error in proximity handling: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String _generateOtp() {
    return (100000 + (Random().nextInt(900000))).toString();
  }

  Future<void> sendOtp(String seekerId, String reservationId) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // Ensure connection before sending OTP
    await provider.ensureConnection();

    // Generate OTP
    final otp = _generateOtp();
    debugPrint(
        '======================Generated OTP: $otp for seeker: $seekerId================');

    // Initialize the service with OTP and make sure it's visible
    provider.initializeService(
      otp: otp,
      reservationId: reservationId,
      seekerId: seekerId,
    );

    // Force visibility
    provider.setOtp(otp); // This will also set isVisible to true

    // Navigate after sending OTP
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProcessPage(
          seekerName: widget.seekerName,
          otp: otp,
          reservationId: reservationId,
        ),
      ),
    );
  }

  Future<void> _updateRoute() async {
    if (currentPosition == null) return;

    List<LatLng> route =
        await _getRouteBetweenPoints(currentPosition!, widget.seekerLocation);

    if (!mounted) return;
    setState(() {
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: route,
          color: kPrimaryColor,
          width: 5,
        ),
      );
    });
  }

  Future<List<LatLng>> _getRouteBetweenPoints(LatLng start, LatLng end) async {
    final String apiKey = dotenv.env['GOOGLE_PLACES_API_KEY']!;
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<LatLng> points = [];
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final polyline = route['overview_polyline']['points'];
        points.addAll(_decodePolyline(polyline));
      }
      return points;
    } else {
      throw Exception('Failed to load directions');
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text('Track ${widget.seekerName}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.seekerLocation,
              zoom: 16.0,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
        ],
      ),
    );
  }
}
