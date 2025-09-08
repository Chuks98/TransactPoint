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
    public function getBillCategories()
    {
        $response = $this->authorizedRequestV3('GET', 'top-bill-categories', [
            'query' => ['country' => 'NG']
        ]);
        return json_decode($response->getBody(), true);
    }

    public function getBillers($country = null, $categoryCode = null)
    {
        $url    = 'billers';
        $params = [];
        if ($country) $params[] = "country={$country}";
        if ($categoryCode) $params[] = "category={$categoryCode}";
        if ($params) $url .= '?' . implode('&', $params);

        $response = $this->authorizedRequestV3('GET', $url);
        return json_decode($response->getBody(), true);
    }

    public function getBillerItems($billerCode)
    {
        $response = $this->authorizedRequestV3('GET', "billers/{$billerCode}/items");
        return json_decode($response->getBody(), true);
    }

    public function purchaseBill($billerCode, $itemCode, $payload)
    {
        try {
            $client = $this->authorizedClientV3(); 
            $response = $client->post("billers/{$billerCode}/items/{$itemCode}/payment", [
                'json' => $payload
            ]);
            return json_decode($response->getBody(), true);
        } catch (\Exception $e) {
            Log::error("Error purchasing bill: " . $e->getMessage());
            return ['status' => 'error', 'message' => 'Unable to complete bill payment at this time.'];
        }
    }

    public function resolveAccountName($accountNumber, $bankCode)
    {
        $response = $this->authorizedRequestV3('GET', 'accounts/resolve', [
            'query' => [
                'account_number' => $accountNumber,
                'bank_code'      => $bankCode
            ]
        ]);
        return json_decode($response->getBody(), true);
    }
}
