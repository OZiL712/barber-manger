class BarberService {
  final int? id;
  final String name;

  BarberService({this.id, required this.name});

  factory BarberService.fromMap(Map<String, dynamic> json) => BarberService(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
