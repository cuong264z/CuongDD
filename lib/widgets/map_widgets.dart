import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme.dart';

const _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'com.hoanghungcuong.smartcheck';

/// Bản đồ OpenStreetMap kèm vòng bán kính (mét) và các điểm đánh dấu.
class MapBox extends StatelessWidget {
  const MapBox({
    super.key,
    required this.center,
    this.zoom = 16,
    this.radiusMeters,
    this.markers = const [],
    this.controller,
    this.onTap,
    this.interactive = true,
  });

  final LatLng center;
  final double zoom;
  final double? radiusMeters;
  final List<Marker> markers;
  final MapController? controller;
  final void Function(LatLng point)? onTap;
  final bool interactive;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all : InteractiveFlag.none),
            onTap: onTap == null ? null : (_, p) => onTap!(p),
          ),
          children: [
            TileLayer(urlTemplate: _tiles, userAgentPackageName: _userAgent),
            if (radiusMeters != null)
              CircleLayer(circles: [
                CircleMarker(
                  point: center,
                  radius: radiusMeters!,
                  useRadiusInMeter: true,
                  color: Palette.indigo.withValues(alpha: 0.15),
                  borderColor: Palette.indigo,
                  borderStrokeWidth: 2,
                ),
              ]),
            MarkerLayer(markers: markers),
            const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
          ],
        ),
      );
}

Marker pin(LatLng p, {Color color = Palette.bad, IconData icon = Icons.location_on_rounded, double size = 40, VoidCallback? onTap}) => Marker(
      point: p,
      width: size,
      height: size,
      alignment: Alignment.topCenter,
      child: GestureDetector(onTap: onTap, child: Icon(icon, color: color, size: size)),
    );

Marker dot(LatLng p, {Color color = Palette.amber}) => Marker(
      point: p,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
