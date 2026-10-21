import 'package:fallah_core/fallah_core.dart';

import 'audit_info.dart';
import 'crud_repository.dart';

/// Province (`api/v1/provinces`, scope `province:*`).
class Province {
  const Province({
    required this.id,
    required this.name,
    this.audit = AuditInfo.none,
  });

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: asInt(json['id'])!,
        name: asString(json['name']) ?? '',
        audit: AuditInfo.fromJson(json),
      );

  final int id;
  final String name;
  final AuditInfo audit;

  Map<String, dynamic> toCreateJson() => {'name': name};

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'name': name,
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class ProvinceRepository extends CrudRepository<Province> {
  ProvinceRepository(super.dio)
      : super(
          path: 'provinces',
          fromJson: Province.fromJson,
          createBody: (e) => e.toCreateJson(),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );
}

/// City (`api/v1/cities`, scope `city:*`). Belongs to a [Province].
class City {
  const City({
    required this.id,
    required this.name,
    required this.provinceId,
    this.audit = AuditInfo.none,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: asInt(json['id'])!,
        name: asString(json['name']) ?? '',
        provinceId: asInt(json['provinceId']) ?? 0,
        audit: AuditInfo.fromJson(json),
      );

  final int id;
  final String name;
  final int provinceId;
  final AuditInfo audit;

  Map<String, dynamic> toCreateJson() =>
      {'name': name, 'provinceId': provinceId};

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'name': name,
        'provinceId': provinceId,
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class CityRepository extends CrudRepository<City> {
  CityRepository(super.dio)
      : super(
          path: 'cities',
          fromJson: City.fromJson,
          createBody: (e) => e.toCreateJson(),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );

  Future<Result<PagedList<City>>> byProvince(
    int provinceId, [
    PageQuery query = const PageQuery(pageSize: 200),
  ]) =>
      list(query, {'ProvinceId': provinceId});
}
