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
            // 🔹 Validate inputs
            $request->validate([
                'id'          => 'required|integer|exists:users,id',
                'biller_code' => 'required|string',
                'item_code'   => 'required|string',
                'phone'       => 'required|string',
                'amount'      => 'required|numeric|min:1',
                'country'     => 'required|string|max:5',
            ]);

            $userId   = $request->id;
            $amount   = $request->amount;
            $country  = $request->country;
            $billerCode = $request->biller_code;
            $itemCode   = $request->item_code;

            // 🔹 Get Wallet
            $wallet = Wallet::where('user_id', $userId)->first();
            if (!$wallet) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Wallet not found.'
                ], 404);
            }

            // 🔹 Check balance
            if ($wallet->balance < $amount) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Insufficient account balance.'
                ], 400);
            }

            // 🔹 Check if Nigerian wallet
            if ($wallet->code !== $country) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Airtime purchase is only for Nigerians.'
                ], 400);
            }

            // 🔹 Prepare payload for Flutterwave
            $data = [
                'id'           => $userId,
                "biller_code"  => $billerCode,
                "item_code"    => $itemCode,
                "type"         => "AIRTIME",
                "country"      => $country,
                "customer_id"  => $request->phone,
                "amount"       => $amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            \Log::info('Airtime Purchase Request: ' . json_encode($data));

            // 🔹 Call Flutterwave API
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Airtime Purchase Response: ' . json_encode($response));

            // 🔹 If success, deduct wallet & log transaction
            if (isset($response['status']) && $response['status'] === 'success') {
                // Deduct wallet balance
                $wallet->balance -= $amount;
                $wallet->save();

                // Save transaction
                Transaction::create([
                    'user_id'       => $userId,
                    'type'          => 'Bill Payment',
                    'amount'        => $amount,
                    'description'   => 'Airtime Purchase',
                    'biller_code'   => $billerCode,
                    'item_code'     => $itemCode,
                    'status'        => 'Successful',
                    'currency'      => $wallet->currency,
                    'transaction_id'=> $data['reference'],
                    'code'          => $wallet->code,
                    'currencySign'  => $wallet->currencySign,
                    'country'       => $wallet->country,
                ]);
            }

            return response()->json($response);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Validation failed',
                'errors'  => $e->errors()
            ], 422);
        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing airtime: ' . $e);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);
        } catch (\Exception $e) {
            \Log::error('Error purchasing airtime: ' . $e);
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }




    // ✅ Purchase Data with proper error handling
    public function purchaseData(Request $request)
    {
        try {
            // 🔹 Validate inputs
            $request->validate([
                'id'          => 'required|integer|exists:users,id',
                'biller_code' => 'required|string',
                'item_code'   => 'required|string',
                'phone'       => 'required|string',
                'amount'      => 'required|numeric|min:1',
                'country'     => 'required|string|max:5',
            ]);

            $userId     = $request->id;
            $amount     = $request->amount;
            $country    = $request->country;
            $billerCode = $request->biller_code;
            $itemCode   = $request->item_code;

            // 🔹 Get Wallet
            $wallet = Wallet::where('user_id', $userId)->first();
            if (!$wallet) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Wallet not found for this user.'
                ], 404);
            }

            // 🔹 Check balance
            if ($wallet->balance < $amount) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Insufficient wallet balance.'
                ], 400);
            }

            // 🔹 Check if Nigerian wallet
            if ($wallet->code !== $country) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Data purchase only for Nigerians.'
                ], 400);
            }

            // 🔹 Prepare payload for Flutterwave
            $data = [
                'id'           => $userId,
                "biller_code"  => $billerCode,
                "item_code"    => $itemCode,
                "type"         => "DATA",
                "country"      => $country,
                "customer_id"  => $request->phone,
                "amount"       => $amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            \Log::info('Data Purchase Request: ' . json_encode($data));

            // 🔹 Call Flutterwave API
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Data Purchase Response: ' . json_encode($response));

            // 🔹 If success, deduct wallet & log transaction
            if (isset($response['status']) && $response['status'] === 'success') {
                // Deduct wallet balance
                $wallet->balance -= $amount;
                $wallet->save();

                // Save transaction
                Transaction::create([
                    'user_id'       => $userId,
                    'type'          => 'Bill Payment',
                    'amount'        => $amount,
                    'description'   => 'Data Purchase',
                    'biller_code'   => $billerCode,
                    'item_code'     => $itemCode,
                    'status'        => 'Successful',
                    'currency'      => $wallet->currency,
                    'transaction_id'=> $data['reference'],
                    'code'          => $wallet->code,
                    'currencySign'  => $wallet->currencySign,
                    'country'       => $wallet->country,
                ]);
            }

            return response()->json($response);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Validation failed',
                'errors'  => $e->errors()
            ], 422);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing data: ' . $e);

            return response()->json([
                'status'  => 'error',
                'message' => $errorMessage
            ], 500);

        } catch (\Exception $e) {
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
        try {
            // 🔹 Validate inputs
            $request->validate([
                'id'          => 'required|integer|exists:users,id',
                'biller_code' => 'required|string',
                'item_code'   => 'required|string',
                'smartcard'   => 'required|string',
                'amount'      => 'required|numeric|min:1',
                'country'     => 'required|string|max:5',
            ]);

            $userId     = $request->id;
            $amount     = $request->amount;
            $country    = $request->country;
            $billerCode = $request->biller_code;
            $itemCode   = $request->item_code;
            $smartCard  = $request->smartcard;

            // 🔹 Get Wallet
            $wallet = Wallet::where('user_id', $userId)->first();
            if (!$wallet) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Wallet not found for this user.'
                ], 404);
            }

            // 🔹 Check balance
            if ($wallet->balance < $amount) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Insufficient wallet balance.'
                ], 400);
            }

            // 🔹 Check if Nigerian wallet
            if ($wallet->code !== $country) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Cable purchase only for Nigerians.'
                ], 400);
            }

            // 🔹 Prepare payload for Flutterwave
            $data = [
                'id'           => $userId,
                "biller_code"  => $billerCode,
                "item_code"    => $itemCode,
                "type"         => "CABLE",
                "country"      => $country,
                "customer_id"  => $smartCard, // SmartCard number
                "amount"       => $amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            \Log::info('Cable Purchase Request: ' . json_encode($data));

            // 🔹 Call Flutterwave API
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Cable Purchase Response: ' . json_encode($response));

            // 🔹 If success, deduct wallet & log transaction
            if (isset($response['status']) && $response['status'] === 'success') {
                // Deduct wallet balance
                $wallet->balance -= $amount;
                $wallet->save();

                // Save transaction
                Transaction::create([
                    'user_id'        => $userId,
                    'type'           => 'Bill Payment',
                    'amount'         => $amount,
                    'description'    => 'Cable Subscription',
                    'biller_code'    => $billerCode,
                    'item_code'      => $itemCode,
                    'status'         => 'Successful',
                    'currency'       => $wallet->currency,
                    'transaction_id' => $data['reference'],
                    'code'           => $wallet->code,
                    'currencySign'   => $wallet->currencySign,
                    'country'        => $wallet->country,
                ]);
            }

            return response()->json($response);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Validation failed',
                'errors'  => $e->errors()
            ], 422);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing cable: ' . $e);

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
        \Log::info('Electricity Purchase Request: ' . json_encode($request->all()));

        try {
            // 🔹 Validate inputs
            $request->validate([
                'id'           => 'required|integer|exists:users,id',
                'biller_code'  => 'required|string',
                'item_code'    => 'required|string',
                'meter_number' => 'required|string',
                'amount' => 'required|numeric|min:0',
                'country'      => 'required|string|max:5',
            ]);

            $userId     = $request->id;
            $amount     = $request->amount;
            $country    = $request->country;
            $billerCode = $request->biller_code;
            $itemCode   = $request->item_code;
            $meter      = $request->meter_number;

            // 🔹 Get Wallet
            $wallet = Wallet::where('user_id', $userId)->first();
            if (!$wallet) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Wallet not found for this user.'
                ], 404);
            }

            // 🔹 Check balance
            if ($wallet->balance < $amount) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Insufficient wallet balance.'
                ], 400);
            }

            // 🔹 Check if Nigerian wallet
            if ($wallet->code !== $country) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Electricity purchase only for Nigerians.'
                ], 400);
            }

            // 🔹 Prepare payload for Flutterwave
            $data = [
                'id'           => $userId,
                "biller_code"  => $billerCode,
                "item_code"    => $itemCode,
                "type"         => "ELECTRICITY",
                "country"      => $country,
                "customer_id"  => $meter,
                "amount"       => $amount,
                "reference"    => "txn_" . uniqid(),
                "callback_url" => "https://yourdomain.com/webhook"
            ];

            \Log::info('Electricity Purchase Request: ' . json_encode($data));

            // 🔹 Call Flutterwave API
            $response = $this->flutterwave->purchaseBill($billerCode, $itemCode, $data);

            \Log::info('Electricity Purchase Response: ' . json_encode($response));

            // 🔹 If success, deduct wallet & log transaction
            if (isset($response['status']) && $response['status'] === 'success') {
                // Deduct wallet balance
                $wallet->balance -= $amount;
                $wallet->save();

                // Save transaction
                Transaction::create([
                    'user_id'       => $userId,
                    'type'          => 'Bill Payment',
                    'amount'        => $amount,
                    'description'   => 'Electricity Purchase',
                    'biller_code'   => $billerCode,
                    'item_code'     => $itemCode,
                    'status'        => 'Successful',
                    'currency'      => $wallet->currency,
                    'transaction_id'=> $data['reference'],
                    'code'          => $wallet->code,
                    'currencySign'  => $wallet->currencySign,
                    'country'       => $wallet->country,
                ]);
            }

            return response()->json($response);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Validation failed',
                'errors'  => $e->errors()
            ], 422);

        } catch (\GuzzleHttp\Exception\ClientException $e) {
            $body = $e->getResponse()->getBody()->getContents();
            $decoded = json_decode($body, true);
            $errorMessage = $decoded['message'] ?? $e->getMessage();

            \Log::error('Error purchasing electricity: ' . $e);

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
                    'name'  => 'Customer',
                ],
                'customizations'  => [
                    'title'       => 'Transact Point Account Funding',
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



    protected $countryList = [
        ["code"=>"NG","country"=>"Nigeria","currency"=>"NGN","currency_sign"=>"₦"],
        ["code"=>"GH","country"=>"Ghana","currency"=>"GHS","currency_sign"=>"₵"],
        ["code"=>"KE","country"=>"Kenya","currency"=>"KES","currency_sign"=>"KSh"],
        ["code"=>"UG","country"=>"Uganda","currency"=>"UGX","currency_sign"=>"USh"],
        ["code"=>"TZ","country"=>"Tanzania","currency"=>"TZS","currency_sign"=>"TSh"],
        ["code"=>"MW","country"=>"Malawi","currency"=>"MWK","currency_sign"=>"MK"],
        ["code"=>"RW","country"=>"Rwanda","currency"=>"RWF","currency_sign"=>"R₣"],
        ["code"=>"SL","country"=>"Sierra Leone","currency"=>"SLL","currency_sign"=>"Le"],
        ["code"=>"ZM","country"=>"Zambia","currency"=>"ZMW","currency_sign"=>"ZK"],
        ["code"=>"SN","country"=>"Senegal","currency"=>"XOF","currency_sign"=>"CFA"],
        ["code"=>"CI","country"=>"Côte d'Ivoire","currency"=>"XOF","currency_sign"=>"CFA"],
        ["code"=>"CM","country"=>"Cameroon","currency"=>"XAF","currency_sign"=>"FCFA"],
        ["code"=>"BF","country"=>"Burkina Faso","currency"=>"XOF","currency_sign"=>"CFA"],
        ["code"=>"ET","country"=>"Ethiopia","currency"=>"ETB","currency_sign"=>"Br"],
        ["code"=>"EG","country"=>"Egypt","currency"=>"EGP","currency_sign"=>"£E"],
        ["code"=>"ZA","country"=>"South Africa","currency"=>"ZAR","currency_sign"=>"R"],
        ["code"=>"INT_USD","country"=>"International","currency"=>"USD","currency_sign"=>"$"],
        ["code"=>"INT_EUR","country"=>"International","currency"=>"EUR","currency_sign"=>"€"],
        ["code"=>"INT_GBP","country"=>"International","currency"=>"GBP","currency_sign"=>"£"],
    ];


    // Get currency sign
    protected function getCurrencySign($currency)
    {
        foreach ($this->countryList as $country) {
            if ($country['currency'] === strtoupper($currency)) {
                return $country['currency_sign'];
            }
        }

        return $currency;
    }



    // Create a virtual account
    public function createVirtualAccount(Request $request)
    {
        // Validate request
        $request->validate([
            'currency_code' => 'required|string',
            'account_name'  => 'required|string',
            'email'         => 'required|email',
            'firstname'     => 'required|string',
            'lastname'      => 'required|string',
            'phonenumber'   => 'required|string',
            'bvn'           => 'nullable|string',
            'user_id'       => 'nullable|integer', // optional, in case account is for another user
        ]);

        $currency = strtoupper($request->currency_code);
        \Log::info("Creating virtual account", [
            'user_id' => $request->user_id ?? auth()->id(),
            'currency' => $currency,
            'email' => $request->email
        ]);

        try {
            $vaData = [];

            if ($currency === 'NGN') {
                \Log::info("Creating NGN V3 virtual account for {$request->email}");
                
                $vaData = $this->flutterwave->createStaticVirtualAccount([
                    'email'       => $request->email,
                    'va_ref'      => 'VA-' . Str::random(6),
                    'firstname'   => $request->firstname,
                    'lastname'    => $request->lastname,
                    'phonenumber' => $request->phonenumber,
                    'narration'   => 'Virtual Account for ' . $request->account_name,
                    'bvn'         => $request->bvn ?? null,
                ]);

                \Log::info("NGN V3 virtual account created", ['vaData' => $vaData]);

            } else {
                \Log::info("Creating international V4 virtual account for {$request->email} in currency: {$currency}");
                
                $vaData = $this->flutterwaveV4->createVirtualAccountForForeignAccounts([
                    'account_name' => $request->account_name,
                    'currency'     => $currency,
                    'email'        => $request->email,
                ]);

                \Log::info("V4 virtual account created", ['vaData' => $vaData]);
            }

            $va = VirtualAccount::create([
                'user_id'        => $request->user_id ?? auth()->id(),
                'account_number' => $vaData['account_number'] ?? $vaData['id'],
                'account_name'   => $vaData['account_name'] ?? $request->account_name,
                'bank_name'      => $vaData['bank_name'] ?? 'Flutterwave',
                'bank_code'      => $vaData['bank_code'] ?? null,
                'currency'       => $currency,
                'currency_sign'  => $this->getCurrencySign($currency),
                'country'        => $currency === 'NGN' ? 'Nigeria' : $currency,
                'va_ref'         => $vaData['va_ref'] ?? null,
                'flw_ref'        => $vaData['id'] ?? null,
                'meta'           => $vaData,
            ]);

            \Log::info("Virtual account saved to database", ['virtual_account_id' => $va->id]);

            return response()->json([
                'account_name'   => $va->account_name,
                'account_number' => $va->account_number,
                'bank_name'      => $va->bank_name,
                'country'        => $va->country,
                'currency_sign'  => $va->currency_sign,
            ]);

        } catch (\Exception $e) {
            \Log::error("Error creating virtual account", [
                'error' => $e->getMessage(),
                'currency' => $currency,
                'email' => $request->email
            ]);

            return response()->json(['error' => $e->getMessage()], 500);
        }
    }









    // Handle Flutterwave webhook
    // public function flutterwaveWebhook(Request $request)
    // {
    //     try {
    //         $secretHash = env('FLW_SECRET_HASH');
    //         $signature  = $request->header('Verif-Hash');

    //         if (!$signature || $signature !== $secretHash) {
    //             Log::warning("Invalid webhook signature", ['signature' => $signature]);
    //             return response()->json(['error' => 'Invalid signature'], 401);
    //         }

    //         $payload = $request->all();
    //         Log::info("Flutterwave Webhook Payload", $payload);

    //         if (!isset($payload['event'])) {
    //             return response()->json(['message' => 'No event found'], 200);
    //         }

    //         $event = $payload['event'];
    //         $data  = $payload['data'];

    //         if ($event === 'charge.completed') {
    //             // CASE 1: Checkout Funding (has tx_ref)
    //             if (isset($data['tx_ref'])) {
    //                 $tx_ref = $data['tx_ref'];

    //                 $transaction = Transaction::where('transaction_id', $tx_ref)->first();
    //                 if (!$transaction) {
    //                     Log::error("Transaction not found", ['tx_ref' => $tx_ref]);
    //                     return response()->json(['error' => 'Transaction not found'], 200);
    //                 }

    //                 $user = User::find($transaction->user_id);
    //                 if (!$user) {
    //                     Log::error("User not found", ['id' => $transaction->user_id]);
    //                     return response()->json(['error' => 'User not found'], 200);
    //                 }

    //                 $transaction->update([
    //                     'status'      => $data['status'],
    //                     'description' => $data['narration'] ?? 'Wallet Funding',
    //                 ]);

    //                 if ($data['status'] === 'successful') {
    //                     $wallet = Wallet::firstOrCreate(
    //                         ['user_id' => $user->id],
    //                         [
    //                             'balance'       => 0,
    //                             'currency'      => $transaction->currency,
    //                             'code'          => $transaction->code,
    //                             'currencySign'  => $transaction->currencySign,
    //                             'country'       => $transaction->country,
    //                         ]
    //                     );

    //                     $wallet->increment('balance', $data['amount']);

    //                     Log::info("Wallet funded successfully (Checkout)", [
    //                         'user_id'        => $user->id,
    //                         'amount'         => $data['amount'],
    //                         'wallet_balance' => $wallet->balance,
    //                         'transaction_id' => $transaction->transaction_id,
    //                     ]);
    //                 }
    //             }

    //             // CASE 2: Virtual Account Funding (no tx_ref, use flw_ref)
    //             elseif (isset($data['flw_ref'])) {
    //                 $flwRef = $data['flw_ref'];

    //                 $virtualAccount = VirtualAccount::where('flw_ref', $flwRef)->first();
    //                 if (!$virtualAccount) {
    //                     Log::error("Virtual account not found for funding", ['flw_ref' => $flwRef]);
    //                     return response()->json(['error' => 'Virtual account not found'], 200);
    //                 }

    //                 $user = $virtualAccount->user;
    //                 if (!$user) {
    //                     Log::error("User not found for virtual account", ['flw_ref' => $flwRef]);
    //                     return response()->json(['error' => 'User not found'], 200);
    //                 }

    //                 // Check if this transaction already exists (avoid duplicate funding if webhook retries)
    //                 $existingTx = Transaction::where('transaction_id', $data['id'])->first();
    //                 if ($existingTx) {
    //                     Log::warning("Duplicate transaction ignored", ['id' => $data['id']]);
    //                     return response()->json(['message' => 'Duplicate transaction'], 200);
    //                 }

    //                 // Create a new transaction
    //                 $transaction = Transaction::create([
    //                     'user_id'       => $user->id,
    //                     'type'          => 'credit',
    //                     'amount'        => $data['amount'],
    //                     'description'   => $data['narration'] ?? 'Virtual Account Funding',
    //                     'status'        => $data['status'],
    //                     'currency'      => $data['currency'],
    //                     'transaction_id'=> $data['id'], // Flutterwave transaction id
    //                     'code'          => $data['reference'] ?? null,
    //                     'currencySign'  => $data['currency'] ?? null,
    //                     'country'       => $data['country'] ?? null,
    //                 ]);

    //                 if ($data['status'] === 'successful') {
    //                     $wallet = Wallet::firstOrCreate(
    //                         ['user_id' => $user->id],
    //                         [
    //                             'balance'       => 0,
    //                             'currency'      => $transaction->currency,
    //                             'code'          => $transaction->code,
    //                             'currencySign'  => $transaction->currencySign,
    //                             'country'       => $transaction->country,
    //                         ]
    //                     );

    //                     $wallet->increment('balance', $data['amount']);

    //                     Log::info("Wallet funded successfully (Virtual Account)", [
    //                         'user_id'        => $user->id,
    //                         'amount'         => $data['amount'],
    //                         'wallet_balance' => $wallet->balance,
    //                         'transaction_id' => $transaction->transaction_id,
    //                     ]);
    //                 }
    //             }

    //         }

    //         return response()->json(['status' => 'success'], 200);

    //     } catch (\Exception $e) {
    //         Log::error("Webhook error", [
    //             'error' => $e->getMessage(),
    //             'trace' => $e->getTraceAsString()
    //         ]);
    //         return response()->json(['error' => 'Server error'], 500);
    //     }
    // }



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

            if (!isset($payload['event'])) {
                return response()->json(['message' => 'No event found'], 200);
            }

            $event = $payload['event'];
            $data  = $payload['data'];

            if ($event === 'charge.completed') {
                \DB::transaction(function () use ($data) {

                    // CASE 1: Checkout Funding (tx_ref exists)
                    if (isset($data['tx_ref'])) {
                        $tx_ref = $data['tx_ref'];

                        $transaction = Transaction::where('transaction_id', $tx_ref)->first();
                        if (!$transaction) {
                            Log::error("Transaction not found", ['tx_ref' => $tx_ref]);
                            return;
                        }

                        $user = User::find($transaction->user_id);
                        if (!$user) {
                            Log::error("User not found", ['id' => $transaction->user_id]);
                            return;
                        }

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

                            Log::info("Wallet funded successfully (Checkout)", [
                                'user_id'        => $user->id,
                                'amount'         => $data['amount'],
                                'wallet_balance' => $wallet->balance,
                                'transaction_id' => $transaction->transaction_id,
                            ]);
                        }
                    }

                    // CASE 2: Virtual Account Funding (use flw_ref)
                    elseif (isset($data['flw_ref'])) {
                        $flwRef = $data['flw_ref'];

                        $virtualAccount = VirtualAccount::where('flw_ref', $flwRef)->first();
                        if (!$virtualAccount) {
                            Log::error("Virtual account not found", ['flw_ref' => $flwRef]);
                            return;
                        }

                        $user = $virtualAccount->user;
                        if (!$user) {
                            Log::error("User not found for virtual account", ['flw_ref' => $flwRef]);
                            return;
                        }

                        // Avoid duplicate transaction
                        $existingTx = Transaction::where('transaction_id', $data['id'])->first();
                        if ($existingTx) {
                            Log::warning("Duplicate transaction ignored", ['id' => $data['id']]);
                            return;
                        }

                        // Create new transaction
                        $transaction = Transaction::create([
                            'user_id'       => $user->id,
                            'type'          => 'credit',
                            'amount'        => $data['amount'],
                            'description'   => $data['narration'] ?? 'Virtual Account Funding',
                            'status'        => $data['status'],
                            'currency'      => $data['currency'],
                            'transaction_id'=> $data['id'],
                            'code'          => $data['reference'] ?? null,
                            'currencySign'  => $data['currency'] ?? null,
                            'country'       => $data['country'] ?? null,
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

                            Log::info("Wallet funded successfully (Virtual Account)", [
                                'user_id'        => $user->id,
                                'amount'         => $data['amount'],
                                'wallet_balance' => $wallet->balance,
                                'transaction_id' => $transaction->transaction_id,
                            ]);
                        }
                    }

                }); // End transaction
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
