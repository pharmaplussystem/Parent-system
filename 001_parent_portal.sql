-- EduCore Parent Portal migration. Run this in the SAME Supabase project as EduCore.
create table if not exists public.parent_student_links (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.parents(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  relationship varchar(50) default 'Parent',
  status varchar(20) not null default 'Active',
  is_primary boolean default false,
  created_at timestamptz default now(),
  unique(parent_id, student_id)
);
create index if not exists idx_parent_student_links_parent on public.parent_student_links(parent_id);
create index if not exists idx_parent_student_links_student on public.parent_student_links(student_id);

create table if not exists public.parent_messages (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references public.schools(id) on delete cascade,
  parent_id uuid not null references public.parents(id) on delete cascade,
  subject varchar(255),
  message text not null,
  created_at timestamptz default now()
);
create index if not exists idx_parent_messages_parent on public.parent_messages(parent_id, created_at desc);

-- Parent accounts need role Parent in profiles. Existing admin/staff policies remain untouched.
alter table public.parent_student_links enable row level security;
alter table public.parent_messages enable row level security;

create or replace function public.current_parent_id()
returns uuid language sql stable security definer set search_path=public
as $$ select id from public.parents where user_id=auth.uid() limit 1 $$;

create or replace function public.parent_can_view_student(p_student uuid)
returns boolean language sql stable security definer set search_path=public
as $$
  select exists(select 1 from public.parent_student_links l where l.parent_id=public.current_parent_id() and l.student_id=p_student and l.status='Active')
  or exists(select 1 from public.students s where s.id=p_student and s.parent_id=public.current_parent_id());
$$;

drop policy if exists parent_links_select_own on public.parent_student_links;
create policy parent_links_select_own on public.parent_student_links for select to authenticated using (parent_id=public.current_parent_id());

drop policy if exists parent_messages_select_own on public.parent_messages;
create policy parent_messages_select_own on public.parent_messages for select to authenticated using (parent_id=public.current_parent_id());

-- Read-only policies for parent-owned student information. Management INSERT/UPDATE policies are not removed.
drop policy if exists parent_students_select on public.students;
create policy parent_students_select on public.students for select to authenticated using (public.parent_can_view_student(id));

drop policy if exists parent_attendance_select on public.attendance;
create policy parent_attendance_select on public.attendance for select to authenticated using (public.parent_can_view_student(student_id));

drop policy if exists parent_payments_select on public.payments;
create policy parent_payments_select on public.payments for select to authenticated using (public.parent_can_view_student(student_id));

drop policy if exists parent_results_select on public.results;
create policy parent_results_select on public.results for select to authenticated using (public.parent_can_view_student(student_id) and is_published=true);

drop policy if exists parent_reports_select on public.report_cards;
create policy parent_reports_select on public.report_cards for select to authenticated using (public.parent_can_view_student(student_id) and is_published=true);

drop policy if exists parent_schools_select on public.schools;
create policy parent_schools_select on public.schools for select to authenticated using (exists(select 1 from public.parents p where p.user_id=auth.uid() and p.school_id=schools.id));

drop policy if exists parent_notifications_select on public.notifications;
create policy parent_notifications_select on public.notifications for select to authenticated using (target_role in ('All','Parent') and exists(select 1 from public.parents p where p.user_id=auth.uid() and p.school_id=notifications.school_id));

-- IMPORTANT: parent profiles should be linked by an administrator. Parents are not granted write access.
