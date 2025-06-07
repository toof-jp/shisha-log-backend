-- Create users table (for passkey authentication)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create passkey credentials table (WebAuthn)
CREATE TABLE IF NOT EXISTS public.passkey_credentials (
    id TEXT PRIMARY KEY, -- credential ID from WebAuthn
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    public_key BYTEA NOT NULL, -- public key in COSE format
    counter BIGINT NOT NULL DEFAULT 0, -- signature counter for replay protection
    aaguid BYTEA, -- authenticator attestation GUID
    transports TEXT[], -- supported transports (usb, nfc, ble, internal)
    backup_eligible BOOLEAN DEFAULT FALSE,
    backup_state BOOLEAN DEFAULT FALSE,
    device_name TEXT, -- optional friendly name for the device
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create authentication challenges table (for WebAuthn flow)
CREATE TABLE IF NOT EXISTS public.auth_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge TEXT NOT NULL, -- base64 encoded challenge
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('registration', 'authentication')),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create shisha sessions table
CREATE TABLE IF NOT EXISTS public.shisha_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.users(id),
    session_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    store_name TEXT,
    notes TEXT,
    order_details TEXT,
    mix_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create session flavors table
CREATE TABLE IF NOT EXISTS public.session_flavors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.shisha_sessions(id) ON DELETE CASCADE,
    flavor_name TEXT NOT NULL,
    brand TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER handle_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_shisha_sessions_updated_at BEFORE UPDATE ON public.shisha_sessions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (NEW.id, NEW.display_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_user_created
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create function to clean up expired challenges
CREATE OR REPLACE FUNCTION public.cleanup_expired_challenges()
RETURNS void AS $$
BEGIN
    DELETE FROM public.auth_challenges
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Create indexes for better performance
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_passkey_credentials_user_id ON public.passkey_credentials(user_id);
CREATE INDEX idx_auth_challenges_user_id ON public.auth_challenges(user_id);
CREATE INDEX idx_auth_challenges_expires_at ON public.auth_challenges(expires_at);
CREATE INDEX idx_shisha_sessions_user_id ON public.shisha_sessions(user_id);
CREATE INDEX idx_shisha_sessions_session_date ON public.shisha_sessions(session_date);
CREATE INDEX idx_session_flavors_session_id ON public.session_flavors(session_id);