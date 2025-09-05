<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    public function register(Request $request)
    {
        try {
            // Validate request (without unique rule here, since we will check manually)
            $request->validate([
                'firstName' => 'required|string|max:255',
                'lastName'  => 'required|string|max:255',
                'phoneNumber' => 'required|string|max:20',
            ]);

            // Check if phone number already exists
            if (User::where('phoneNumber', $request->phoneNumber)->exists()) {
                \Log::info('Registration attempt with existing phone number', [
                    'phoneNumber' => $request->phoneNumber,
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'This phone number is already registered.',
                ], 409); // 409 Conflict
            }

            // Create user
            $user = User::create([
                'firstName'   => $request->firstName,
                'lastName'    => $request->lastName,
                'phoneNumber' => $request->phoneNumber,
            ]);

            \Log::info('New user registered', [
                'user_id' => $user->id,
                'phoneNumber' => $user->phoneNumber,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully.',
                'user'    => $user,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during user registration', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during user registration', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Registration failed. Please try again.',
            ], 500);
        }
    }






    // Updating password
    public function updatePassword(Request $request)
    {
        try {
            // Validate the request
            $request->validate([
                'phoneNumber' => 'required|string|exists:users,phoneNumber',
                'password'    => 'required|string|min:4|max:6', // 4-6 digit PIN
            ]);

            // Find the user
            $user = User::where('phoneNumber', $request->phoneNumber)->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not found.',
                ], 404);
            }

            // Hash the password before saving
            $user->password = Hash::make($request->password);
            $user->save();

            Log::info("User password updated", [
                'phoneNumber' => $user->phoneNumber,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Password set successfully.',
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::warning('Password update validation failed', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            Log::error('Error updating password', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to set password. Please try again.',
            ], 500);
        }
    }
}
