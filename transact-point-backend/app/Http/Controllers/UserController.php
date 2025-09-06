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
            // Validate base fields
            $request->validate([
                'firstName'   => 'required|string|max:255',
                'lastName'    => 'required|string|max:255',
                'phoneNumber' => 'required|string|max:20',
                'password'    => 'nullable|string|min:4|max:6', // optional PIN
            ]);

            // Check if user exists
            $user = User::where('phoneNumber', $request->phoneNumber)->first();

            if ($user) {
                // 🔑 If password is provided, update it
                if ($request->filled('password')) {
                    $user->password = Hash::make($request->password);
                    $user->save();

                    \Log::info("User password updated", [
                        'phoneNumber' => $user->phoneNumber,
                    ]);

                    return response()->json([
                        'success' => true,
                        'message' => 'Password updated successfully.',
                        'user'    => $user,
                    ], 200);
                }

                return response()->json([
                    'success' => false,
                    'message' => 'This phone number is already registered.',
                ], 409); // Conflict
            }

            // 👤 If user does not exist, create them
            $newUser = User::create([
                'firstName'   => $request->firstName,
                'lastName'    => $request->lastName,
                'phoneNumber' => $request->phoneNumber,
                'password'    => $request->filled('password')
                                    ? Hash::make($request->password)
                                    : null,
            ]);

            \Log::info('New user registered', [
                'user_id' => $newUser->id,
                'phoneNumber' => $newUser->phoneNumber,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'User registered successfully.',
                'user'    => $newUser,
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            \Log::warning('Validation failed during registration', [
                'errors' => $e->errors(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $e->errors(),
            ], 422);

        } catch (\Exception $e) {
            \Log::error('Error during registration/update', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Something went wrong. Please try again.',
            ], 500);
        }
    }

}
