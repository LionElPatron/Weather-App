import 'package:flutter/material.dart';
import 'weather_service.dart';
import 'weather_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wetter App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue[50],
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  WeatherModel? _weather;
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _getWeather() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte geben Sie eine Stadt ein.';
        _weather = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final coordinates = await WeatherService().getCoordinatesbyCity(_controller.text);
      if (coordinates.isEmpty) {
        throw Exception('Koordinaten konnten nicht abgerufen werden.');
      }

      final latitude = coordinates['latitude'];
      final longitude = coordinates['longitude'];

      final weather = await WeatherService().getWeather(latitude!, longitude!, _controller.text);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      setState(() {
        _weather = null;
        _errorMessage = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Image.asset(
              'assets/weather_icon.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text('Wetter App'),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 50),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Stadt eingeben',
                  hintText: 'Z. B. Langen',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => _getWeather(),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? Center(child: CircularProgressIndicator()) // Ladeanzeige
                  : _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        )
                      : _weather != null
                          ? WeatherDetails(weather: _weather!)
                          : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherDetails extends StatelessWidget {
  final WeatherModel weather;

  const WeatherDetails({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    // Icons basierend auf dem Wettertyp
    IconData weatherIcon = Icons.wb_sunny; // Standard: Sonne
    if (weather.description?.contains('Mild') ?? false) {
      weatherIcon = Icons.umbrella;
    } else if (weather.description?.contains('Kühl') ?? false) {
      weatherIcon = Icons.air;
    } else if (weather.description?.contains('Frostig') ?? false) {
      weatherIcon = Icons.ac_unit;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          weather.cityName, // Stadtname wird hier angezeigt
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(weatherIcon, size: 60, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              '${weather.temperature} °C',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          weather.description ?? 'Keine Beschreibung verfügbar',
          style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Max. Temp.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${weather.maxTemperature} °C',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 30),
              Column(
                children: [
                  Text(
                    'Min. Temp.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${weather.minTemperature} °C',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Aktualisiert am',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 5),
                Text(
                  formatDate(weather.datetime),
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  'Uhrzeit',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 5),
                Text(
                  formatTime(weather.datetime),
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
