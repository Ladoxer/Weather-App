import 'dart:convert';
import 'dart:ui';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:weather_app/additional_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weatherData;
  final String openWeatherApiKey = dotenv.env['OPEN_WEATHER_API_KEY'] ?? '';
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      String cityName = 'London';
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherApiKey',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != "200") {
        throw data['message'];
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weatherData = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weatherData = getCurrentWeather();
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: FutureBuilder(
        future: weatherData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final currentPressure = currentWeatherData['main']['pressure'];
          final currentHumidity = currentWeatherData['main']['humidity'];
          final currentWind = currentWeatherData['wind']['speed'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // main card
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              '$currentTemp K',
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Icon(
                                currentSky == 'Clouds' || currentSky == 'Rain'
                                    ? Icons.cloud
                                    : Icons.sunny,
                                size: 64),
                            const SizedBox(height: 16),
                            Text(
                              currentSky,
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // weather forecast cards
              const Text(
                'Hourly Forecast',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     children: [
              //       for (int i = 0; i < 5; i++)
              //         HourlyForecastItem(
              //           time: data['list'][i + 1]['dt_txt'],
              //           icon: data['list'][i + 1]['weather'][0]['main'] ==
              //                       'Clouds' ||
              //                   data['list'][i + 1]['weather'][0]['main'] ==
              //                       'Rain'
              //               ? Icons.cloud
              //               : Icons.sunny,
              //           temperature:
              //               data['list'][i + 1]['main']['temp'].toString(),
              //         ),
              //     ],
              //   ),
              // ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: 5,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final hourlyForescastData = data['list'][index + 1];
                    final hourlySky = hourlyForescastData['weather'][0]['main'];
                    final hourlyTemp =
                        hourlyForescastData['main']['temp'].toString();
                    final hourlyTime = DateTime.parse(
                      hourlyForescastData['dt_txt']
                    );
                    return HourlyForecastItem(
                      time: DateFormat.Hm().format(hourlyTime),
                      icon: hourlySky == 'Clouds' || hourlySky == 'Rain'
                          ? Icons.cloud
                          : Icons.sunny,
                      temperature: hourlyTemp,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // additional information
              const Text(
                'Additional Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AdditionalInfoItem(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '$currentHumidity %',
                  ),
                  AdditionalInfoItem(
                    icon: Icons.wind_power,
                    label: 'Wind Speed',
                    value: '$currentWind km/h',
                  ),
                  AdditionalInfoItem(
                    icon: Icons.thermostat,
                    label: 'Pressure',
                    value: '$currentPressure hPa',
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}
