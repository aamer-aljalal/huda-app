// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dhikr_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DhikrModelAdapter extends TypeAdapter<DhikrModel> {
  @override
  final int typeId = 0;

  @override
  DhikrModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DhikrModel(
      text: fields[0] as String,
      targetCount: fields[1] as int,
      currentCount: fields[2] as int,
      createdAt: fields[3] as DateTime,
      lastUpdated: fields[4] as DateTime,
      isReminderEnabled: (fields[5] as bool?) ?? false,
      reminderHour: (fields[6] as int?) ?? 9,
      reminderMinute: (fields[7] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, DhikrModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.targetCount)
      ..writeByte(2)
      ..write(obj.currentCount)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.isReminderEnabled)
      ..writeByte(6)
      ..write(obj.reminderHour)
      ..writeByte(7)
      ..write(obj.reminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DhikrModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
