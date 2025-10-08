// supabase/functions/create-member/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // This is needed if you're planning to invoke your function from a browser.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { name, email } = await req.json();

    // Create a Supabase client with the service role key
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // --- STEP 1: Create the user in the auth system ---
    const password = `${name.split(' ')[0].toLowerCase()}123`; // Simple password generation
    const { data: { user }, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Auto-confirm the email
      user_metadata: { full_name: name, role: 'member' }
    });

    if (authError) throw authError;
    if (!user) throw new Error('User creation failed.');

    // --- STEP 2: Create the public 'profiles' record ---
    // This makes the function self-contained and avoids race conditions with triggers.
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: user.id,
        full_name: name,
        role: 'member'
      });

    if (profileError) {
      // If profile creation fails, it's a good idea to clean up the created auth user
      await supabaseAdmin.auth.admin.deleteUser(user.id);
      throw profileError;
    }

    // --- STEP 3: Create the corresponding record in the public 'members' table ---
    const { error: membersError } = await supabaseAdmin
      .from('members')
      .insert({
        user_id: user.id, // Link to the auth user
        name: name,
        email: email,
        status: 'active', // Set a default status
      });

    if (membersError) {
      // If member creation fails, clean up the auth user and profile
      await supabaseAdmin.auth.admin.deleteUser(user.id);
      // The profile should be deleted automatically if you have a foreign key with cascade delete.
      throw membersError;
    }

    // Return the created user data
    return new Response(JSON.stringify({ user }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
})