import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postboy/features/request/widgets/request_view.dart';
import '../../core/models/api_request.dart';
import '../../core/services/http_service.dart';
import '../../data/request_repository.dart';
import 'bloc/request_bloc.dart';
import 'bloc/request_event.dart';


class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isPro = args?['isPro'] ?? false;
    return BlocProvider(
      create: (_) => RequestBloc(
        GenericRepository<ApiRequest>(
          tableName: 'requests',
          fromJson: (json) => ApiRequest.fromJson(json),
        ),
        HttpService(),
      )..add(LoadRequests()),
      child: RequestView(isPro: isPro,),
    );
  }
}