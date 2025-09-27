<?php

namespace App\Http\Controllers;

use App\Mail\ForgotPasswordMail;
use Illuminate\Support\Facades\Mail;
use App\Services\FlutterwaveService;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use App\Models\VirtualAccount;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    protected $flutterwaveService;

    public function __construct(FlutterwaveService $flutterwaveService)
    {
        $this->flutterwaveService = $flutterwaveService;
    }


    public function register(Request $request)
    {
        try {
            // ✅ Validate base fields
            $request->validate([
                'firstName'   => 'required|string|max:255',
                'lastName'    => 'required|string|max:255',
                'email'       => 'required|string|email|max:255|unique:users,email',
                'phoneNumber' => 'required|string|max:20|unique:users,phoneNumber',
                'password'    => 'nullable|string|min:4|max:6', // optional PIN
                'bvn'         => 'required|string|min:11|max:11', // 👈 Ensure BVN is valid
            ]);

            // ✅ Wrap in DB transaction
            return \DB::transaction(function () use ($request) {
                // 👤 Create new user
                $newUser = User::create([
                    'firstName'   => $request->firstName,
                    'lastName'    => $request->lastName,
                    'email'       => $request->email,
                    'phoneNumber' => $request->phoneNumber,
                    'password'    => $request->filled('password')
                                        ? \Hash::make($request->password)
                                        : null,
                ]);

                // Generate va_ref
                $vaRef = 'VA_USER_' . $newUser->id . '_' . time();

                // 🌐 Call Flutterwave
                $flwData = $this->flutterwaveService->createStaticVirtualAccount([
                    'email'       => $newUser->email,
                    'va_ref'      => $vaRef,
                    'firstname'   => $newUser->firstName,
                    'lastname'    => $newUser->lastName,
                    'phonenumber' => $newUser->phoneNumber,
                    'narration'   => "Creating virtual account {$newUser->id}",
                    'bvn'         => $request->bvn,
                ]);

                if (empty($flwData['account_number'])) {
                    throw new \Exception('Virtual account creation failed.');
                }

                // Save VA details
                $va = VirtualAccount::create([
                    'user_id'        => $newUser->id,
                    'account_number' => $flwData['account_number'],
                    'account_name'   => $flwData['account_name'] ?? ($newUser->firstName.' '.$newUser->lastName),
                    'bank_name'      => $flwData['bank_name'] ?? null,
                    'bank_code'      => $flwData['bank_code'] ?? null,
                    'currency'       => $flwData['currency'] ?? 'NGN',
                    'currency_sign'  => $flwData['currency_sign'] ?? '₦',
                    'country'        => $flwData['country'] ?? 'NG',

                    'reference'      => $flwData['reference'] ?? null,
                    'order_ref'      => $flwData['order_ref'] ?? null,
                    'status'         => $flwData['status'] ?? null,

                    // 👇 Extra fields
                    'va_ref'         => $flwData['va_ref'] ?? ($flwData['meta']['va_ref'] ?? null),
                    'flw_ref'        => $flwData['flw_ref'] ?? ($flwData['meta']['flw_ref'] ?? null),
                    'account_status' => $flwData['account_status'] ?? ($flwData['meta']['account_status'] ?? null),
                    'frequency'      => $flwData['frequency'] ?? ($flwData['meta']['frequency'] ?? null),
                    'expiry_date'    => $flwData['expiry_date'] ?? ($flwData['meta']['expiry_date'] ?? null),
                    'note'           => $flwData['note'] ?? ($flwData['meta']['note'] ?? null),
                    'amount'         => $flwData['amount'] ?? ($flwData['meta']['amount'] ?? 0.00),

                    // keep full response in meta for reference
                    'meta'           => $flwData,
                ]);

                \Log::info("Registration Successful!", ['user'    => $newUser, 'virtualAccount' => $flwData,]);


                return response()->json([
                    'success' => true,
                    'message' => 'User registered & virtual account created successfully.',
                    'user'    => $newUser,
                    'virtualAccount' => $va,
                ], 201);
            });

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during registration', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during registration', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
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
            // 1️⃣ Validate incoming request
            $request->validate([
                'phoneNumber' => 'required|string|max:20',
                'password'    => 'required|string|min:4|max:6', // PIN length
            ]);

            // 2️⃣ Fetch user by phone number
            $user = User::where('phoneNumber', $request->phoneNumber)->first();

            if (!$user) {
                \Log::warning('Login failed: user not found', [
                    'phoneNumber' => $request->phoneNumber,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'User not found.',
                ], 404);
            }

            // 3️⃣ Verify password
            if (!$user->password || !\Hash::check($request->password, $user->password)) {
                \Log::warning('Login failed: incorrect PIN', [
                    'phoneNumber'   => $request->phoneNumber,
                    'attempted_pin' => $request->password,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Invalid PIN.',
                ], 401);
            }

            // 4️⃣ Fetch virtual account using user's id
            $va = VirtualAccount::where('user_id', $user->id)->first();

            \Log::info('User logged in successfully', [
                'user_id' => $user->id,
                'phoneNumber' => $user->phoneNumber,
                'virtual_account_exists' => $va ? true : false,
            ]);

            // 5️⃣ Return user and virtual account separately
            return response()->json([
                'success' => true,
                'message' => 'Login successful.',
                'user' => $user,
                'virtualAccount' => $va, // can be null if not exists
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during login', [
                'errors' => $e->errors(),
                'input'  => $request->all(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during login', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
                'input'   => $request->all(),
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





    // Forgot password api
    public function forgotPassword(Request $request)
    {
        try {

            $request->validate([
                'email' => 'required|email'
            ]);

            $user = User::where('email', $request->email)->first();

            if (!$user) {
                Log::warning('Forgot password failed: User not found.', ['email' => $request->email]);

                return response()->json([
                    'success' => false,
                    'message' => 'No account found with this email.',
                ], 404);
            }

            // 🔑 Generate a new 6-digit numeric password
            $newPassword = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            Log::info('Generated new password.', ['email' => $user->email, 'newPassword' => $newPassword]);

            // 🔒 Hash it and update user
            $user->password = Hash::make($newPassword);
            $user->save();
            Log::info('Password updated in database.', ['user_id' => $user->id]);

            // 📧 Send email with new password
            Mail::to($user->email)->send(new ForgotPasswordMail($user, $newPassword));
            Log::info('Forgot password email sent.', ['email' => $user->email]);

            return response()->json([
                'success' => true,
                'message' => 'A new password has been sent to your email.',
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::error('Validation error in forgotPassword.', [
                'email' => $request->email,
                'errors' => $e->errors()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            Log::error('Exception in forgotPassword.', [
                'email' => $request->email ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Something went wrong. Please try again later.',
            ], 500);
        }
    }
}
