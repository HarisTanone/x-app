# Supabase Database Schema - Dating App

## Setup Instructions

1. Create a new Supabase project
2. Run the SQL files in order:
   - `01_auth_users.sql` - Authentication & user management
   - `02_profiles.sql` - User profiles & onboarding
   - `03_matching.sql` - Swipe & matching system
   - `04_chat.sql` - Chat & messaging
   - `05_albums.sql` - Premium content system
   - `06_wallet.sql` - Payment & wallet system
   - `07_admin.sql` - Admin & moderation
   - `08_rls_policies.sql` - Row Level Security policies

## Database Structure

### Core Tables
- `profiles` - User profiles with photos and preferences
- `swipes` - User swipe actions (like/pass)
- `matches` - Matched users who can chat
- `messages` - Chat messages between matches
- `albums` - Premium photo/video albums
- `album_purchases` - Album purchase records
- `wallets` - User wallet balances
- `transactions` - Payment transactions

### Features
- JWT authentication via Supabase Auth
- Real-time chat with Supabase Realtime
- File storage for photos/videos
- Row Level Security for data protection
- Premium content monetization
- Wallet system with top-up/withdrawal

## Key Features Implemented

### 1. Authentication
- Phone/Email + Password login
- OTP verification
- Session management

### 2. User Profiles
- Photo upload (2-6 photos)
- Bio, interests, location
- Age verification (18+)
- Photo verification system

### 3. Matching System
- Swipe left/right functionality
- Location-based filtering
- Age and preference filters
- Undo swipe feature

### 4. Chat System
- Real-time messaging
- Message status (sent/delivered/read)
- Media sharing
- End-to-end encryption ready

### 5. Premium Albums
- Content creator monetization
- Secure content delivery
- Purchase tracking
- Revenue sharing

### 6. Wallet System
- Top-up via multiple payment methods
- Secure transactions
- Withdrawal for creators
- Transaction history

### 7. Admin Panel
- User management
- Content moderation
- Financial tracking
- Analytics dashboard