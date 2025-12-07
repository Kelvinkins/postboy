import 'package:equatable/equatable.dart';
import '../../../core/models/api_request.dart';
import '../../../core/models/api_response.dart';

abstract class RequestState extends Equatable {
  const RequestState();
  @override
  List<Object?> get props => [];
}

class RequestInitial extends RequestState {}

class RequestLoading extends RequestState {}


class RequestLoaded extends RequestState {
  final List<ApiRequest> requests;
  final Map<int, String?>? executedEnvironments; // requestId -> environmentName

  const RequestLoaded(this.requests, {this.executedEnvironments});

  @override
  List<Object?> get props => [requests, executedEnvironments ?? {}];
}


class RequestError extends RequestState {
  final String message;
  const RequestError(this.message);
  @override
  List<Object?> get props => [message];
}

class RequestSent extends RequestState {
  final ApiResponse response;
  const RequestSent(this.response);
  @override
  List<Object?> get props => [response];
}



