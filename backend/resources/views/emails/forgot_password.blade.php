<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Password Recovery</title>
</head>
<body style="font-family: Arial, sans-serif; background-color: #F9F9F9; padding:20px; margin:0;">
    <div style="max-width:600px; margin:auto; background:#FFFFFF; border-radius:12px; overflow:hidden; box-shadow:0 2px 8px rgba(0,0,0,0.1);">
        
        <!-- Header -->
        <div style="background:#1FD365; color:#FFFFFF; padding:20px; text-align:center;">
            <h1 style="margin:0; font-size:24px; font-weight:700;">Transact Point</h1>
        </div>

        <!-- Body -->
        <div style="padding:24px; color:#1A1A1A; line-height:1.6;">
            <p style="margin:0 0 16px 0;">Hello {{ $user->firstName }},</p>
            
            <p style="margin:0 0 16px 0;">You requested to recover your login PIN.</p>
            
            <p style="font-size:20px; font-weight:bold; color:#1FD365; margin:0 0 20px 0;">
                Your PIN: {{ $pin }}
            </p>

            <p style="margin:0 0 16px 0;">
                Please keep it safe and <strong>do not share</strong> with anyone.
            </p>
            
            <p style="margin:32px 0 0 0;">Best Regards,<br> 
            <strong>Transact Point Team</strong></p>
        </div>

        <!-- Footer -->
        <div style="background:#F0F0F0; padding:12px; text-align:center; font-size:12px; color:#9E9E9E;">
            &copy; {{ date('Y') }} Transact Point. All rights reserved.
        </div>
    </div>
</body>
</html>
