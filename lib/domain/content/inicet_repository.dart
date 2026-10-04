import 'inicet_models.dart';

abstract interface class InicetRepository {
  Future<List<InicetSubjectStats>> loadSubjectStats();
  Future<Map<String, InicetSubjectDetail>> loadSubjectDetails();
}
