<?php

namespace App\Http\Controllers;

use App\Services\FlutterwaveService;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Support\Facades\Log;

class BillsController extends Controller
{
    protected $flutterwave;

    public function __construct(FlutterwaveService $flutterwave)
    {
        $this->flutterwave = $flutterwave;
    }

    // Returns everything
    public function billCategories()
    {
        try {
            $response = $this->flutterwave->getTopBillCategories();

            if (!isset($response['status']) || $response['status'] !== 'success') {
                \Log::error('Flutterwave returned error: ' . json_encode($response));
                return response()->json([
                    'status' => 'error',
                    'message' => $response['message'] ?? 'Unable to fetch categories at the moment'
                ], 500);
            }

            $data = $response['data'] ?? [];
            \Log::info($data);

            $grouped = [
                'airtime' => array_values(array_filter($data, fn($item) => isset($item['name']) && str_contains(strtoupper($item['name']), 'AIRTIME'))),
                'data' => array_values(array_filter($data, fn($item) => isset($item['name']) && str_contains(strtoupper($item['name']), 'DATA'))),
                'electricity' => array_values(array_filter($data, fn($item) => isset($item['name']) && str_contains(strtoupper($item['name']), 'ELECTRICITY'))),
                'cabletv' => array_values(array_filter($data, fn($item) => isset($item['name']) && (
                    str_contains(strtoupper($item['name']), 'DSTV') || 
                    str_contains(strtoupper($item['name']), 'GOTV') || 
                    str_contains(strtoupper($item['name']), 'STARTIMES')
                ))),
            ];

            \Log::info('Billers by Category Response: ' . json_encode($grouped));

            return response()->json(['status' => 'success', 'data' => $grouped]);

        } catch (\Exception $e) {
            \Log::error('Error fetching categories: ' . $e->getMessage());
            return response()->json(['error' => 'Service unavailable. Please try again later.'], 500);
        }
    }



    // Returns only the needed category
    public function billersByCategory(Request $request)
    {
        try {
            $category = strtolower($request->get('category', 'airtime')); // default to airtime
            $country = strtoupper($request->get('country', 'NG')); // default to NG

            // fetch everything once
            $response = $this->flutterwave->getBillCategories();
            $data = $response['data'] ?? [];

            // group by category
            $grouped = [
                'airtime' => array_values(array_filter($data, fn($item) => $item['is_airtime'] === true)),
                'data' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'DATA'))),
                'electricity' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'ELECTRICITY'))),
                'cabletv' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'DSTV') 
                    || str_contains(strtoupper($item['name']), 'GOTV') 
                    || str_contains(strtoupper($item['name']), 'STARTIMES'))),
            ];

            // return only requested category, or empty if not found
            $filtered = $grouped[$category] ?? [];

            // filter by country
            $filtered = array_values(array_filter($filtered, fn($item) => strtoupper($item['country']) === $country));

            // ✅ Remove duplicates by biller_code + item_code
            $unique = [];
            $filtered = array_values(array_filter($filtered, function($item) use (&$unique) {
                $key = $item['biller_code'] . '_' . $item['item_code'];
                if (isset($unique[$key])) return false;
                $unique[$key] = true;
                return true;
            }));

            \Log::info("Billers by Category [$category, Country: $country]: " . json_encode($filtered));

            return response()->json([
                'status' => 'success',
                'category' => $category,
                'country' => $country,
                'data' => $filtered
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching billers by category: ' . $e->getMessage());
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }






    // ✅ Get Mobile Networks
    public function mobileNetworks()
    {
        try {
            $response = $this->flutterwave->getMobileNetworks();
            \Log::info('Mobile Networks Response: ' . json_encode($response));
            return response()->json($response);
        } catch (\Exception $e) {
            \Log::error('Error fetching mobile networks: ' . $e->getMessage());
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // Buy airtime
    public function purchaseAirtime(Request $request)
    {
        try {
            $data = [
                "biller_code"  => $request->input('biller_code'),
                "item_code"    => $request->input('item_code'),
                "type"         => "AIRTIME",
                "country"      => $request->input('country', 'NG'),
                "customer_id"  => $request->phone,
                "amount"       => $request->amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            $billerCode = $request->input('biller_code');
            $itemCode   = $request->input('item_code');

            \Log::info('Airtime Purchase Request: ' . json_encode($data));

            if (!$billerCode || !$itemCode) {
                \Log::error('Biller code and item code are required');
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Biller code and item code are required'
                ], 400);
            }

            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Airtime Purchase Response: ' . json_encode($response));

            return response()->json($response);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            // Extract response body from Flutterwave error
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);

            // Get the "message" field, fallback to full exception message
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing airtime: ' . $errorMessage);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);
        } catch (\Exception $e) {
            // Fallback for any other exception
            \Log::error('Error purchasing airtime: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }



    // ✅ Purchase Data with proper error handling
    public function purchaseData(Request $request)
    {
        \Log::info('Display amount: ' . $request->amount);

        try {
            $data = [
                "biller_code"  => $request->input('biller_code'),
                "item_code"    => $request->input('item_code'),
                "type"         => "DATA",
                "country"      => $request->input('country', 'NG'),
                "customer_id"  => $request->phone,
                "amount"       => $request->amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            $billerCode = $request->input('biller_code');
            $itemCode   = $request->input('item_code');

            // Validate required fields
            if (!$billerCode || !$itemCode) {
                \Log::error('Biller code and item code are required for data purchase');
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Biller code and item code are required'
                ], 400);
            }

            \Log::info('Data Purchase Request: ' . json_encode($data));

            // Attempt to purchase data
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Data Purchase Response: ' . json_encode($response));

            return response()->json($response);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            // Extract response body from Flutterwave error
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);

            // Get the "message" field, fallback to full exception message
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing data: ' . $errorMessage);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);

        } catch (\Exception $e) {
            // Fallback for any other exception
            \Log::error('Error purchasing data: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }



    // ✅ Purchase Cable subscription with proper error handling
    public function purchaseCable(Request $request)
    {
        \Log::info('CableTV Purchase Amount: ' . $request->amount);

        try {
            $data = [
                "biller_code"  => $request->input('biller_code'),
                "item_code"    => $request->input('item_code'),
                "type"         => "CABLE",
                "country"      => $request->input('country', 'NG'),
                "customer_id"  => $request->smartcard, // SmartCard Number
                "amount"       => $request->amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            $billerCode = $request->input('biller_code');
            $itemCode   = $request->input('item_code');
            $smartCard  = $request->input('smartcard');

            // Validate required fields
            if (!$billerCode || !$itemCode || !$smartCard) {
                \Log::error('Biller code, item code, and SmartCard number are required for cable purchase');
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Biller code, item code, and SmartCard number are required'
                ], 400);
            }

            \Log::info('Cable Purchase Request: ' . json_encode($data));

            // Attempt to purchase cable subscription via Flutterwave
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Cable Purchase Response: ' . json_encode($response));

            return response()->json($response);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();
            \Log::error('Error purchasing cable: ' . $errorMessage);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);

        } catch (\Exception $e) {
            \Log::error('Error purchasing cable: ' . $e->getMessage());

            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }




    // ✅ Purchase Electricity subscription with proper error handling
    public function purchaseElectricity(Request $request)
    {
        \Log::info('Electricity Purchase Amount: ' . $request->amount);

        try {
            $data = [
                "biller_code"  => $request->input('biller_code'),
                "item_code"    => $request->input('item_code'),
                "type"         => "ELECTRICITY",
                "country"      => $request->input('country', 'NG'),
                "customer_id"  => $request->meter_number, // Meter Number
                // "amount"       => $request->amount,
                "amount"       => 3500,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            $billerCode = $request->input('biller_code');
            $itemCode   = $request->input('item_code');
            $meter      = $request->input('meter_number');
            \Log::info('Electricity Purchase Request: ' . json_encode($data));

            // Validate required fields
            if (!$billerCode || !$itemCode || !$meter) {
                \Log::error('Biller code, item code, and Meter number are required for electricity purchase');
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Biller code, item code, and Meter number are required'
                ], 400);
            }

            \Log::info('Electricity Purchase Request: ' . json_encode($data));

            // Attempt to purchase electricity via Flutterwave
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Electricity Purchase Response: ' . json_encode($response));

            return response()->json($response);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();
            \Log::error('Error purchasing electricity: ' . $errorMessage);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);

        } catch (\Exception $e) {
            \Log::error('Error purchasing electricity: ' . $e->getMessage());

            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }




    // ================= BANKS =================

    public function getBanks(Request $request)
    {
        try {
            $country = $request->get('country', 'NG');
            Log::info("Fetching banks for country", ['country' => $country]);

            $response = $this->flutterwave->getBanks($country);

            Log::info("Banks retrieved", ['country' => $country, 'count' => count($response['data'] ?? [])]);
            Log::debug("Banks data", ['data' => $response]);

            return response()->json([
                'success' => true,
                'message' => 'Banks retrieved successfully',
                'data'    => $response
            ]);
        } catch (\Exception $e) {
            Log::error("Get banks error", [
                'error'   => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Unable to fetch banks at this time. Please try again later.'
            ], 500);
        }
    }



    // ================= RESOLVE ACCOUNT =================
    
    public function resolveAccountName(Request $request)
    {
        $request->validate([
            'account_number' => 'required|string',
            'bank_code'      => 'required|string',
        ]);

        try {
            $response = $this->flutterwave->resolveAccountName($request->account_number, $request->bank_code);

            if (isset($response['status']) && $response['status'] === 'success') {
                \Log::info("Fetching account details", ['account_number' => $request->account_number, 'bank_code' => $request->bank_code]);
                return response()->json([
                    'status'  => 'success',
                    'message' => $response['message'],
                    'data'    => [
                        'account_number' => $response['data']['account_number'],
                        'account_name'   => $response['data']['account_name'],
                    ]
                ]);
            }

            \Log::error("Account resolve failed", [
                'account_number' => $request->account_number,
                'bank_code'      => $request->bank_code,
                'response'      => $response,
            ]);

            return response()->json([
                'status'  => 'error',
                'message' => $response['message'] ?? 'Unable to resolve account',
            ], 400);

        } catch (\Exception $e) {
            \Log::error("Account resolve error", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status'  => 'error',
                'message' => 'Something went wrong while fetching account name, please try again later.',
            ], 500);
        }
    }



    // ================= TRANSFERS / PAYMENTS =================
    public function transfer(Request $request)
    {
        $request->validate([
            'account_bank'        => 'nullable|string',
            'account_number'      => 'required|string',
            'amount'              => 'required|numeric|min:1',
            'currency'            => 'required|string',
            'description'         => 'nullable|string',
            'country'             => 'nullable|string',
            'swift_code'          => 'nullable|string',
            'beneficiary_name'    => 'nullable|string',
            'beneficiary_address' => 'nullable|string',
            'beneficiary_city'    => 'nullable|string',
        ]);

        try {
            $payload = [
                'account_bank'   => $request->account_bank,
                'account_number' => $request->account_number,
                'amount'         => $request->amount,
                'currency'       => $request->currency,
                'description'    => $request->description ?? 'Money Transfer',
                'reference'      => uniqid("tx_"),
            ];

            // Attach international fields if provided
            if ($request->filled('country')) $payload['country'] = $request->country;
            if ($request->filled('swift_code')) $payload['swift_code'] = $request->swift_code;
            if ($request->filled('beneficiary_name')) $payload['beneficiary_name'] = $request->beneficiary_name;
            if ($request->filled('beneficiary_address')) $payload['beneficiary_address'] = $request->beneficiary_address;
            if ($request->filled('beneficiary_city')) $payload['beneficiary_city'] = $request->beneficiary_city;

            // ✅ Add meta if it's international
            if ($request->filled('country')) {
                $payload['meta'] = [[
                    "sender"           => "Transact Point",
                    "sender_country"   => "NG",
                    "receiver_country" => $request->country,
                    "purpose"          => $request->description ?? "Transfer"
                ]];
            }

            Log::info("Initiating transfer", ['payload' => $payload]);

            $response = $this->flutterwave->transfer($payload);

            Log::info("Transfer response", ['response' => $response]);

            return response()->json([
                'success' => true,
                'message' => $response['message'] ?? 'Transfer initiated successfully',
                'data'    => $response
            ]);
        } catch (\Exception $e) {
            Log::error("Transfer error", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Unable to initiate transfer at this time. Please try again later.'
            ], 500);
        }
    }



    // ================= CURRENCY CONVERSION =================
    public function convert(Request $request)
    {
        $request->validate([
            'amount'        => 'required|numeric|min:1',
            'from_currency' => 'required|string',
            'to_currency'   => 'required|string',
        ]);

        try {
            \Log::info("Conversion request", ['request' => $request->all()]);

            $response = $this->flutterwave->convert($request->amount, $request->from_currency, $request->to_currency);
            \Log::info("Conversion response", ['response' => $response]);

            if ($response['status'] === 'success') {
                $rate = (float) $response['data']['rate'];
                $converted = $rate * (float) $request->amount;
                \Log::info("Conversion successful", [
                    'from_currency' => $request->from_currency,
                    'to_currency'   => $request->to_currency,
                    'amount'        => $request->amount,
                    'rate'          => $rate,
                    'converted'     => $converted
                ]);

                return response()->json([
                    'success'           => true,
                    'rate'              => $rate,
                    'converted_amount'  => $converted,
                    'data'              => $response
                ]);
            }

            \Log::error("Conversion failed", ['response' => $response]);
            return response()->json(['success' => false, 'message' => $response['message']], 400);
        } catch (\Exception $e) {
            \Log::error("Conversion error", ['error' => $e]);
            return response()->json(['success' => false, 'message' => 'Conversion failed'], 500);
        }
    }



    // Fund my account
    public function fundAccount(Request $request)
    {
        $amount       = $request->input('amount');
        $currency     = $request->input('currency');
        $email        = $request->input('email');
        $id           = $request->input('id'); // user_id
        $redirectUrl  = $request->input('redirect_url');

        $code         = $request->input('code');
        $currencySign = $request->input('currencySign');
        $country      = $request->input('country');

        try {
            $tx_ref = uniqid('fund_');

            // 🔹 Save pending transaction in DB
            $transaction = Transaction::create([
                'user_id'       => $id,
                'type'          => 'funding',
                'amount'        => $amount,
                'description'   => 'Wallet funding initiated',
                'status'        => 'pending',
                'currency'      => $currency,
                'transaction_id'=> $tx_ref,
                'code'          => $code,
                'currencySign'  => $currencySign,
                'country'       => $country,
            ]);

            $payload = [
                'tx_ref'          => $tx_ref,
                'amount'          => $amount,
                'currency'        => $currency,
                'redirect_url'    => $redirectUrl,
                'payment_options' => 'card,account,ussd,banktransfer',
                'customer'        => [
                    'email' => $email,
                    'id'    => $id,
                    'name'  => 'Test Customer',
                ],
                'customizations'  => [
                    'title'       => 'Transact Point Wallet Funding',
                    'description' => 'Fund your account',
                    'logo'        => env('APP_LOGO_URL', ''),
                ],
            ];

            $response = $this->flutterwave->fundAccount($payload);
            \Log::info('Fund account API response received', ['response' => $response]);

            return $response;

        } catch (\Exception $e) {
            \Log::error('Error funding account', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);

            return [
                'status'  => 'error',
                'message' => 'Unable to initiate funding request',
            ];
        }
    }







    // Handle Flutterwave webhook
    public function flutterwaveWebhook(Request $request)
    {
        try {
            $secretHash = env('FLW_SECRET_HASH');
            $signature  = $request->header('Verif-Hash');

            if (!$signature || $signature !== $secretHash) {
                Log::warning("Invalid webhook signature", ['signature' => $signature]);
                return response()->json(['error' => 'Invalid signature'], 401);
            }

            $payload = $request->all();
            Log::info("Flutterwave Webhook Payload", $payload);

            if (!isset($payload['event']) || $payload['event'] !== 'charge.completed') {
                return response()->json(['message' => 'Event not handled'], 200);
            }

            $data   = $payload['data'];
            $tx_ref = $data['tx_ref'];

            // 🔹 Find our stored transaction
            $transaction = Transaction::where('transaction_id', $tx_ref)->first();
            if (!$transaction) {
                Log::error("Transaction not found", ['tx_ref' => $tx_ref]);
                return response()->json(['error' => 'Transaction not found'], 200);
            }

            $user = User::find($transaction->user_id);
            if (!$user) {
                Log::error("User not found", ['id' => $transaction->user_id]);
                return response()->json(['error' => 'User not found'], 200);
            }

            // 🔹 Update transaction
            $transaction->update([
                'status'      => $data['status'],
                'description' => $data['narration'] ?? 'Wallet Funding',
            ]);

            if ($data['status'] === 'successful') {
                $wallet = Wallet::firstOrCreate(
                    ['user_id' => $user->id],
                    [
                        'balance'       => 0,
                        'currency'      => $transaction->currency,
                        'code'          => $transaction->code,
                        'currencySign'  => $transaction->currencySign,
                        'country'       => $transaction->country,
                    ]
                );

                $wallet->increment('balance', $data['amount']);

                Log::info("Wallet funded successfully", [
                    'user_id'        => $user->id,
                    'amount'         => $data['amount'],
                    'wallet_balance' => $wallet->balance,
                    'transaction_id' => $tx_ref,
                ]);
            }

            return response()->json(['status' => 'success'], 200);

        } catch (\Exception $e) {
            Log::error("Webhook error", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json(['error' => 'Server error'], 500);
        }
    }








}
