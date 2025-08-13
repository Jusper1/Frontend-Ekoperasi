import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SelectLocationPage extends StatefulWidget {
  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? selectedLocation;
  LatLng? userLocation;
  String? selectedAddress;
  final MapController _mapController = MapController();
  final PopupController _popupController = PopupController();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("GPS tidak aktif, gunakan lokasi default")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Izin lokasi ditolak permanen")),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
      selectedLocation = userLocation;
      _mapController.move(userLocation!, 15.0);
    });

    await _getAddressFromLatLng(position.latitude, position.longitude);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        String address =
            "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}, ${p.country}";

        setState(() {
          selectedAddress = address;
          _searchController.text = address;
        });
      }
    } catch (e) {
      print("Gagal mengambil alamat: $e");
    }
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    try {
      List<Location> locations =
          await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng latLng = LatLng(loc.latitude, loc.longitude);

        setState(() {
          selectedLocation = latLng;
          _mapController.move(latLng, 15.0);
        });

        await _getAddressFromLatLng(latLng.latitude, latLng.longitude);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lokasi tidak ditemukan")),
        );
      }
    } catch (e) {
      print("Error mencari lokasi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mencari lokasi")),
      );
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5");
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data
          .map((e) => {
                'display_name': e['display_name'],
                'lat': double.parse(e['lat']),
                'lon': double.parse(e['lon']),
              })
          .toList();
    } else {
      throw Exception("Gagal mengambil data lokasi");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pilih Lokasi")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Cari Lokasi",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: userLocation ??
                    LatLng(-0.3048953795079559, 100.36948650078536),
                zoom: 15.0,
                onTap: (tapPosition, latLng) async {
                  setState(() {
                    selectedLocation = latLng;
                  });
                  await _getAddressFromLatLng(
                      latLng.latitude, latLng.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (selectedLocation != null)
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: selectedLocation!,
                          child: Icon(Icons.location_pin,
                              color: Colors.red, size: 40),
                        ),
                      ],
                      popupController: _popupController,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (selectedLocation != null && selectedAddress != null) {
            Navigator.pop(context, {
              'lat': selectedLocation!.latitude,
              'lng': selectedLocation!.longitude,
              'address': selectedAddress,
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Silakan pilih lokasi!")),
            );
          }
        },
        label: Text("Pilih Lokasi"),
        icon: Icon(Icons.check),
      ),
    );
  }
}
