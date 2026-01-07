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
import '../../presentation/pages/patients/patients_list_page.dart';
import '../../presentation/pages/patients/patient_form_page.dart';
import '../../presentation/pages/patients/patient_detail_page.dart';
import '../../services/auth_service.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    try {
      final isLoggedIn = await _authService.checkAuth();
      final isGoingToLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      
      // Se não está logado e não está indo para login/register, redirecionar para login
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      
      // Se está logado e está indo para login/register, redirecionar para dashboard
      if (isLoggedIn && isGoingToLogin) {
        return '/dashboard';
      }
      
      return null; // Não redirecionar
    } catch (e) {
      // Em caso de erro, permitir acesso (pode ser problema de rede)
      // Mas redirecionar para login se não estiver indo para login/register
      final isGoingToLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!isGoingToLogin) {
        return '/login';
      }
      return null;
    }
  },
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
      path: '/clinical/recording/:consultationId',
      builder: (context, state) {
        final consultationId = state.pathParameters['consultationId'];
        return ClinicalRecordingPage(consultationId: consultationId);
      },
    ),
    GoRoute(
      path: '/clinical/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        // Se o id for "recording", não é uma consulta válida
        if (id == 'recording') {
          return const ClinicalRecordingPage();
        }
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
    // Patient routes
    GoRoute(
      path: '/patients',
      builder: (context, state) => const PatientsListPage(),
    ),
    GoRoute(
      path: '/patients/new',
      builder: (context, state) => const PatientFormPage(),
    ),
    GoRoute(
      path: '/patients/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PatientDetailPage(patientId: id);
      },
    ),
    GoRoute(
      path: '/patients/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PatientFormPage(patientId: id);
      },
    ),
  ],
);

