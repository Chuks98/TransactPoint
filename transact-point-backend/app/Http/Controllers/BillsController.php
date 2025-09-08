<?php

namespace App\Http\Controllers;

use App\Services\FlutterwaveService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BillsController extends Controller
{
    protected $flutterwave;

    public function __construct(FlutterwaveService $flutterwave)
    {
        $this->flutterwave = $flutterwave;
    }


    // ✅ Get Billers
    public function billers(Request $request)
    {
        try {
            $country = $request->get('country'); // optional
            $response = $this->flutterwave->getBillers($country);

            \Log::info('Billers Response: ' . json_encode($response));
            return response()->json($response);
        } catch (\Exception $e) {
            \Log::error('Error fetching billers: ' . $e->getMessage());
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }


    public function billerItems($billerCode)
    {
        try {
            $response = $this->flutterwave->getBillerItems($billerCode);
            return response()->json($response);
        } catch (\Exception $e) {
            \Log::error('Error fetching biller items: ' . $e->getMessage());
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }



    // Returns everything
    public function billCategories()
    {
        try {
            $response = $this->flutterwave->getBillCategories();

            if (!isset($response['status']) || $response['status'] !== 'success') {
                \Log::error('Flutterwave returned error: ' . json_encode($response));
                return response()->json([
                    'status' => 'error',
                    'message' => $response['message'] ?? 'Unable to fetch categories at the moment'
                ], 500);
            }

            $data = $response['data'] ?? [];

            $grouped = [
                'airtime' => array_values(array_filter($data, fn($item) => $item['is_airtime'] === true)),
                'data' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'DATA'))),
                'electricity' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'ELECTRICITY'))),
                'cabletv' => array_values(array_filter($data, fn($item) => str_contains(strtoupper($item['name']), 'DSTV') || str_contains(strtoupper($item['name']), 'GOTV') || str_contains(strtoupper($item['name']), 'STARTIMES'))),
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


    // ================= TRANSFERS / PAYMENTS =================
    public function transfer(Request $request)
    {
        $request->validate([
            'account_bank'       => 'required|string',
            'account_number'     => 'required|string',
            'amount'             => 'required|numeric|min:1',
            'currency'           => 'required|string',
            'narration'          => 'nullable|string',
            'country'            => 'nullable|string',
            'swift_code'         => 'nullable|string',
            'beneficiary_name'   => 'nullable|string',
            'beneficiary_address'=> 'nullable|string',
            'beneficiary_city'   => 'nullable|string',
        ]);

        try {
            $payload = [
                'account_bank'   => $request->account_bank,
                'account_number' => $request->account_number,
                'amount'         => $request->amount,
                'currency'       => $request->currency,
                'narration'      => $request->narration ?? 'Wallet Transfer',
                'reference'      => uniqid("tx_"),
            ];

            // Attach international fields if provided
            if ($request->filled('country')) $payload['country'] = $request->country;
            if ($request->filled('swift_code')) $payload['swift_code'] = $request->swift_code;
            if ($request->filled('beneficiary_name')) $payload['beneficiary_name'] = $request->beneficiary_name;
            if ($request->filled('beneficiary_address')) $payload['beneficiary_address'] = $request->beneficiary_address;
            if ($request->filled('beneficiary_city')) $payload['beneficiary_city'] = $request->beneficiary_city;

            Log::info("Initiating transfer", ['payload' => $payload]);

            $response = $this->flutterwave->authorizedRequestV3('POST', 'transfers', [
                'json' => $payload
            ]);

            $body = json_decode($response->getBody(), true);

            Log::info("Transfer response", ['response' => $body]);

            return response()->json([
                'success' => true,
                'message' => $body['message'] ?? 'Transfer initiated successfully',
                'data'    => $body
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
    
    public function resolveAccount(Request $request)
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
                        'bank_code'      => $response['data']['bank_code'],
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
                'message' => 'Something went wrong, please try again later.',
            ], 500);
        }
    }
}
