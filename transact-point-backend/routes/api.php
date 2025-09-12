<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BillsController;
use App\Http\Controllers\UserController;

Route::get('/bill-categories', [BillsController::class, 'billCategories']);
Route::get('/billers-by-category', [BillsController::class, 'billersByCategory']);
Route::get('/mobile-networks', [BillsController::class, 'mobileNetworks']);
Route::post('/purchase-airtime', [BillsController::class, 'purchaseAirtime']);
Route::post('/purchase-data', [BillsController::class, 'purchaseData']);
Route::post('/purchase-cable', [BillsController::class, 'purchaseCable']);
Route::post('/purchase-electricity', [BillsController::class, 'purchaseElectricity']);
Route::post('/transfer', [BillsController::class, 'transfer']);
Route::get('/get-banks', [BillsController::class, 'getBanks']);
Route::post('/resolve-account-name', [BillsController::class, 'resolveAccountName']);
Route::get('/convert', [BillsController::class, 'convert']);
Route::post('/fund-account', [BillsController::class, 'fundAccount']);
Route::post('/flutterwave-webhook', [BillsController::class, 'flutterwaveWebhook']);



// User data and wallet routes
Route::prefix('user')->group(function () {
    Route::post('/register', [UserController::class, 'register']);
    Route::post('/login', [UserController::class, 'login']);
    Route::post('/update-password', [UserController::class, 'updatePassword']);
    Route::get('/get-single-user/{id}', [UserController::class, 'getSingleUser']);
    Route::put('/update-single-user/{id}', [UserController::class, 'updateSingleUser']);
    Route::delete('/delete-single-user/{id}', [UserController::class, 'deleteSingleUser']);

    // ✅ Wallet routes
    Route::get('/get-wallet/{userId}', [UserController::class, 'getWallet']);
    Route::post('/create-wallet', [UserController::class, 'createWallet']);
    Route::patch('/update-account', [UserController::class, 'updateAccount']);
});
