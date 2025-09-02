<?php

namespace App\Services;

use GuzzleHttp\Client;

class FlutterwaveService
{
    private $baseUrl = "https://api.flutterwave.com/v3/";
    // private $baseUrl = "https://ravesandboxapi.flutterwave.com/v3/";
    private $secretKey;
    private $client;

    public function __construct()
    {
        $this->secretKey = env('FLW_SECRET_KEY');

        $this->client = new Client([
            'base_uri' => $this->baseUrl,
            'headers' => [
                'Authorization' => 'Bearer ' . $this->secretKey,
                'Accept'        => 'application/json',
            ]
        ]);
    }

    // ✅ Fetch all billers available on your Flutterwave account
    public function getBillers($country = null)
    {
        $url = "billers";
        if ($country) {
            $url .= "?country={$country}";
        }

        $response = $this->client->get($url);
        return json_decode($response->getBody(), true);
    }


    // Get billers items
    public function getBillerItems($billerCode)
    {
        $response = $this->client->get("billers/{$billerCode}/items");
        return json_decode($response->getBody(), true);
    }


    // Get bill categories (like AIRTIME, DATA, POWER, CABLETV)
    public function getBillCategories()
    {
        $response = $this->client->get("bill-categories");
        return json_decode($response->getBody(), true);
    }


    // ✅ Get mobile networks
    public function getMobileNetworks($country = 'NG')
    {
        $response = $this->client->get("/mobile-networks?country={$country}");
        return json_decode($response->getBody(), true);
    }

    // ✅ Purchase Airtime or Data
    public function purchaseBill($billerCode, $itemCode, $payload)
    {
        $response = $this->client->post("billers/{$billerCode}/items/{$itemCode}/payment", [
            'json' => $payload
        ]);
        return json_decode($response->getBody(), true);
    }

    // public function purchaseBill($billerCode, $itemCode, $payload)
    // {
    //     $response = $this->client->post("bills", [
    //         'json' => $payload
    //     ]);
    //     return json_decode($response->getBody(), true);
    // }
}
