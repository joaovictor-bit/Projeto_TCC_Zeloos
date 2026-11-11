import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/pulseira.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';

class PulseiraMapScreen extends StatefulWidget {
  const PulseiraMapScreen({super.key, required this.pulseira, this.childName});

  final Pulseira pulseira;
  final String? childName;

  @override
  State<PulseiraMapScreen> createState() => _PulseiraMapScreenState();
}

class _PulseiraMapScreenState extends State<PulseiraMapScreen> {
  static const _fallbackCenter = LatLng(-14.235, -51.9253);
  final _refreshSeconds = AppSettings.instance.mapRefreshSeconds;
  final MapController _mapController = MapController();

  Timer? _timer;
  LatLng? _position;
  DateTime? _lastUpdate;
  double? _battery;
  List<CircleMarker> _safeZones = [];
  bool _loading = true;
  bool _fetching = false;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
    _timer = Timer.periodic(
      Duration(seconds: _refreshSeconds),
      (_) => _refreshLocation(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _refreshLocation() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final data = await ApiService.fetchPulseiraLocation(widget.pulseira.id);
      final rawLocation = data['localizacao'];
      LatLng? position;
      DateTime? lastUpdate;
      double? battery;
      if (rawLocation is Map<String, dynamic>) {
        final latitude = _number(rawLocation['latitude']);
        final longitude = _number(rawLocation['longitude']);
        if (latitude != null &&
            longitude != null &&
            latitude >= -90 &&
            latitude <= 90 &&
            longitude >= -180 &&
            longitude <= 180) {
          position = LatLng(latitude, longitude);
        }
        final registeredAt = rawLocation['registrada_em']?.toString();
        if (registeredAt != null) lastUpdate = DateTime.tryParse(registeredAt);
        battery = _number(rawLocation['bateria_percentual']);
      }

      final safeZones = <CircleMarker>[];
      final rawSafeZones = data['locaisSeguros'];
      if (rawSafeZones is List) {
        for (final item in rawSafeZones) {
          if (item is! Map<String, dynamic>) continue;
          final latitude = _number(item['latitude']);
          final longitude = _number(item['longitude']);
          final radius = _number(item['raio_metros']);
          if (latitude == null ||
              longitude == null ||
              radius == null ||
              latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180 ||
              radius <= 0) {
            continue;
          }
          safeZones.add(
            CircleMarker(
              point: LatLng(latitude, longitude),
              radius: radius,
              useRadiusInMeter: true,
              color: const Color(0x26348A59),
              borderColor: const Color(0xFF25855A),
              borderStrokeWidth: 2,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _position = position;
        _lastUpdate = lastUpdate;
        _battery = battery ?? widget.pulseira.bateriaPercentual;
        _safeZones = safeZones;
        _error = null;
        _loading = false;
      });
      if (_mapReady && position != null) {
        _mapController.move(position, _mapController.camera.zoom);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } finally {
      _fetching = false;
    }
  }

  String _formatUpdate(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date às $time';
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.pulseira.nomeDispositivo ?? widget.pulseira.identificador;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _fetching ? null : _refreshLocation,
            tooltip: 'Atualizar localização',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Icon(Icons.child_care_rounded, color: context.palette.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.childName ??
                        'Identificador: ${widget.pulseira.identificador}',
                    style: TextStyle(
                      color: context.palette.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_battery != null)
                  Chip(
                    avatar: const Icon(Icons.battery_std_rounded, size: 18),
                    label: Text('${_battery!.round()}%'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _position ?? _fallbackCenter,
                    initialZoom: _position == null ? 5 : 15,
                    onMapReady: () {
                      _mapReady = true;
                      final position = _position;
                      if (position != null) {
                        _mapController.move(position, 15);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_app',
                    ),
                    CircleLayer(circles: _safeZones),
                    if (_position != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _position!,
                            width: 56,
                            height: 64,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFB3261E),
                                  size: 48,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                        ),
                      ],
                    ),
                  ],
                ),
                if (_loading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(),
                  ),
                if (_position == null && !_loading)
                  Align(
                    alignment: Alignment.center,
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              color: context.palette.accent,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error == null
                                  ? 'Aguardando a primeira localização'
                                  : 'Não foi possível atualizar a localização',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.title,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.palette.muted),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'O mapa será atualizado quando a pulseira enviar uma posição ao servidor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.palette.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(
                    _position == null
                        ? Icons.location_disabled_rounded
                        : Icons.my_location_rounded,
                    color: _position == null
                        ? context.palette.muted
                        : const Color(0xFF25855A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _position == null
                              ? 'Sem localização recebida'
                              : 'Última posição recebida',
                          style: TextStyle(
                            color: context.palette.title,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _position == null
                              ? 'Atualização automática a cada ${_refreshSeconds < 60 ? '$_refreshSeconds segundos' : '${_refreshSeconds ~/ 60} minuto'}'
                              : '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}'
                                    '${_lastUpdate == null ? '' : ' · ${_formatUpdate(_lastUpdate!)}'}',
                          style: TextStyle(
                            color: context.palette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
