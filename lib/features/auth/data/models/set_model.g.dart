// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetModelAdapter extends TypeAdapter<SetModel> {
  @override
  final int typeId = 5;

  @override
  SetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SetModel(
      weight: fields[0] as double,
      reps: fields[1] as int,
      rpe: fields[2] as double?,
      type: fields[3] as String,
      isDone: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SetModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.weight)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.rpe)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.isDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
