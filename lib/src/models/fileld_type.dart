enum FieldType {
  number('number'),
  unknown('unknown');

  const FieldType(this.value);
  factory FieldType.fromString(final String? value) =>
      FieldType.values.firstWhere((t) => value == t.value, orElse: () => unknown);

  static List<FieldType> get defined => [number];
  final String value;
}
