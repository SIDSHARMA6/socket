# Quick Start Guide 🚀

## What You Have Now

✅ **Complete Chat App with Authentication**
- Signup, Login, Password Reset
- Real-time messaging with Socket.io
- Email OTP via Brevo
- User-specific message filtering
- Beautiful chat bubbles

## Start the App (2 Commands)

### 1. Start Backend
```bash
cd chat-backend
npm run develop
```
Wait for: `Server started on http://localhost:1337`

### 2. Start Flutter App
```bash
flutter run
```

## First Time Setup (One Time Only)

### Configure Strapi Permissions:

1. Open `http://localhost:1337/admin`
2. Create admin account
3. Go to **Settings** → **Users & Permissions Plugin** → **Roles**

**Authenticated Role:**
- Message: ✅ `find`, ✅ `findOne`, ✅ `create`

**Public Role:**
- User: ✅ `create` (for signup)

That's it! The custom auth routes are already public.

## Test the App

### 1. Signup
- Click "Don't have an account? Sign up"
- Enter username, email (use real email!), password
- Auto-login after signup

### 2. Chat
- Send messages
- See them appear in real-time
- Blue bubbles = your messages
- Grey bubbles = received messages

### 3. Password Reset
- Logout (close app and reopen)
- Click "Forgot Password?"
- Enter your email
- Check email for 6-digit OTP
- Copy OTP
- Paste in app
- Enter new password + confirm
- Login with new password

## Email Configuration

Already configured with your Brevo credentials:
- SMTP: smtp-relay.brevo.com
- Port: 587
- From: 943fa5001@smtp-brevo.com

OTP emails sent automatically!

## File Structure

```
socket/
├── chat-backend/          # Strapi backend
│   ├── src/
│   │   ├── index.js       # Socket.io setup
│   │   └── api/
│   │       ├── auth/      # OTP email routes
│   │       └── message/   # Chat messages
│   └── config/            # Database, server config
│
├── lib/                   # Flutter app
│   ├── main.dart          # App entry (Login page)
│   ├── login_page.dart    # Login screen
│   ├── signup_page.dart   # Signup screen
│   ├── forgot_password_page.dart  # Reset password
│   ├── chat_page.dart     # Chat screen
│   ├── auth_service.dart  # Auth API calls
│   └── api.dart           # Message API calls
│
└── Documentation/
    ├── AUTH_SETUP.md              # Auth details
    ├── PASSWORD_RESET_FLOW.md     # How OTP works
    └── DEPLOYMENT_GUIDE.md        # Deploy to Render
```

## Common Issues

**Backend won't start:**
```bash
cd chat-backend
npm install
npm run build
npm run develop
```

**Flutter errors:**
```bash
flutter clean
flutter pub get
flutter run
```

**OTP not received:**
- Check spam folder
- Verify email is correct
- Check backend console for errors

**Can't login:**
- Make sure backend is running
- Check credentials
- Try signup with new account

## Production Deployment

When ready to deploy:

1. **Update Flutter app URL:**
   In `lib/api.dart`:
   ```dart
   static String baseUrl = "https://your-app.onrender.com";
   ```

2. **Deploy backend to Render:**
   Follow `DEPLOYMENT_GUIDE.md`

3. **Build Flutter app:**
   ```bash
   flutter build apk  # Android
   flutter build ios  # iOS
   ```

## Features Summary

### Authentication
- ✅ Signup with username, email, password
- ✅ Login with email/username
- ✅ Password reset via email OTP
- ✅ JWT token authentication
- ✅ 6-digit OTP (10-minute expiry)

### Chat
- ✅ Real-time messaging
- ✅ Socket.io integration
- ✅ User-specific messages
- ✅ Chat bubbles (sent/received)
- ✅ Message history

### Email
- ✅ Brevo SMTP integration
- ✅ Beautiful HTML emails
- ✅ OTP delivery
- ✅ Auto-expiry

## Next Steps

1. ✅ Test signup/login/reset
2. ✅ Test chat messaging
3. ✅ Test OTP email
4. 📱 Add user list
5. 📱 Add timestamps
6. 📱 Add typing indicators
7. 🚀 Deploy to Render

## Need Help?

Check these files:
- `AUTH_SETUP.md` - Authentication details
- `PASSWORD_RESET_FLOW.md` - How OTP works
- `DEPLOYMENT_GUIDE.md` - Deploy to production

## You're Ready! 🎉

Just run:
```bash
# Terminal 1
cd chat-backend && npm run develop

# Terminal 2
flutter run
```

Enjoy your chat app!
