import 'package:equatable/equatable.dart';
import '../../../core/models/api_request.dart';
import '../../../core/models/environment.dart';

abstract class RequestEvent extends Equatable {
  const RequestEvent();
  @override
  List<Object?> get props => [];
}

class LoadRequests extends RequestEvent {}

class AddRequest extends RequestEvent {
  final ApiRequest request;
  final Environment? environment; // ✅ Add this

  const AddRequest(this.request, {this.environment});

  @override
  List<Object?> get props => [request, environment];
}

class DeleteRequest extends RequestEvent {
  final int id;
  const DeleteRequest(this.id);

  @override
  List<Object?> get props => [id];
}

class SendRequest extends RequestEvent {
  final ApiRequest request;
  const SendRequest(this.request);

  @override
  List<Object?> get props => [request];
}
