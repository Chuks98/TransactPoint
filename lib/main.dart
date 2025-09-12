import 'package:transact_point/main-layout.dart';
import 'package:transact_point/screens/airtime.dart';
import 'package:transact_point/screens/bills.dart';
import 'package:transact_point/screens/cable.dart';
import 'package:transact_point/screens/data.dart';
import 'package:transact_point/screens/edit-account.dart';
import 'package:transact_point/screens/electricity.dart';
import 'package:transact_point/screens/fund-account.dart';
import 'package:transact_point/screens/insurance.dart';
import 'package:transact_point/screens/loan.dart';
import 'package:transact_point/screens/login-normally.dart';
import 'package:transact_point/screens/savings.dart';
import 'package:transact_point/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:transact_point/screens/shopping.dart';
import 'package:transact_point/screens/support.dart';
import 'package:transact_point/screens/transfer.dart';
import 'package:transact_point/screens/travel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:transact_point/screens/wallet.dart';
import 'theme.dart';

// Screens
import './screens/home.dart';
import './screens/register.dart';
import './screens/login.dart';
import './screens/dashboard.dart';
import './screens/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const TransactPointApp());
}

class TransactPointApp extends StatefulWidget {
  const TransactPointApp({super.key});

  @override
  State<TransactPointApp> createState() => _TransactPointAppState();
}

class _TransactPointAppState extends State<TransactPointApp> {
  ThemeMode _themeMode = ThemeMode.system; // initial theme

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Transact Point",
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode, // dynamically changes theme
      initialRoute: '/login',
      routes: {
        '/':
            (context) =>
                const MainLayout(title: "Welcome", body: LoginScreen()),
        '/home':
            (context) => const MainLayout(
              title: "Welcome",
              body: HomeScreen(),
              initialIndex: 0,
            ),
        '/dashboard':
            (context) =>
                const MainLayout(title: "Dashboard", body: DashboardScreen()),
        '/profile':
            (context) => const MainLayout(
              title: "Profile",
              body: ProfileScreen(),
              initialIndex: 3,
            ),
        '/airtime':
            (context) => const MainLayout(
              title: "Airtime",
              body: AirtimeScreen(),
              showBackButton: true,
              initialIndex: 1,
            ),
        '/data':
            (context) => const MainLayout(
              title: "Data",
              body: DataScreen(),
              showBackButton: true,
            ),
        '/cabletv':
            (context) => const MainLayout(
              title: "Cable",
              body: CableScreen(),
              showBackButton: true,
            ),
        '/electricity':
            (context) => const MainLayout(
              title: "Electricity",
              body: ElectricityScreen(),
              showBackButton: true,
            ),
        '/transfer':
            (context) => const MainLayout(
              title: "Transfer",
              body: TransferScreen(),
              initialIndex: 2,
            ),
        '/loan':
            (context) => const MainLayout(title: "Loan", body: LoanScreen()),
        '/bills':
            (context) => const MainLayout(title: "Bills", body: BillsScreen()),
        '/insurance':
            (context) =>
                const MainLayout(title: "Insurance", body: InsuranceScreen()),
        '/shopping':
            (context) =>
                const MainLayout(title: "Shopping", body: ShoppingScreen()),
        '/travel':
            (context) =>
                const MainLayout(title: "Travel", body: TravelScreen()),

        '/savings':
            (context) =>
                const MainLayout(title: "Savings", body: SavingsScreen()),
        '/wallet':
            (context) => const MainLayout(
              title: "My Account",
              body: WalletScreen(),
              showBackButton: true,
            ),
        '/edit-account':
            (context) => const MainLayout(
              title: "Edit Account",
              body: EditAccountScreen(),
              showBackButton: true,
            ),
        '/fund-account':
            (context) => const MainLayout(
              title: "Fund Account",
              body: AccountFundingScreen(),
              showBackButton: true,
            ),
        '/settings':
            (context) => MainLayout(
              title: "Settings",
              body: SettingsScreen(
                toggleTheme: _toggleTheme,
                isDarkMode: _isDarkMode,
              ),
              initialIndex: 4,
            ),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/login-normally': (context) => LoginNormallyScreen(),
        '/support':
            (context) => MainLayout(
              title: "Support",
              body: SupportScreen(),
              showBackButton: true,
            ),
      },
    );
  }
}
