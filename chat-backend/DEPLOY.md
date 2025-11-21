# Deploy to Render

## Quick Deploy Steps

1. **Push to GitHub**
   ```bash
   cd chat-backend
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Create Render Account**
   - Go to https://render.com
   - Sign up or log in

3. **Deploy Backend**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select the `chat-backend` folder
   - Configure:
     - **Name**: chat-backend
     - **Environment**: Node
     - **Build Command**: `npm install && npm run build`
     - **Start Command**: `npm run start`
     - **Instance Type**: Free

4. **Add PostgreSQL Database**
   - Click "New +" → "PostgreSQL"
   - Name: chat-db
   - Plan: Free
   - Create Database

5. **Set Environment Variables**
   In your web service settings, add:
   ```
   NODE_ENV=production
   DATABASE_CLIENT=postgres
   DATABASE_HOST=[from Render PostgreSQL]
   DATABASE_PORT=5432
   DATABASE_NAME=[from Render PostgreSQL]
   DATABASE_USERNAME=[from Render PostgreSQL]
   DATABASE_PASSWORD=[from Render PostgreSQL]
   DATABASE_SSL=true
   APP_KEYS=[generate random string]
   API_TOKEN_SALT=[generate random string]
   ADMIN_JWT_SECRET=[generate random string]
   TRANSFER_TOKEN_SALT=[generate random string]
   JWT_SECRET=[generate random string]
   PUBLIC_URL=https://your-app.onrender.com
   ```

6. **Deploy**
   - Click "Manual Deploy" → "Deploy latest commit"
   - Wait for deployment to complete

7. **Configure Strapi**
   - Visit `https://your-app.onrender.com/admin`
   - Create admin account
   - Go to Settings → Roles → Public → Message
   - Enable: `find`, `findOne`, `create`
   - Save

8. **Update Flutter App**
   - In `lib/api.dart`, change:
   ```dart
   static String baseUrl = "https://your-app.onrender.com";
   ```

## Generate Random Secrets

Use this command to generate secure random strings:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

Run it 5 times for each secret variable.

## Troubleshooting

- **Build fails**: Check Node version (should be 20.x)
- **Database connection fails**: Verify all DATABASE_* env vars are set correctly
- **CORS errors**: Check that Socket.io CORS is set to allow your Flutter app domain
