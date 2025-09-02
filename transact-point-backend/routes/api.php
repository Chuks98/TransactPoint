<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BillsController;

Route::get('/billers', [BillsController::class, 'billers']);
Route::get('/billers/{billerCode}/items', [BillsController::class, 'billerItems']);
Route::get('/bill-categories', [BillsController::class, 'billCategories']);
Route::get('/billers-by-category', [BillsController::class, 'billersByCategory']);
Route::get('/mobile-networks', [BillsController::class, 'mobileNetworks']);
Route::post('/purchase-airtime', [BillsController::class, 'purchaseAirtime']);
Route::post('/purchase-data', [BillsController::class, 'purchaseData']);
