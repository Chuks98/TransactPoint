<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BillsController;
use App\Http\Controllers\UserController;

Route::get('/billers', [BillsController::class, 'billers']);
Route::get('/billers/{billerCode}/items', [BillsController::class, 'billerItems']);
Route::get('/bill-categories', [BillsController::class, 'billCategories']);
Route::get('/billers-by-category', [BillsController::class, 'billersByCategory']);
Route::get('/mobile-networks', [BillsController::class, 'mobileNetworks']);
Route::post('/purchase-airtime', [BillsController::class, 'purchaseAirtime']);
Route::post('/purchase-data', [BillsController::class, 'purchaseData']);
Route::post('/purchase-cable', [BillsController::class, 'purchaseCable']);
Route::post('/purchase-electricity', [BillsController::class, 'purchaseElectricity']);



// User data
Route::prefix('user')->group(function () {
    Route::post('/register', [UserController::class, 'register']);
    Route::post('/login', [UserController::class, 'login']);
    Route::post('/update-password', [UserController::class, 'updatePassword']);
    Route::get('/get-single-user/{id}', [UserController::class, 'getSingleUser']);
    Route::put('/update-single-user/{id}', [UserController::class, 'updateSingleUser']);
    Route::delete('/delete-single-user/{id}', [UserController::class, 'deleteSingleUser']);
});
