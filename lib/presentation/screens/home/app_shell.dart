import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';
import 'package:toktok/presentation/screens/filters/filters_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceFilterProvider(),
      child: const _ShellBody(),
    );
  }
}

class _ShellBody extends StatefulWidget {
  const _ShellBody();

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  int _index = 0;

  void _showOnFeed(VideoPost video) {
    context.read<DiscoverProvider>().insertUploaded(video);
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final onFeed = _index == 0;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomInset =
        keyboardOpen ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _barColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Offstage(
                        offstage: !onFeed,
                        child: DiscoverScreen(playbackEnabled: onFeed),
                      ),
                      if (!onFeed) FiltersScreen(onUploaded: _showOnFeed),
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: _barColor,
                border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: MediaQuery(
                  data:
                      MediaQuery.of(context).removePadding(removeBottom: true),
                  child: NavigationBar(
                    backgroundColor: _barColor,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: const Color(0xFF5C3144),
                    selectedIndex: _index,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    onDestinationSelected: (index) =>
                        setState(() => _index = index),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Feed',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.face_retouching_natural_outlined),
                        selectedIcon: Icon(Icons.face_retouching_natural),
                        label: 'Filtros',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _barColor = Color(0xFF161616);
