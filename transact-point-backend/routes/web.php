<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BillsController;

Route::get('/mobile-networks', [BillsController::class, 'mobileNetworks']);
Route::post('/purchase-airtime', [BillsController::class, 'purchaseAirtime']);
Route::post('/purchase-data', [BillsController::class, 'purchaseData']);
