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
            $search = $request->query('search', '');

            $query = User::query();

            if (!empty($search)) {
                $query->where(function ($q) use ($search) {
                    $q->where('firstName', 'LIKE', "%$search%")
                    ->orWhere('lastName', 'LIKE', "%$search%")
                    ->orWhere('phoneNumber', 'LIKE', "%$search%");
                });
            }

            $users = $query->paginate(15, ['*'], 'page', $page);

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
            $search = $request->query('search');

            $query = Wallet::with('user');

            if ($search) {
                $query->whereHas('user', function($q) use ($search) {
                    $q->where('firstName', 'like', "%{$search}%")
                    ->orWhere('lastName', 'like', "%{$search}%")
                    ->orWhere('phoneNumber', 'like', "%{$search}%")
                    ->orWhere('country', 'like', "%{$search}%");
                })->orWhere('balance', 'like', "%{$search}%")
                ->orWhere('currency', 'like', "%{$search}%");
            }

            $wallets = $query->paginate(15, ['*'], 'page', $page);

            $walletsData = $wallets->map(function ($wallet) {
                return [
                    'id' => $wallet->id,
                    'user_id' => $wallet->user_id,
                    'fullName' => $wallet->user ? $wallet->user->firstName . ' ' . $wallet->user->lastName : 'Unknown',
                    'phoneNumber' => $wallet->user ? $wallet->user->phoneNumber : null,
                    'balance' => $wallet->balance,
                    'currency' => $wallet->currency,
                    'code' => $wallet->code,
                    'currencySign' => $wallet->currencySign,
                    'country' => $wallet->country,
                    'created_at' => $wallet->created_at,
                    'updated_at' => $wallet->updated_at,
                ];
            });

            return response()->json([
                'status' => 'success',
                'data' => $walletsData,
                'total' => $wallets->total(),
                'current_page' => $wallets->currentPage(),
                'last_page' => $wallets->lastPage(),
            ]);

        } catch (\Exception $e) {
            \Log::error("Fetching wallets failed: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to fetch wallets'
            ], 500);
        }
    }



    // ================== FETCH ALL TRANSACTIONS ==================
    public function getAllTransactions(Request $request)
    {
        try {
            $page = $request->query('page', 1);
            $search = $request->query('search', null);

            $query = Transaction::with('user');

            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('transaction_id', 'like', "%$search%")
                    ->orWhere('type', 'like', "%$search%")
                    ->orWhere('status', 'like', "%$search%")
                    ->orWhere('country', 'like', "%$search%")
                    ->orWhere('amount', 'like', "%$search%")
                    ->orWhereHas('user', function ($uq) use ($search) {
                        $uq->where('firstName', 'like', "%$search%")
                            ->orWhere('lastName', 'like', "%$search%")
                            ->orWhere('phoneNumber', 'like', "%$search%");
                    });
                });
            }

            $transactions = $query->paginate(15, ['*'], 'page', $page);

            $transactionsData = $transactions->map(function ($tx) {
                return [
                    'id' => $tx->id,
                    'transaction_id' => $tx->transaction_id,
                    'type' => $tx->type,
                    'amount' => $tx->amount,
                    'description' => $tx->description,
                    'status' => $tx->status,
                    'currency' => $tx->currency,
                    'currencySign' => $tx->currencySign,
                    'code' => $tx->code,
                    'country' => $tx->country,
                    'biller_code' => $tx->biller_code,
                    'item_code' => $tx->item_code,
                    'user_id' => $tx->user_id,
                    'fullName' => $tx->user ? $tx->user->firstName . ' ' . $tx->user->lastName : 'Unknown',
                    'phoneNumber' => $tx->user ? $tx->user->phoneNumber : null,
                    'created_at' => $tx->created_at,
                    'updated_at' => $tx->updated_at,
                ];
            });

            return response()->json([
                'status' => 'success',
                'data' => $transactionsData,
                'total' => $transactions->total(),
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
            ]);
        } catch (\Exception $e) {
            \Log::error("Fetching transactions failed: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to fetch transactions'
            ], 500);
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






    // savings Plans CRUD system
    public function getPlans()
    {
        try {
            $plans = Plan::all();

            \Log::info("Plans fetched successfully", ['plans' => $plans]);

            return response()->json([
                'status' => 'success',
                'data' => $plans
            ]);
        } catch (\Exception $e) {
            \Log::error("Fetching plans failed: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to fetch plans'
            ], 500);
        }
    }

    public function createPlan(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'min_amount' => 'required|numeric|min:0',
                'max_amount' => 'nullable|numeric|min:0',
                'duration_months' => 'required|integer|min:0',
                'interest_rate' => 'nullable|numeric|min:0',
                'interest_type' => 'nullable|string|in:simple,compound',
                'with_interest' => 'boolean',
                'is_locked' => 'boolean',
            ]);

            $plan = Plan::create($validated);

            \Log::info("Plan created successfully", ['plan' => $plan]);

            return response()->json([
                'status' => 'success',
                'message' => 'Plan created successfully',
                'data' => $plan
            ], 201);
        } catch (\Exception $e) {
            \Log::error("Creating plan failed: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to create plan'
            ], 500);
        }
    }

    public function updatePlan(Request $request, $id)
    {
        try {
            $plan = Plan::findOrFail($id);

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'min_amount' => 'required|numeric|min:0',
                'max_amount' => 'nullable|numeric|min:0',
                'duration_months' => 'required|integer|min:0',
                'interest_rate' => 'nullable|numeric|min:0',
                'interest_type' => 'nullable|string|in:simple,compound',
                'with_interest' => 'boolean',
                'is_locked' => 'boolean',
            ]);

            $plan->update($validated);

            \Log::info("Plan updated successfully", ['plan' => $plan]);

            return response()->json([
                'status' => 'success',
                'message' => 'Plan updated successfully',
                'data' => $plan
            ]);
        } catch (\Exception $e) {
            \Log::error("Updating plan failed: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update plan'
            ], 500);
        }
    }

    public function deletePlan($id)
    {
        try {
            $plan = Plan::findOrFail($id);
            $plan->delete();

            \Log::info("Plan deleted successfully", ['plan_id' => $id]);

            return response()->json([
                'status' => 'success',
                'message' => 'Plan deleted successfully'
            ]);
        } catch (\Exception $e) {
            \Log::error("Deleting plan failed: " . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete plan'
            ], 500);
        }
    }
}
