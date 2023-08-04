import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:practical_task/Models/location_model.dart';
import 'package:http/http.dart' as http;
import 'constant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  TransitionBuilder? get _builder =>
      ((context, child) => StreamBuilder<ConnectivityResult>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final ConnectivityResult conenctivityResult = snapshot.data!;
              if (conenctivityResult == ConnectivityResult.none) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/no_connection.png",
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            return child!;
          }));

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: _builder,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocationModel locations = LocationModel();
  List<String> tabName = [];
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      var response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/place/search/json?location=23.03744,72.566&rankby=distance&sensor=true&key=AIzaSyB2Az9gVUzQULUc55xQD9AE7gj9Ni5hvJk'));
      if (response.statusCode == 200) {
        setState(() {
          var data = json.decode(response.body);
          log('API response: ${response.body}');
          locations = LocationModel.fromJson(data);
          isOffline = false;
          /*locations.results!.map((resultList){
            log('Types: ${resultList.types}');
            resultList.types!.map((typeData){
              if(!tabName.contains(typeData)){
                tabName.add(typeData);
              }
            });
          });*/
          for(var i=0; i<locations.results!.length ; i++){
            for(var j=0; j<locations.results![i].types!.length ; j++){
              if(!tabName.contains(locations.results![i].types![j])){
                tabName.add(locations.results![i].types![j]);
              }
            }
          }
          log('Tab list: ${tabName.map((e) => e)}');
        });
      } else {
        // Handle API error
        log('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle connection error
      setState(() {
        isOffline = true;
      });
      log('Connection Error: $e');
    }
  }

  bool _sortAscendingName = true;
  bool _sortAscendingNearByPlace = true;

  void _sortByName(bool ascending) {
    setState(() {
      _sortAscendingName = ascending;
      locations.results!.sort((a, b) => ascending
          ? a.name!.compareTo(b.name!)
          : b.name!.compareTo(a.name!));
    });
  }

  void _sortByNearBy(bool ascending) {
    setState(() {
      _sortAscendingNearByPlace = ascending;
      locations.results!.sort((a, b) => ascending
          ? Geolocator.distanceBetween(23.03744,72.566, double.parse(a.geometry!.location!.lat.toString()),double.parse(a.geometry!.location!.lng.toString())).compareTo(Geolocator.distanceBetween(23.03744,72.566, double.parse(b.geometry!.location!.lat.toString()),double.parse(b.geometry!.location!.lng.toString())))
          : Geolocator.distanceBetween(23.03744,72.566, double.parse(b.geometry!.location!.lat.toString()),double.parse(b.geometry!.location!.lng.toString())).compareTo(Geolocator.distanceBetween(23.03744,72.566, double.parse(a.geometry!.location!.lat.toString()),double.parse(a.geometry!.location!.lng.toString()))));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabName.length,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Location List'),
              const Expanded(child: SizedBox()),
              IconButton(onPressed: () {
                  _sortByName(!_sortAscendingName);
                },
                icon: const Icon(Icons.filter_alt_rounded),
                tooltip: 'Sort by name',
              ),
              const SizedBox(width: 5),
              IconButton(
                onPressed: () {
                  _sortByNearBy(!_sortAscendingNearByPlace);
                },
                icon: const Icon(Icons.social_distance),
                tooltip: 'Sort by Near By',
              ),
            ],
          ),
          bottom: TabBar(tabs: tabName.map((e) => Tab(text: e)).toList()),
        ),
        body: isOffline ?
        const Center(
          child: Text('No internet connection. Displaying stored data.'),
        ) : TabBarView(
          children: tabName.map((e) => ListView.builder(
            itemCount: locations.results?.length,
            itemBuilder: (context, index) {
              final location = locations.results?[index];
              return (location!.types!.contains(e)) ? Card(
                shape: Border.all(width: 1),
                shadowColor: const Color(0xFF000000),
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                elevation: 0.2,
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${location.name ?? ''}', style: const TextStyle(color: Colors.white)),
                      Text('Address: ${location.vicinity ?? ''}', style: const TextStyle(color: Colors.white)),
                      Text('Distance: ${Geolocator.distanceBetween(23.03744,72.566, double.parse(location.geometry!.location!.lat.toString()),double.parse(location.geometry!.location!.lng.toString()))}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                // subtitle: Image.network(location?.icon ?? ''),
                // Add more details here if needed
              ) : const SizedBox();
            },
          ),).toList(),
        ),
      ),
    );
  }
}
