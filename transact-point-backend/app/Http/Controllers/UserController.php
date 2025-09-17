<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    public function register(Request $request)
    {
        try {
            // Validate base fields
            $request->validate([
                'firstName'   => 'required|string|max:255',
                'lastName'    => 'required|string|max:255',
                'phoneNumber' => 'required|string|max:20',
                'password'    => 'nullable|string|min:4|max:6', // optional PIN
            ]);

            // Check if user exists
            $user = User::where('phoneNumber', $request->phoneNumber)->first();

            if ($user) {
                return response()->json([
                    'success' => false,
                    'message' => 'This phone number is already registered. Please login.',
                ], 409); // Conflict
            }

            // 👤 If user does not exist, create them
            $newUser = User::create([
                'firstName'   => $request->firstName,
                'lastName'    => $request->lastName,
                'phoneNumber' => $request->phoneNumber,
                'password'    => $request->filled('password')
                                    ? Hash::make($request->password)
                                    : null,
            ]);

            \Log::info('New user registered', [
                'user_id' => $newUser->id,
                'phoneNumber' => $newUser->phoneNumber,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully.',
                'user'    => $newUser,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during registration', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during registration/update', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }



    // User login with phone number and PIN
    public function login(Request $request)
    {
        try {
            // Validate incoming request
            $request->validate([
                'phoneNumber' => 'required|string|max:20',
                'password'    => 'required|string|min:4|max:6', // PIN length
            ]);

            // Attempt to find user by phone number
            $user = User::where('phoneNumber', $request->phoneNumber)->first();

            if (!$user) {
                \Log::warning('Login attempt failed: user not found', [
                    'phoneNumber' => $request->phoneNumber,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'User not found.',
                ], 404);
            }

            // Verify password (PIN)
            if (!$user->password || !Hash::check($request->password, $user->password)) {
                \Log::warning('Login attempt failed: incorrect PIN', [
                    'phoneNumber' => $request->phoneNumber,
                    'attempted_pin' => $request->password,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Invalid PIN.',
                ], 401); // Unauthorized
            }

            // Successful login
            \Log::info('User logged in successfully', [
                'user_id' => $user->id,
                'phoneNumber' => $user->phoneNumber,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Login successful.',
                'data'    => $user, // you can return only needed fields if sensitive
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during login', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during login', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }



    // Fetch wallet details for a user
    public function getWallet($userId)
    {
        try {
            // ✅ Check if user exists
            $user = User::find($userId);
            if (!$user) {
                \Log::warning('Wallet fetch failed: user not found', ['user_id' => $userId]);
                return response()->json([
                    'status' => 'error',
                    'message' => 'User not found.',
                ], 404);
            }

            // ✅ Check if wallet exists
            $wallet = Wallet::where('user_id', $userId)->first();
            if (!$wallet) {
                \Log::info('Wallet not found for user', ['user_id' => $userId]);
                return response()->json([
                    'status' => 'success',
                    'data' => null, // No wallet yet
                    'message' => 'Wallet does not exist yet.',
                ], 200);
            }

            \Log::info('Wallet fetched successfully', ['user_id' => $userId]);
            return response()->json([
                'status' => 'success',
                'data' => $wallet,
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Error fetching wallet', [
                'user_id' => $userId,
                'message' => $e->getMessage(),
            ]);
            return response()->json([
                'status' => 'error',
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }



    // Create a new wallet for a user
    public function createWallet(Request $request)
    {
        try {
            // ✅ Validate request
            $request->validate([
                'user_id'      => 'required|integer|exists:users,id',
                'currency'     => 'required|string|max:5',
                'code'         => 'required|string|max:10',
                'currencySign' => 'required|string|max:5',
                'country'      => 'required|string|max:50',
            ]);

            // ✅ Check if wallet already exists
            $existingWallet = Wallet::where('user_id', $request->user_id)->first();
            if ($existingWallet) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Wallet already exists.',
                    'data' => $existingWallet,
                ], 400);
            }

            // ✅ Create wallet
            $wallet = Wallet::create([
                'user_id'      => $request->user_id,
                'balance'      => 0,
                'currency'     => $request->currency,
                'code'         => $request->code,
                'currencySign' => $request->currencySign,
                'country'      => $request->country,
            ]);

            \Log::info('Wallet created successfully', ['user_id' => $request->user_id]);

            return response()->json([
                'status' => 'success',
                'message' => 'Wallet created successfully.',
                'data' => $wallet,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Wallet creation validation failed', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed.',
                'errors' => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error creating wallet', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }


    // Update wallet details (excluding balance)
    public function updateAccount(Request $request)
    {
        try {
            // ✅ Validate request
            $request->validate([
                'user_id'      => 'required|integer|exists:users,id',
                'currency'     => 'required|string|max:5',
                'code'         => 'required|string|max:10',
                'currencySign' => 'required|string|max:5',
                'country'      => 'required|string|max:50',
                'amount'      => 'required|numeric|min:0',
            ]);

            // ✅ Find the user's wallet
            $wallet = Wallet::where('user_id', $request->user_id)->first();
            if (!$wallet) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Wallet not found for this user.',
                ], 404);
            }

            // ✅ Update wallet fields
            $wallet->update([
                'currency'     => $request->currency,
                'code'         => $request->code,
                'currencySign' => $request->currencySign,
                'country'      => $request->country,
                'balance'      => $request->amount,
            ]);

            \Log::info('Wallet updated successfully', ['user_id' => $request->user_id]);

            return response()->json([
                'status' => 'success',
                'message' => 'Wallet updated successfully.',
                'data' => $wallet,
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Wallet update validation failed', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed.',
                'errors' => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error updating wallet', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }


    // Get 10 recent transactions for a user
    public function getUserRecentTransactions($userId)
    {
        try {
            \Log::info("📡 Fetching last 10 transactions for user: {$userId}");

            $transactions = Transaction::where('user_id', $userId)
                ->orderBy('created_at', 'desc')
                ->take(10) // only 10 most recent
                ->get(['id', 'type', 'amount', 'description', 'status', 'currency', 'currencySign', 'created_at']); 

            \Log::info("✅ Transactions fetched successfully", [
                'user_id' => $userId,
                'count'   => $transactions->count()
            ]);

            return response()->json([
                'status' => 'success',
                'data'   => $transactions
            ]);
        } catch (\Exception $e) {
            \Log::error("🔥 Error fetching transactions for user {$userId}: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status'  => 'error',
                'message' => 'Unable to fetch transactions.'
            ], 500);
        }
    }



    // Get transactions
    public function getUserTransactions(Request $request, $userId)
    {
        try {
            \Log::info("📡 Fetching transactions for user: {$userId}", [
                'page' => $request->get('page', 1)
            ]);

            $transactions = Transaction::where('user_id', $userId)
                ->orderBy('created_at', 'desc')
                ->paginate(10, [
                    'id',
                    'type',
                    'amount',
                    'description',
                    'status',
                    'currency',
                    'currencySign',
                    'created_at'
                ]);

            \Log::info("✅ Transactions fetched", [
                'user_id' => $userId,
                'count'   => $transactions->count(),
                'page'    => $transactions->currentPage()
            ]);

            return response()->json([
                'status' => 'success',
                'data'   => $transactions
            ]);
        } catch (\Exception $e) {
            \Log::error("🔥 Error fetching transactions for user {$userId}: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status'  => 'error',
                'message' => 'Unable to fetch transactions.'
            ], 500);
        }
    }


}
