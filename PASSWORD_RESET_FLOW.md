# Password Reset Flow - How It Works ✅

## The Flow (User Stays in App!)

```
┌─────────────────────────────────────────────────────────────┐
│                    1. User Opens App                        │
│                    Clicks "Forgot Password?"                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    2. Enter Email Screen                    │
│                                                             │
│   ┌───────────────────────────────────────────────┐        │
│   │  Email: user@example.com                      │        │
│   └───────────────────────────────────────────────┘        │
│                                                             │
│              [Send OTP Button]                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 3. Backend Sends Email                      │
│                                                             │
│   • Generates 6-digit OTP (e.g., 123456)                   │
│   • Stores OTP in memory with 10-min expiry                │
│   • Sends email via Brevo SMTP                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              4. User Receives Email (Gmail)                 │
│                                                             │
│   ╔═══════════════════════════════════════════════════╗    │
│   ║  Password Reset Request                           ║    │
│   ║                                                   ║    │
│   ║  You requested to reset your password.           ║    │
│   ║  Use the OTP code below in the app:              ║    │
│   ║                                                   ║    │
│   ║         ┌─────────────────────┐                  ║    │
│   ║         │     1 2 3 4 5 6     │  ← 6-digit OTP   ║    │
│   ║         └─────────────────────┘                  ║    │
│   ║                                                   ║    │
│   ║  This code will expire in 10 minutes.            ║    │
│   ╚═══════════════════════════════════════════════════╝    │
│                                                             │
│   User copies: 123456                                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│           5. User Returns to App (Still Open!)              │
│                                                             │
│   ┌───────────────────────────────────────────────┐        │
│   │  Enter 6-digit OTP: 123456                    │        │
│   └───────────────────────────────────────────────┘        │
│   ┌───────────────────────────────────────────────┐        │
│   │  New Password: ••••••••                       │        │
│   └───────────────────────────────────────────────┘        │
│   ┌───────────────────────────────────────────────┐        │
│   │  Confirm Password: ••••••••                   │        │
│   └───────────────────────────────────────────────┘        │
│                                                             │
│              [Reset Password Button]                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  6. Backend Verifies                        │
│                                                             │
│   ✓ Check if OTP matches                                   │
│   ✓ Check if OTP not expired                               │
│   ✓ Check if passwords match                               │
│   ✓ Update user password                                   │
│   ✓ Delete OTP from memory                                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                7. Success! Back to Login                    │
│                                                             │
│   "Password reset successfully! Please login."              │
│                                                             │
│   User can now login with new password                      │
└─────────────────────────────────────────────────────────────┘
```

## Why OTP Instead of Link?

### ❌ Email Link Approach (Bad for Mobile Apps)
```
Email → Click Link → Opens Browser → Needs Deep Linking → Complex Setup
```
**Problems:**
- Requires deep linking configuration
- May open in browser instead of app
- User might close app
- Complex token handling in URLs
- Bad user experience

### ✅ OTP Approach (Perfect for Mobile Apps)
```
Email → Copy OTP → Paste in App → Done
```
**Benefits:**
- ✅ User stays in the app
- ✅ Simple copy-paste
- ✅ No deep linking needed
- ✅ Works on all devices
- ✅ Better security (short expiry)
- ✅ Great user experience

## Email Example

When user requests password reset, they receive:

```
Subject: Password Reset OTP - Chat App

Password Reset Request

You requested to reset your password. Use the OTP code below in the app:

    ┌─────────────┐
    │  1 2 3 4 5 6 │
    └─────────────┘

This code will expire in 10 minutes.

If you didn't request this, please ignore this email.
```

## Security Features

1. **6-digit OTP**: Easy to type, hard to guess (1 in 1,000,000)
2. **10-minute expiry**: Short window reduces risk
3. **One-time use**: OTP deleted after successful reset
4. **Email verification**: Only registered emails can reset
5. **Password validation**: Minimum 6 characters
6. **Confirm password**: Prevents typos

## User Experience

### Step-by-Step for User:

1. **Forgot password?** → Click link on login screen
2. **Enter email** → Type registered email
3. **Send OTP** → Click button
4. **Check email** → Open Gmail/email app
5. **Copy OTP** → Copy the 6-digit code
6. **Return to app** → App is still open!
7. **Paste OTP** → Paste code
8. **New password** → Type new password
9. **Confirm** → Type again to confirm
10. **Reset** → Click button
11. **Success!** → Login with new password

## Testing

### Test the Flow:

1. Start backend: `cd chat-backend && npm run develop`
2. Start app: `flutter run`
3. Create account with real email
4. Logout (or use "Forgot Password?")
5. Enter your email
6. Check your email for OTP
7. Copy OTP and paste in app
8. Set new password
9. Login with new password

### Test Cases:

- ✅ Valid OTP → Success
- ❌ Wrong OTP → Error message
- ❌ Expired OTP (after 10 min) → Error message
- ❌ Passwords don't match → Error message
- ❌ Password too short → Error message
- ❌ Email not registered → Error message

## Code Highlights

### Backend (OTP Generation)
```javascript
// Generate 6-digit OTP
const otp = Math.floor(100000 + Math.random() * 900000).toString();

// Store with expiry
otpStore.set(email, {
  otp,
  expires: Date.now() + 10 * 60 * 1000 // 10 minutes
});
```

### Flutter (OTP Input)
```dart
TextField(
  controller: otpController,
  keyboardType: TextInputType.number,
  maxLength: 6,
  decoration: InputDecoration(
    labelText: 'Enter 6-digit OTP',
  ),
)
```

## Production Notes

For production deployment:
- Consider using Redis instead of in-memory storage for OTPs
- Add rate limiting (max 3 OTP requests per hour)
- Add SMS OTP as backup option
- Log all password reset attempts
- Add CAPTCHA to prevent abuse

## Summary

✅ **Current Implementation:**
- User receives **6-digit OTP code** in email
- User **stays in the app** throughout the process
- User **copies and pastes** OTP
- Simple, secure, and great UX

❌ **NOT Using:**
- Email reset links
- Browser redirects
- Deep linking
- Complex token URLs
