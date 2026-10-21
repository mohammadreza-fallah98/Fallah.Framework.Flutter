import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/network/dio_provider.dart';

part 'api_providers.g.dart';

// fallah_api is the data layer of the base entities, so presentation reads
// these repositories directly instead of going through usecases.

@riverpod
UserRepository userRepository(Ref ref) => UserRepository(ref.watch(dioProvider));

@riverpod
RoleRepository roleRepository(Ref ref) => RoleRepository(ref.watch(dioProvider));

@riverpod
RoleScopeRepository roleScopeRepository(Ref ref) =>
    RoleScopeRepository(ref.watch(dioProvider));

@riverpod
ProvinceRepository provinceRepository(Ref ref) =>
    ProvinceRepository(ref.watch(dioProvider));

@riverpod
CityRepository cityRepository(Ref ref) => CityRepository(ref.watch(dioProvider));

@riverpod
AuditLogRepository auditLogRepository(Ref ref) =>
    AuditLogRepository(ref.watch(dioProvider));

@riverpod
ChatRepository chatRepository(Ref ref) => ChatRepository(ref.watch(dioProvider));

@riverpod
AttachmentRepository attachmentRepository(Ref ref) =>
    AttachmentRepository(ref.watch(dioProvider));

@riverpod
AttachmentChatRepository attachmentChatRepository(Ref ref) =>
    AttachmentChatRepository(ref.watch(dioProvider));

/// All roles (drop-downs, role list).
@riverpod
Future<List<Role>> rolesLookup(Ref ref) async {
  final page = await ref
      .watch(roleRepositoryProvider)
      .list(const PageQuery(pageSize: 200));
  return page.getOrThrow().items;
}

/// All provinces (there are few; one page is enough).
@riverpod
Future<List<Province>> provincesLookup(Ref ref) async {
  final page = await ref
      .watch(provinceRepositoryProvider)
      .list(const PageQuery(pageSize: 200));
  return page.getOrThrow().items;
}

/// Cities of one province.
@riverpod
Future<List<City>> citiesLookup(Ref ref, int provinceId) async {
  final page = await ref.watch(cityRepositoryProvider).byProvince(provinceId);
  return page.getOrThrow().items;
}
