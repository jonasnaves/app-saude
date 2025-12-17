import 'package:go_router/go_router.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/clinical/clinical_list_page.dart';
import '../../presentation/pages/clinical/clinical_recording_page.dart';
import '../../presentation/pages/clinical/clinical_detail_page.dart';
import '../../presentation/pages/support/support_hub_page.dart';
import '../../presentation/pages/support/support_chat_page.dart';
import '../../presentation/pages/business/business_hub_page.dart';
import '../../presentation/pages/business/drug_catalog_page.dart';
import '../../presentation/pages/profile/profile_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    // Dashboard
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    // Clinical routes
    GoRoute(
      path: '/clinical',
      builder: (context, state) => const ClinicalListPage(),
    ),
    GoRoute(
      path: '/clinical/recording',
      builder: (context, state) => const ClinicalRecordingPage(),
    ),
    GoRoute(
      path: '/clinical/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ClinicalDetailPage(consultationId: id);
      },
    ),
    // Support routes
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportHubPage(),
    ),
    GoRoute(
      path: '/support/chat/:mode',
      builder: (context, state) {
        final mode = state.pathParameters['mode']!;
        return SupportChatPage(mode: mode);
      },
    ),
    // Business routes
    GoRoute(
      path: '/business',
      builder: (context, state) => const BusinessHubPage(),
    ),
    GoRoute(
      path: '/business/catalog',
      builder: (context, state) => const DrugCatalogPage(),
    ),
    // Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);

