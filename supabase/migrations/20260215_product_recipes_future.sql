-- Save this script for later use when implementing Product Cost feature
create table public.product_recipes (
    id uuid not null default gen_random_uuid (),
    product_id uuid not null references public.products (id) on delete cascade,
    raw_material_id uuid not null references public.raw_materials (id) on delete restrict,
    quantity numeric not null default 0,
    unit text not null, -- e.g., 'gram', 'ml', 'pcs'
    created_at timestamptz not null default now(),
    updated_at timestamptz,
    primary key (id)
);

-- RLS Policies (example)
alter table public.product_recipes enable row level security;

create policy "Enable read access for all users" on public.product_recipes for
select using (true);

create policy "Enable insert for authenticated users only" on public.product_recipes for
insert
with
    check (
        auth.role () = 'authenticated'
    );

create policy "Enable update for authenticated users only" on public.product_recipes for
update using (
    auth.role () = 'authenticated'
);

create policy "Enable delete for authenticated users only" on public.product_recipes for delete using (
    auth.role () = 'authenticated'
);