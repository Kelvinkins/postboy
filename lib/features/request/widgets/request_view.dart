import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:postboy/features/request/widgets/request_form.dart';
import 'package:postboy/features/request/widgets/response_panel.dart';

import '../bloc/request_bloc.dart';
import '../bloc/request_state.dart';

class RequestView extends StatefulWidget {
  final bool isPro;
  const RequestView({super.key, required this.isPro});

  @override
  State<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<RequestView> {
  bool showForm = true;
  dynamic jsonData;

  int responseStatus = 200;
  Map<String, String>? responseHeaders;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-2109400871305297/4299718563',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RequestBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postboy Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(showForm ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => showForm = !showForm),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (showForm) RequestForm(bloc: bloc),

          // Listen to RequestBloc for response updates
          Expanded(
            child: BlocConsumer<RequestBloc, RequestState>(
              listener: (context, state) {
                if (state is RequestSent) {
                  setState(() {
                    jsonData = state.response.data;
                    responseStatus = state.response.statusCode;
                    responseHeaders = state.response.headers;
                  });
                } else if (state is RequestError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                // Show a loading indicator while sending
                if (state is RequestLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (jsonData!=null) {
                  return ResponsePanel(
                    body: jsonData,
                    statusCode: responseStatus,
                    headers: responseHeaders,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isBannerAdReady
    ? (!widget.isPro
    ? SizedBox(
    height: _bannerAd.size.height.toDouble(),
    width: _bannerAd.size.width.toDouble(),
    child: AdWidget(ad: _bannerAd),
    )
        : const SizedBox.shrink())
    : null,

    );
  }
}
