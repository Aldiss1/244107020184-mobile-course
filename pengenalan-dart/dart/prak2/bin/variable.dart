
late int a;
void main(List<String> args) {
  int a = 10;
  double b = 3.14;
  String c = 'hello, dart';
  bool d = true;

  print('Integer : $a');
  print('Double : $b');
  print('String : $c');
  print('Boolean : $d');

  String e = '12';
  int f = a + int.parse(e);

  print('hasil penjumlahan $f');

  List<String> listNama = ['aldi', 'surya', 'satriawan'];
  List<int> listNilai = [1, 2, 3, 4, 5];

  print('Names: $listNama');
  print('First name : ${listNama[0]}');
  print('Number: $listNilai');
  print('Numbers length: ${listNilai.length}');

  Map<String, int> ages = {'Alice': 25, 'Bob': 30, 'Charlie': 35};
  print('Ages: ${ages['Alice']}');
  dynamic g = 'Hello';
  print('Dynamic: $g');
  g = 42;
  print('Dynamic: $g');
}
