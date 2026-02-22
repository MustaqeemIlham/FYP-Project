import 'package:go_router/go_router.dart';
import '../screen/home_screen.dart';
import '../screen/sigin_screen.dart';
import '../screen/signup_screen.dart';
import '../screen/resetpassword.dart';
import '../screen/profile_screen.dart';
// import '../screen/recommendation_screen.dart';
import '../screen/community screen.dart';
import '../screen/addpost_screen.dart';
import '../screen/edit_profile_screen.dart';
import '../screen/history_screen.dart';
import '../screen/support_screen.dart';
import '../screen/reminder_screen.dart';
import '../screen/recom2_screen.dart';
final GoRouter appRouter = GoRouter(
  initialLocation: '/sigin',
  routes: [
    GoRoute(
      path: '/sigin',
      builder: (context, state) => SignInPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
 
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignUpPage(),
    ),
    GoRoute(
      path: '/forgotpass',
      builder: (context, state) => ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: '/recom2',
      builder: (context, state) => CropRecommendationsPage(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => CommunityScreen(),
    ),
    GoRoute(
      path: '/addpost',
      builder: (context, state) => AddPostScreen(),
    ),
     GoRoute(
      path: '/edit',
      builder: (context, state) => EditProfilePage(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => RecommendationHistoryPage(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => HelpSupportPage(),
    ),
    GoRoute(
      path: '/noti',
      builder: (context, state) => NotificationsPage(),
    ),
  ],
);
