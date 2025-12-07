import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/db/database_helper.dart';
import '../../../core/models/api_request.dart';
import '../../../data/request_repository.dart';
import 'request_event.dart';
import 'request_state.dart';
import '../../../core/services/http_service.dart';

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final GenericRepository<ApiRequest> repository;
  final HttpService httpService;

  RequestBloc(this.repository, this.httpService) : super(RequestInitial()) {
    on<LoadRequests>(_onLoadRequests);
    on<AddRequest>(_onAddRequest);
    on<DeleteRequest>(_onDeleteRequest);
    on<SendRequest>(_onSendRequest);
  }

  // ---------------- Load all requests ----------------
  Future<void> _onLoadRequests(
      LoadRequests event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    try {
      final requests = await repository.getAll();
      emit(RequestLoaded(requests));
    } catch (e) {
      emit(RequestError(e.toString()));
    }
  }

  // ---------------- Add a new request (with environment snapshot) ----------------
  Future<void> _onAddRequest(
      AddRequest event, Emitter<RequestState> emit) async {
    try {
      // Save the environment values directly ON the request record
      final requestWithEnv = event.request.copyWith(
        authType: event.environment?.authType ?? "none",
        username: event.environment?.username,
        password: event.environment?.password,
        token: event.environment?.token,
        customHeaderKey: event.environment?.customHeaderKey,
        customHeaderValue: event.environment?.customHeaderValue,
      );

      await repository.insert(requestWithEnv.toJson());

      add(LoadRequests());
    } catch (e) {
      emit(RequestError('Failed to add request'));
    }
  }

  // ---------------- Delete a request ----------------
  Future<void> _onDeleteRequest(
      DeleteRequest event, Emitter<RequestState> emit) async {
    try {
      await repository.delete(event.id);
      add(LoadRequests());
    } catch (_) {
      emit(RequestError('Failed to delete request'));
    }
  }

  // ---------------- Send a request ----------------
  Future<void> _onSendRequest(
      SendRequest event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    bool success = false;

    try {
      final response = await httpService.send(event.request);

      // Determine if successful
      success = response.statusCode >= 200 && response.statusCode < 300;

      emit(RequestSent(response));
    } catch (e) {
      emit(RequestError('Failed to send request'));
    } finally {
      // Track statistics
      await DatabaseHelper.instance.updateStatistics(success: success);
    }
  }
}
