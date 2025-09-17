<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;

class AdminController extends Controller
{
    // ================== ADMIN LOGIN ==================
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        try {
            // Hardcode your admin credentials here
            $adminUsername = "admin";
            $adminPassword = "dfd678@&"; // Or better: hash if you want

            if ($request->username === $adminUsername && $request->password === $adminPassword) {
                return response()->json([
                    'success' => true,
                    'message' => 'Admin login successful!',
                    'data'    => [
                        'username' => $adminUsername,
                    ]
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);

        } catch (\Exception $e) {
            \Log::error("Admin login failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Login failed'], 500);
        }
    }


    // ================== LOGOUT ADMIN ==================
    public function logout(Request $request)
    {
        try {
            $request->user()->currentAccessToken()->delete();

            return response()->json([
                'success' => true,
                'message' => 'Admin logged out successfully.',
            ]);
        } catch (\Exception $e) {
            Log::error("Admin logout failed: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Logout failed'], 500);
        }
    }

    // ================== GET LOGGED-IN ADMIN ==================
    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user(),
        ]);
    }

    // ================== FETCH ALL USERS ==================
    public function getAllUsers(Request $request)
    {
        try {
            $page = $request->query('page', 1);
            $users = User::paginate(15, ['*'], 'page', $page);

            return response()->json([
                'status' => 'success',
                'data' => $users->items(),
                'total' => $users->total(),
                'current_page' => $users->currentPage(),
            ]);
        } catch (\Exception $e) {
            Log::error("Fetching users failed: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Failed to fetch users'], 500);
        }
    }

    // ================== FETCH ALL WALLETS ==================
    public function getAllWallets(Request $request)
    {
        try {
            $page = $request->query('page', 1);
            $wallets = Wallet::paginate(15, ['*'], 'page', $page);

            return response()->json([
                'status' => 'success',
                'data' => $wallets->items(),
                'total' => $wallets->total(),
                'current_page' => $wallets->currentPage(),
            ]);
        } catch (\Exception $e) {
            Log::error("Fetching wallets failed: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Failed to fetch wallets'], 500);
        }
    }

    // ================== FETCH ALL TRANSACTIONS ==================
    public function getAllTransactions(Request $request)
    {
        try {
            $page = $request->query('page', 1);
            $transactions = Transaction::paginate(15, ['*'], 'page', $page);

            return response()->json([
                'status' => 'success',
                'data' => $transactions->items(),
                'total' => $transactions->total(),
                'current_page' => $transactions->currentPage(),
            ]);
        } catch (\Exception $e) {
            Log::error("Fetching transactions failed: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Failed to fetch transactions'], 500);
        }
    }

    // ================== FETCH TRANSACTIONS BY STATUS ==================
    public function getTransactionsByStatus(Request $request, $status)
    {
        try {
            $page = $request->query('page', 1);
            $transactions = Transaction::where('status', $status)
                                       ->paginate(15, ['*'], 'page', $page);

            return response()->json([
                'status' => 'success',
                'data' => $transactions->items(),
                'total' => $transactions->total(),
                'current_page' => $transactions->currentPage(),
            ]);
        } catch (\Exception $e) {
            Log::error("Fetching transactions by status failed: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Failed to fetch transactions'], 500);
        }
    }

    // ================== FETCH SINGLE WALLET BY USER ==================
    public function getWalletByUser($userId)
    {
        try {
            $wallet = Wallet::where('user_id', $userId)->first();

            if (!$wallet) {
                return response()->json(['status' => 'error', 'message' => 'Wallet not found'], 404);
            }

            return response()->json(['status' => 'success', 'data' => $wallet]);
        } catch (\Exception $e) {
            Log::error("Fetching wallet failed: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Failed to fetch wallet'], 500);
        }
    }
}
