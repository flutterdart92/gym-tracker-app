// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodItemModelAdapter extends TypeAdapter<FoodItemModel> {
  @override
  final int typeId = 3;

  @override
  FoodItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String?,
      caloriesPer100g: fields[3] as double,
      proteinPer100g: fields[4] as double,
      carbsPer100g: fields[5] as double,
      fatPer100g: fields[6] as double,
      isFavorite: fields[7] as bool,
      lastUsed: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItemModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.caloriesPer100g)
      ..writeByte(4)
      ..write(obj.proteinPer100g)
      ..writeByte(5)
      ..write(obj.carbsPer100g)
      ..writeByte(6)
      ..write(obj.fatPer100g)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.lastUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
