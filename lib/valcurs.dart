import 'dart:convert';

import 'package:flutter_training/unit.dart';
import 'package:http/http.dart' as http;

abstract class GetUnits{
  Future<List> getUnits();
  /// Given two units, converts from one to another.
  ///
  /// Returns a double, which is the converted amount. Returns null on error.
  Future<double> convert(double amount, Unit fromUnit, Unit toUnit);

  /// Clean up conversion; trim trailing zeros, e.g. 5.500 -> 5.5, 10.0 -> 10
  String format(double conversion) {
    var outputNum = conversion.toStringAsPrecision(7);
    if (outputNum.contains('.') && outputNum.endsWith('0')) {
      var i = outputNum.length - 1;
      while (outputNum[i] == '0') {
        i -= 1;
      }
      outputNum = outputNum.substring(0, i + 1);
    }
    if (outputNum.endsWith('.')) {
      return outputNum.substring(0, outputNum.length - 1);
    }
    return outputNum;
  }
}


class RegularUnits implements GetUnits{
  Future<List> getUnits(){
    return null;
  }
  Future<double> convert(double amount, Unit fromUnit, Unit toUnit){
    return new Future<double>(() => amount * (toUnit.conversion / fromUnit.conversion));
  }
  String format(double conversion){
    return super.format(conversion);
  }
}

class Valute {
  String id;
  num numCode;
  String charCode;
  int nominal;
  String name;
  double value;
  double previous;

  Valute(
      {this.id,
      this.numCode,
      this.charCode,
      this.nominal,
      this.name,
      this.value,
      this.previous});

  factory Valute.fromJson(Map<String, dynamic> jsonMap) {
    return Valute(
        id: jsonMap["ID"],
        numCode: int.parse(jsonMap["NumCode"]),
        charCode: jsonMap["CharCode"],
        nominal: jsonMap["Nominal"],
        name: jsonMap["Name"],
        value: jsonMap["Value"],
        previous: jsonMap["Previous"]);
  }

  @override
  String toString() {
    return "ID: $id \n" +
        "NumCode: $numCode\n" +
        "CharCode: $charCode \n" +
        "Name: " +
        name +
        " \n" +
        "Value: $value\n";
  }
}

class CbrDaily {
  DateTime date;
  DateTime previousDate;
  String previousURL;
  DateTime timestamp;
  List<Valute> valute;

  CbrDaily(
      {this.date,
      this.previousDate,
      this.previousURL,
      this.timestamp,
      this.valute});

  factory CbrDaily.fromJson(Map<String, dynamic> parsedJson) {
    return CbrDaily(
        date: DateTime.parse(parsedJson['Date']),
        previousDate: DateTime.parse(parsedJson['PreviousDate']),
        previousURL: parsedJson['PreviousURL'],
        timestamp: DateTime.parse(parsedJson['Timestamp']),
        valute: _remapValute(parsedJson['Valute']));
  }

  static List<Valute> _remapValute(Map<String, dynamic> parsedJson) {
    List<Valute> result =
        parsedJson.values.map((value) => Valute.fromJson(value)).toList();
    return result;
  }
}



//Future<void> downloadValutes(List<Unit> storedValutes) async {
//  if (storedValutes.length == 1) {
//    var curses = await http
//        .get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});
//
//    final jsonResponse = json.decode(curses.body);
//    CbrDaily cbr = new CbrDaily.fromJson(jsonResponse);
//    cbr.valute.forEach((valute) => storedValutes
//        .add(Unit(name: valute.charCode, conversion: valute.value)));
//  }
//  return "Success";
//}

class Centrabank implements GetUnits{
  final String jsonUrl = 'https://www.cbr-xml-daily.ru/daily_json.js';
  List<Valute> valutes = [Valute(id : 'RUB', name: 'Ruble', charCode : 'Ruble', value: 1.0)];
  Future<List> getUnits() async {
    List<Unit> bindValutes = [];
    if (valutes.length == 1) {
      var curses = await http
          .get(Uri.encodeFull(jsonUrl), headers: {"Accept": "application/json"});
      if (curses == null) {
        print('Error retrieving units.');
        return null;
      }
      final jsonResponse = json.decode(curses.body);
      final CbrDaily cbr = new CbrDaily.fromJson(jsonResponse);

      valutes.addAll(cbr.valute);
      valutes.forEach((valute) => bindValutes
          .add(Unit(name: valute.charCode, conversion: valute.value)));
    }
    return bindValutes;
  }
}

void main() {
  GetUnits cb = new Centrabank();
  Future<List> vls = cb.getUnits();
  vls.timeout(Duration(seconds: 5));
  vls.asStream().forEach(print);
}
