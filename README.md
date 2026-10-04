# EduCore Parent Portal — GitHub Pages Ready

This version is intentionally a **static HTML/CSS/JavaScript application**. It does not require npm, React, Vite, Node.js, or a build step. That makes it much harder for GitHub Pages to show a blank page or fail because of missing build files.

## Upload to GitHub
1. Extract this ZIP.
2. Open the extracted folder.
3. Upload **all files and folders inside it** to the root of your GitHub repository.
4. Commit to `main`.
5. Go to **Settings → Pages**.
6. Select **Deploy from a branch**.
7. Branch: `main`; folder: `/ (root)`; Save.
8. Open the GitHub Pages URL after GitHub finishes deploying.

## Connect to your existing EduCore Supabase
Open `config.js` and replace the empty values with the **same Supabase URL and anon key used by EduCore**.

Run `supabase/migrations/001_parent_portal.sql` in that same Supabase project.

Then create/link parent accounts:
- Supabase Authentication user
- `public.parents.user_id` = Auth user ID
- `public.parent_student_links` contains one row for every child

One parent can therefore have many children.

## Important
Never put the Supabase service-role key in `config.js`. Only the public anon key belongs in a browser application. RLS in the SQL migration limits parents to their own children and published information.
