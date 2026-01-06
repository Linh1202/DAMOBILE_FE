import '../Repositories/GroupRepository.dart';
import '../Models/Chat.dart';

class GroupService {
  final GroupRepository _groupRepository = GroupRepository();

  Future<Chat> createGroup({
    required String name,
    required String description,
    required String creatorId,
  }) async {
    return await _groupRepository.createGroup(
      name: name,
      description: description,
      creatorId: creatorId,
    );
  }

  Future<Chat> getGroupById(String id) async {
    return await _groupRepository.getGroupById(id);
  }

  Future<List<Chat>> getGroupsByCreator(String creatorId) async {
    return await _groupRepository.getGroupsByCreator(creatorId);
  }

  Future<bool> addMember(String groupId, String userId) async {
    return await _groupRepository.addMember(groupId, userId);
  }

  Future<bool> removeMember(String groupId, String userId) async {
    return await _groupRepository.removeMember(groupId, userId);
  }
}