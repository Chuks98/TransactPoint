<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BillsController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AdminController; // Make sure you create this

// Bills routes
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
Route::post('/create-virtual-account', [BillsController::class, 'createVirtualAccount   ']);
Route::post('/flutterwave-webhook', [BillsController::class, 'flutterwaveWebhook']);



// User routes
Route::prefix('user')->group(function () {
    Route::post('/register', [UserController::class, 'register']);
    Route::post('/login', [UserController::class, 'login']);
    Route::post('/update-password', [UserController::class, 'updatePassword']);
    Route::get('/get-single-user/{id}', [UserController::class, 'getSingleUser']);
    Route::put('/update-single-user/{id}', [UserController::class, 'updateSingleUser']);
    Route::delete('/delete-single-user/{id}', [UserController::class, 'deleteSingleUser']);
    Route::post('/forgot-password', [UserController::class, 'forgotPassword']);
    Route::post('/verify-otp', [UserController::class, 'verifyOTP']);
    Route::post('/reset-password', [UserController::class, 'resetPassword']);

    // Wallet routes
    Route::get('/get-wallet/{userId}', [UserController::class, 'getWallet']);
    Route::post('/create-wallet', [UserController::class, 'createWallet']);
    Route::patch('/update-account', [UserController::class, 'updateAccount']);
    Route::get('/recent-transactions/{userId}', [UserController::class, 'getUserRecentTransactions']);
    Route::get('/transactions/{userId}', [UserController::class, 'getUserTransactions']);
});




// Admin routes
Route::prefix('admin')->group(function () {
    // Auth
    Route::post('/login', [AdminController::class, 'login']);
    Route::post('/logout', [AdminController::class, 'logout']);
    Route::get('/me', [AdminController::class, 'me']);

    // Users
    Route::get('/users', [AdminController::class, 'getAllUsers']);

    // Wallets
    Route::get('/wallets', [AdminController::class, 'getAllWallets']);
    Route::get('/wallet-by-user/{userId}', [AdminController::class, 'getWalletByUser']);

    // Transactions
    Route::get('/transactions', [AdminController::class, 'getAllTransactions']);
    Route::get('/transactions/status/{status}', [AdminController::class, 'getTransactionsByStatus']);
});