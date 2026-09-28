// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cs_rank_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CsMapAdapter extends TypeAdapter<CsMap> {
  @override
  final int typeId = 1;

  @override
  CsMap read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CsMap.mirage;
      case 1:
        return CsMap.inferno;
      case 2:
        return CsMap.dust2;
      case 3:
        return CsMap.nuke;
      case 4:
        return CsMap.ancient;
      case 5:
        return CsMap.anubis;
      case 6:
        return CsMap.vertigo;
      case 7:
        return CsMap.office;
      default:
        return CsMap.mirage;
    }
  }

  @override
  void write(BinaryWriter writer, CsMap obj) {
    switch (obj) {
      case CsMap.mirage:
        writer.writeByte(0);
        break;
      case CsMap.inferno:
        writer.writeByte(1);
        break;
      case CsMap.dust2:
        writer.writeByte(2);
        break;
      case CsMap.nuke:
        writer.writeByte(3);
        break;
      case CsMap.ancient:
        writer.writeByte(4);
        break;
      case CsMap.anubis:
        writer.writeByte(5);
        break;
      case CsMap.vertigo:
        writer.writeByte(6);
        break;
      case CsMap.office:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CsMapAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CompetitiveRankAdapter extends TypeAdapter<CompetitiveRank> {
  @override
  final int typeId = 2;

  @override
  CompetitiveRank read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CompetitiveRank.silver1;
      case 1:
        return CompetitiveRank.silver2;
      case 2:
        return CompetitiveRank.silver3;
      case 3:
        return CompetitiveRank.silver4;
      case 4:
        return CompetitiveRank.silverElite;
      case 5:
        return CompetitiveRank.silverEliteMaster;
      case 6:
        return CompetitiveRank.goldNova1;
      case 7:
        return CompetitiveRank.goldNova2;
      case 8:
        return CompetitiveRank.goldNova3;
      case 9:
        return CompetitiveRank.goldNovaMaster;
      case 10:
        return CompetitiveRank.masterGuardian1;
      case 11:
        return CompetitiveRank.masterGuardian2;
      case 12:
        return CompetitiveRank.masterGuardianElite;
      case 13:
        return CompetitiveRank.distinguishedMasterGuardian;
      case 14:
        return CompetitiveRank.legendaryEagle;
      case 15:
        return CompetitiveRank.legendaryEagleMaster;
      case 16:
        return CompetitiveRank.supremeMasterFirstClass;
      case 17:
        return CompetitiveRank.globalElite;
      default:
        return CompetitiveRank.silver1;
    }
  }

  @override
  void write(BinaryWriter writer, CompetitiveRank obj) {
    switch (obj) {
      case CompetitiveRank.silver1:
        writer.writeByte(0);
        break;
      case CompetitiveRank.silver2:
        writer.writeByte(1);
        break;
      case CompetitiveRank.silver3:
        writer.writeByte(2);
        break;
      case CompetitiveRank.silver4:
        writer.writeByte(3);
        break;
      case CompetitiveRank.silverElite:
        writer.writeByte(4);
        break;
      case CompetitiveRank.silverEliteMaster:
        writer.writeByte(5);
        break;
      case CompetitiveRank.goldNova1:
        writer.writeByte(6);
        break;
      case CompetitiveRank.goldNova2:
        writer.writeByte(7);
        break;
      case CompetitiveRank.goldNova3:
        writer.writeByte(8);
        break;
      case CompetitiveRank.goldNovaMaster:
        writer.writeByte(9);
        break;
      case CompetitiveRank.masterGuardian1:
        writer.writeByte(10);
        break;
      case CompetitiveRank.masterGuardian2:
        writer.writeByte(11);
        break;
      case CompetitiveRank.masterGuardianElite:
        writer.writeByte(12);
        break;
      case CompetitiveRank.distinguishedMasterGuardian:
        writer.writeByte(13);
        break;
      case CompetitiveRank.legendaryEagle:
        writer.writeByte(14);
        break;
      case CompetitiveRank.legendaryEagleMaster:
        writer.writeByte(15);
        break;
      case CompetitiveRank.supremeMasterFirstClass:
        writer.writeByte(16);
        break;
      case CompetitiveRank.globalElite:
        writer.writeByte(17);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompetitiveRankAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
