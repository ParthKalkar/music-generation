import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool showBarChart = true;
  Map<String, int> keywordFrequency = {};

  @override
  void initState() {
    super.initState();
    fetchKeywordFrequency();
  }

  Future<void> fetchKeywordFrequency() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('musics').get();
    List<String> allKeywords = [];

    for (var doc in querySnapshot.docs) {
      String prompt = doc['name'] ?? '';
      allKeywords.addAll(prompt.split(' '));
    }

    Map<String, int> frequency = {};
    for (var keyword in allKeywords) {
      if (frequency.containsKey(keyword)) {
        frequency[keyword] = frequency[keyword]! + 1;
      } else {
        frequency[keyword] = 1;
      }
    }

    setState(() {
      keywordFrequency = frequency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keyword Analysis'),
        actions: [
          Row(
            children: [
              Text(showBarChart ? "Bar Chart" : "Pie Chart"),
              Switch(
                value: showBarChart,
                onChanged: (value) {
                  setState(() {
                    showBarChart = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: showBarChart ? buildBarChart() : buildPieChart(),
      ),
    );
  }

  Widget buildBarChart() {
    List<_ChartData> data = keywordFrequency.entries
        .toList()
        .take(20)
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,  // Rotate labels to prevent overlap
      ),
      primaryYAxis: NumericAxis(
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      title: ChartTitle(text: 'Top 20 Keywords'),
      tooltipBehavior: TooltipBehavior(enable: true),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        zoomMode: ZoomMode.xy,
      ),
      series: <ChartSeries<_ChartData, String>>[
        BarSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.keyword,
          yValueMapper: (_ChartData data, _) => data.frequency,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  Widget buildPieChart() {
    List<_ChartData> data = keywordFrequency.entries
        .toList()
        .take(20)
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return SfCircularChart(
      title: ChartTitle(text: 'Top 20 Keywords'),
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries<_ChartData, String>>[
        PieSeries<_ChartData, String>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.keyword,
          yValueMapper: (_ChartData data, _) => data.frequency,
          dataLabelMapper: (_ChartData data, _) => data.keyword,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            overflowMode: OverflowMode.shift,
          ),
        )
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.keyword, this.frequency);

  final String keyword;
  final int frequency;
}
