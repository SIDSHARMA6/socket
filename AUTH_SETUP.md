# Authentication Setup Complete ✅

## What's Been Added

### Backend (Strapi)
- ✅ Email OTP service using Brevo SMTP
- ✅ Password reset with OTP verification
- ✅ Custom auth routes: `/api/auth/send-otp` and `/api/auth/verify-otp`
- ✅ Message filtering (users only see their own messages)
- ✅ Socket.io updated for user-specific messaging

### Flutter App
- ✅ Login page
- ✅ Signup page
- ✅ Forgot password page with OTP
- ✅ Chat bubbles (blue for sent, grey for received)
- ✅ Authentication token handling

## Setup Instructions

### 1. Configure Strapi Permissions

Start the backend:
```bash
cd chat-backend
npm run develop
```

Then configure permissions:

1. Go to `http://localhost:1337/admin`
2. Create admin account (if first time)
3. Go to **Settings** → **Users & Permissions Plugin** → **Roles**

**For Authenticated Role:**
- Message: Enable `find`, `findOne`, `create`

**For Public Role:**
- Auth: Enable `send-otp`, `verify-otp` (custom routes are public by default)
- User: Enable `create` (for registration)

### 2. Test the App

```bash
flutter run
```

**Flow:**
1. Click "Don't have an account? Sign up"
2. Create account with username, email, password
3. You'll be logged in automatically
4. Send messages in the chat

**Reset Password:**
1. Click "Forgot Password?"
2. Enter your email
3. Click "Send OTP"
4. Check your email for the 6-digit code
5. Enter OTP and new password
6. Click "Reset Password"

### 3. Update for Production

In `lib/api.dart`, change:
```dart
static String baseUrl = "https://your-app.onrender.com";
```

## Email Configuration

The app uses Brevo SMTP with credentials from `keys.md`:
- SMTP Server: smtp-relay.brevo.com
- Port: 587
- From: 943fa5001@smtp-brevo.com

OTP emails are sent automatically when user requests password reset.

## Features

### Authentication
- Signup with username, email, password
- Login with email/username and password
- Password reset via email OTP (6-digit code, 10-minute expiry)

### Chat
- Real-time messaging with Socket.io
- Messages filtered by user (only see your conversations)
- Chat bubbles with sender indication
- Message history loaded on login

### Security
- JWT tokens for authentication
- OTP expires after 10 minutes
- Passwords hashed by Strapi
- User-specific message filtering

## Troubleshooting

**OTP not received:**
- Check spam folder
- Verify email is correct
- Check backend logs for email errors

**Login fails:**
- Verify credentials
- Check if user exists in Strapi admin panel
- Ensure backend is running

**Messages not showing:**
- Check Authenticated role permissions
- Verify JWT token is being sent
- Check browser/app console for errors

## Next Steps

1. Add user list to select chat partner
2. Add message timestamps
3. Add read receipts
4. Add typing indicators
5. Deploy to Render (see DEPLOYMENT_GUIDE.md)
