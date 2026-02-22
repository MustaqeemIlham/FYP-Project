import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class MainNavigationBar extends StatelessWidget {
  final Widget child;
  const MainNavigationBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/reco');
              break;
            case 2:
              context.go('/profile');
              break;
            case 3:
              context.go('/community');
              break;
          }
        },
              items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Recommendation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

 int _calculateSelectedIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.toString();

  if (location.startsWith('/recommendation')) {
    return 1;
  }
  if (location.startsWith('/community')) {
    return 2;
  }
  if (location.startsWith('/profile')) {
    return 3;
  }
  return 0; // default = home
}

}
