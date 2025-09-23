<?php

namespace App\Services;

use GuzzleHttp\Client;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FlutterwaveService
{
    private $baseUrlV3;
    private $baseUrlV4;

    public function __construct()
    {
        $this->baseUrlV3 = 'https://api.flutterwave.com/v3/';

        $this->baseUrlV4 = env('FLW_ENVIRONMENT') === 'live'
            ? env('FLW_LIVE_API')
            : env('FLW_TEST_API');
    }

    /**
     * ========== V4 CLIENT (OAuth2) ==========
     */
    private function authorizedClientV4()
    {
        $accessToken = $this->getAccessToken();

        return new Client([
            'base_uri' => $this->baseUrlV4,
            'headers'  => [
                'Authorization' => 'Bearer ' . $accessToken,
                'Accept'        => 'application/json',
            ]
        ]);
    }

    public function getAccessToken()
    {
        try {
            return Cache::remember('flutterwave_access_token', 540, function () {
                $clientId     = env('FLW_CLIENT_ID');
                $clientSecret = env('FLW_CLIENT_SECRET');

                $client = new Client();
                $response = $client->post(
                    'https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token',
                    [
                        'form_params' => [
                            'grant_type'    => 'client_credentials',
                            'client_id'     => $clientId,
                            'client_secret' => $clientSecret,
                        ],
                        'headers' => [
                            'Content-Type' => 'application/x-www-form-urlencoded',
                        ],
                    ]
                );

                $body = json_decode($response->getBody(), true);
                Log::info('Fetched new Flutterwave access token', ['token' => $body['access_token']]);
                return $body['access_token'] ?? null;
            });
        } catch (\Exception $e) {
            Log::error('Error fetching access token: ' . $e->getMessage());
            throw $e;
        }
    }

    private function authorizedRequestV4(string $method, string $uri, array $options = [])
    {
        $client = $this->authorizedClientV4();

        try {
            return $client->request($method, $uri, $options);
        } catch (RequestException $e) {
            if ($e->hasResponse() && $e->getResponse()->getStatusCode() === 401) {
                Log::warning("V4 Access token expired. Refreshing...");
                Cache::forget('flutterwave_access_token');
                $client = $this->authorizedClientV4();
                return $client->request($method, $uri, $options);
            }
            throw $e;
        }
    }

    /**
     * ========== PAYMENTS / TRANSACTIONS (V4) ==========
     */
    public function verifyTransaction($id)
    {
        $response = $this->authorizedRequestV4('GET', "transactions/{$id}/verify");
        return json_decode($response->getBody(), true);
    }

    public function refundTransaction($id, $amount, $currency)
    {
        $payload = ['amount' => $amount, 'currency' => $currency];

        $response = $this->authorizedRequestV4('POST', "transactions/{$id}/refund", [
            'json' => $payload
        ]);
        return json_decode($response->getBody(), true);
    }

    public function getTransactionDetails($txRef)
    {
        $response = $this->authorizedRequestV4('GET', "transactions/{$txRef}");
        return json_decode($response->getBody(), true);
    }

    public function getBanks($country = 'NG')
    {
        $response = $this->authorizedRequestV4('GET', "banks?country={$country}");
        return json_decode($response->getBody(), true);
    }

















    /**
     * ========== V3 CLIENT Auth (Secret key) ==========
     */
    private function authorizedClientV3()
    {
        return new Client([
            'base_uri' => $this->baseUrlV3,
            'headers'  => [
                'Authorization' => 'Bearer ' . env('FLW_SECRET_KEY'),
                'Accept'        => 'application/json',
                'accept' => 'application/json',
            ]
        ]);
    }

    private function authorizedRequestV3(string $method, string $uri, array $options = [])
    {
        $client = $this->authorizedClientV3();
        return $client->request($method, $uri, $options);
    }

    /**
     * ========== BILLS (V3 ONLY) ==========
     */


    public function createStaticVirtualAccount(array $userData)
    {
        // userData expected to contain:
        // email, va_ref, firstname, lastname, phonenumber, narration, bvn

        $payload = [
            'email'        => $userData['email'],
            'va_ref'       => $userData['va_ref'],
            'firstname'    => $userData['firstname'],
            'lastname'     => $userData['lastname'],
            'phonenumber'  => $userData['phonenumber'],
            'is_permanent' => true,
            'narration'    => $userData['narration'],
            'bvn'          => $userData['bvn'],  // required for static NGN accounts
        ];

        // Using v3 endpoint with secret key (as per docs)
        $client = $this->authorizedClientV3();  
        $response = $client->post('virtual-account-numbers', [
            'json' => $payload
        ]);

        $body = json_decode($response->getBody(), true);

        if (isset($body['status']) && $body['status'] === 'success') {
            return $body['data'];
        }

        // throw exception or return error depending on your error handling
        throw new \Exception('Could not create virtual account: ' . ($body['message'] ?? 'Unknown error'));
    }



    public function createVirtualAccountForForeignAccounts(array $payload)
    {
        $payload['va_ref'] = 'VA-' . time();

        $response = $this->authorizedRequest('POST', 'virtual-accounts', [
            'json' => $payload
        ]);

        $body = json_decode($response->getBody(), true);

        if ($body['status'] !== 'success') {
            throw new \Exception($body['message'] ?? 'Failed to create V4 virtual account');
        }

        return $body['data'];
    }


    public function getTopBillCategories()
    {
        $response = $this->authorizedRequestV3('GET', 'top-bill-categories', [
            'query' => ['country' => 'NG']
        ]);
        return json_decode($response->getBody(), true);
    }

    public function getBillCategories()
    {
        $response = $this->authorizedRequestV3('GET', 'bill-categories', [
            'query' => ['country' => 'NG']
        ]);
        return json_decode($response->getBody(), true);
    }


    public function purchaseBill($billerCode, $itemCode, $payload)
    {
        $client = $this->authorizedClientV3(); 
        $response = $client->post("billers/{$billerCode}/items/{$itemCode}/payment", [
            'json' => $payload
        ]);
        return json_decode($response->getBody(), true);
    }

    public function resolveAccountName($accountNumber, $bankCode)
    {
        $response = $this->authorizedRequestV3('POST', 'accounts/resolve', [
            'json' => [
                'account_number'    => $accountNumber,
                'account_bank'      => $bankCode,
                "currency"          => "NGN"
            ]
        ]);

        $body = $response->getBody();
        \Log::info('Raw Flutterwave response', ['body' => $body]);
        return json_decode($body, true);
    }


    public function transfer($data)
    {
        $response = $this->authorizedRequestV3('POST', 'transfers', [
            'json' => $data
        ]);

        $body = $response->getBody();
        return json_decode($body, true);
    }

    

    public function convert($amount, $from_currency, $to_currency)
    {
        $response = $this->authorizedRequestV3('GET', "transfers/rates?amount={$amount}&destination_currency={$from_currency}&source_currency={$to_currency}");

        $body = $response->getBody();
        return json_decode($body, true);
    }


    public function fundAccount($payload)
    {
        $response = $this->authorizedRequestV3('POST', 'payments', [
            'json' => $payload,
        ]);

        $body = $response->getBody();
        return json_decode($body, true);
    }
    
}
