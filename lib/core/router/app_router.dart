import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/product/screens/product_list_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_confirmation_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/shop',
            builder: (c, s) => ProductListScreen(
              initialCategory: s.uri.queryParameters['category'],
              initialSearch: s.uri.queryParameters['search'],
            ),
          ),
          GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
          GoRoute(path: '/wishlist', builder: (c, s) => const WishlistScreen()),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),

      // Full screen routes
      GoRoute(
        path: '/product/:slug',
        builder: (c, s) => ProductDetailScreen(slug: s.pathParameters['slug']!),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
      GoRoute(
        path: '/order-confirmation/:orderNumber',
        builder: (c, s) => OrderConfirmationScreen(
          orderNumber: s.pathParameters['orderNumber']!,
        ),
      ),
      GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen()),

      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
    ],
  );
}
