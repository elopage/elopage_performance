enum FieldType {
  number('number'),
  unknown('unknown');

  const FieldType(final this.value);
  factory FieldType.fromString(final String? value) =>
      FieldType.values.firstWhere((t) => value == t.value, orElse: () => unknown);

  final String value;
}
