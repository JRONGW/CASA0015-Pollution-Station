import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/physical_test_screen.dart';
import 'screens/suggestions_screen.dart';
import 'screens/supplements_screen.dart';

import 'widgets/gradient_wrapper.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GradientWrapper(child: HomeScreen()),
      ),
      GoRoute(
        path: '/connection',
        builder: (context, state) => const GradientWrapper(child: ConnectionScreen()),
      ),  
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const GradientWrapper(child: DashboardScreen()),
      ),
      GoRoute(
        path: '/suggestions',
        builder: (context, state) => const GradientWrapper(child: SuggestionsScreen()),
      ),
      GoRoute(
        path: '/supplements',
        builder: (context, state) => const GradientWrapper(child: SupplementsScreen()),
      ),
      GoRoute(
        path: '/physical-test',
        builder: (context, state) => const GradientWrapper(child: PhysicalTestScreen()),
      ),
    ],
  );
}
