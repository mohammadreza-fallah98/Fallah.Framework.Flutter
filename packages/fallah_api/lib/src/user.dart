import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'audit_info.dart';

/// User (`api/v1/users`, scope `user:*`). The password is never part of a
/// response; send it only through [UserRepository.create].
class User {
  const User({
    required this.id,
    required this.roleId,
    required this.username,
    this.provinceId,
    this.cityId,
    this.firstName,
    this.lastName,
    this.nationalCode,
    this.mobile,
    this.email,
    this.phone,
    this.address,
    this.postalCode,
    this.gender,
    this.isActive = true,
    this.audit = AuditInfo.none,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asInt(json['id'])!,
        roleId: asInt(json['roleId']) ?? 0,
        username: asString(json['username']) ?? '',
        provinceId: asInt(json['provinceId']),
        cityId: asInt(json['cityId']),
        firstName: asString(json['firstName']),
        lastName: asString(json['lastName']),
        nationalCode: asString(json['nationalCode']),
        mobile: asString(json['mobile']),
        email: asString(json['email']),
        phone: asString(json['phone']),
        address: asString(json['address']),
        postalCode: asString(json['postalCode']),
        gender: asInt(json['gender']),
        isActive: asBool(json['isActive'], fallback: true),
        audit: AuditInfo.fromJson(json),
      );

  final int id;
  final int roleId;
  final String username;
  final int? provinceId;
  final int? cityId;
  final String? firstName;
  final String? lastName;
  final String? nationalCode;
  final String? mobile;
  final String? email;
  final String? phone;
  final String? address;
  final String? postalCode;

  /// `1` male, `2` female.
  final int? gender;
  final bool isActive;
  final AuditInfo audit;

  String get fullName => [firstName, lastName]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');

  Map<String, dynamic> _fields() => {
        'roleId': roleId,
        'username': username,
        'provinceId': provinceId,
        'cityId': cityId,
        'firstName': firstName,
        'lastName': lastName,
        'nationalCode': nationalCode,
        'mobile': mobile,
        'email': email,
        'phone': phone,
        'address': address,
        'postalCode': postalCode,
        'gender': gender,
        'isActive': isActive,
      };

  Map<String, dynamic> toCreateJson({required String password}) =>
      {..._fields(), 'password': password};

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        ..._fields(),
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class UserRepository {
  UserRepository(Dio dio)
      : _client = ResourceClient<User>(dio, 'users', User.fromJson);

  final ResourceClient<User> _client;

  Future<Result<PagedList<User>>> list([
    PageQuery query = const PageQuery(),
    Map<String, Object?> filters = const {},
  ]) =>
      apiCall(() => _client.list(query, filters: filters));

  Future<Result<User>> get(int id) => apiCall(() => _client.get(id));

  Future<Result<int>> create(User user, {required String password}) =>
      apiCall(() => _client.add(user.toCreateJson(password: password)));

  Future<Result<void>> edit(User user) =>
      apiCall(() => _client.edit(user.id, user.toUpdateJson()));

  Future<Result<void>> remove(int id) => apiCall(() => _client.remove(id));

  /// Activate / deactivate (deactivating revokes all of the user's sessions).
  Future<Result<void>> setActive(int id, {required bool isActive}) => apiCall(
        () => _client.action(
          'PATCH',
          'status',
          body: {'id': id, 'isActive': isActive},
        ),
      );
}
