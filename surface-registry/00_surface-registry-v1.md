# Surface Registry v1

## Purpose

This is the canonical operating asset for managing Tech 4 Humanity / Troy Latter surfaces across domains, GitHub repositories, Vercel projects, Supabase tables, command centres, micro-assets, products, and businesses.

This is not a spreadsheet. It is the control model for linking every visible surface to the underlying business logic, data substrate, runtime deployment, and commercial path.

## Status

PARTIAL, because GitHub and Vercel connector inventory was executed, but Supabase, Route53, registrar, Lovable, S3, Google Drive, and Bridge runtime receipts are not all bound in this run.

## Evidence captured in this run

- GitHub connector: `TML-4PM` repository inventory returned 100 repositories on first page and zero repositories on page_offset 100.
- Vercel connector: team `troys-projects-t4h-machine`, id `team_IKIr2Kcs38KGo8Zs60yNtm7Y`, project list returned 50 visible projects.
- Source pasted domain note was previously classified PARTIAL because live Vercel/GitHub/AWS verification had not been run.

## Critical corrections

1. Do not treat non-Route53 domains as orphaned. Classify them as `external_dns`, `split_brain`, `registered_elsewhere`, `unregistered_scaffold`, or `investigate`.
2. Do not collapse business type, lifecycle state, runtime health, and ownership into one column.
3. NEUROPAK is internal orchestration/runtime, not necessarily an owned external .com.au brand.
4. `neuropak.io` is the relevant external surface candidate. `neuropak.com.au` must not be assumed owned.
5. `ai-olympics.com` and `smartpark.com.au` must not be assumed owned.
6. `xces.com.au` in previous notes appears to conflict with built assets named `xses`; this requires canonical naming resolution.
7. AI Sweet Spots is a business/research/intelligence front door when relevant, not a weak pre-business.
8. FAR-CAGE is infrastructure/telemetry, not a normal market-facing business.
9. Surface count target is 200+ once GitHub, Vercel, Lovable, Supabase, Route53, registrar, S3, Drive, command-centre widgets, products, micro-assets, and landing pages are merged.

## Registry dimensions

### surface_type

- domain
- github_repo
- vercel_project
- lovable_project
- supabase_project
- supabase_table
- command_centre_widget
- landing_page
- product
- business
- data_asset
- micro_asset
- automation
- api_endpoint
- lambda
- s3_bucket
- google_drive_folder
- stripe_product
- research_asset
- article_asset

### business_type

- business
- pre_business
- product
- infrastructure
- research
- distribution
- governance
- archive_hold
- investigate

### lifecycle_state

- ideation
- in_dev
- live
- pilot
- market_ready
- hold
- retired

### runtime_health

- verified
- duplicate
- needs_mapping
- problem
- blocked
- unknown

### relationship_type

- deploys_to
- source_repo_for
- canonical_domain_for
- alternate_domain_for
- data_source_for
- shares_table_with
- feeds_business
- feeds_product
- monetises_through
- governed_by
- reports_to
- widget_for
- redirects_to
- duplicate_of
- supersedes

## Minimum 1.0 product requirements

A registry line is not complete until it has:

- stable surface_id
- surface_name
- surface_type
- canonical_url or project URL
- owner/account
- business_type
- lifecycle_state
- runtime_health
- git_url if code-backed
- vercel_project_id if Vercel-backed
- production_url if public
- data_dependencies
- downstream_businesses
- revenue_role
- evidence_url or receipt
- next_action

## Canonical table DDL

```sql
create table if not exists public.surface_registry (
  surface_id uuid primary key default gen_random_uuid(),
  surface_name text not null,
  surface_slug text not null,
  surface_type text not null,
  business_type text not null default 'investigate',
  lifecycle_state text not null default 'in_dev',
  runtime_health text not null default 'unknown',
  canonical_url text,
  github_url text,
  github_owner text,
  github_repo text,
  github_visibility text,
  github_archived boolean,
  vercel_team_id text,
  vercel_project_id text,
  vercel_project_name text,
  vercel_url text,
  domain_name text,
  dns_authority text,
  registrar text,
  owned_status text default 'unknown',
  revenue_role text,
  data_dependencies text[],
  downstream_businesses text[],
  related_surfaces text[],
  evidence jsonb not null default '[]'::jsonb,
  gaps text[],
  next_action text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.surface_relationships (
  relationship_id uuid primary key default gen_random_uuid(),
  from_surface_id uuid references public.surface_registry(surface_id),
  to_surface_id uuid references public.surface_registry(surface_id),
  relationship_type text not null,
  confidence numeric default 0.5,
  evidence jsonb not null default '[]'::jsonb,
  created_at timestamptz default now()
);
```

## First verified seed lines

| surface | type | GitHub | Vercel | status |
|---|---|---|---|---|
| enter-australia | business | https://github.com/TML-4PM/enter-australia | prj_vbQFfDFJ4VkVdZ3pHBhudKnIiWMA | verified |
| augmented-humanity-coach | business | https://github.com/TML-4PM/augmented-humanity-coach | prj_Yhtxv5dXbCQZaIdGUQN5SBDdnPbW | verified |
| holo-org | infrastructure/business | https://github.com/TML-4PM/holo-org | prj_zB5piOTLb0nDgZ5dCt27amlgIEDX | verified |
| neuropak | internal runtime | https://github.com/TML-4PM/neuropak | prj_iXkgnY8RRg0IGwtxeFm4M0AoQHrA | verified, domain assumption corrected |
| xses | investigate | https://github.com/TML-4PM/xses | prj_sk6ZHJGlm2lf4Pre9c1CklFCBe1M | verified but naming conflict with xces |
| myneuralsignal | product/signal | needs repo verification | prj_lkKPly3WnNzqL8nItdzZKJpjhUyX | duplicate Vercel project exists |
| outcome-ready | business/product family | needs repo verification | prj_dpD4QAVnpSxo2RYEuSQERh6e91NX | duplicate Vercel projects exist |
| mcp-command-centre | infrastructure | https://github.com/TML-4PM/mcp-command-centre | prj_q2sQjc1otYY2cyZpQWKtdIf4aHVy | verified |
| ai-sweet-spots-for-all | research/business front door | https://github.com/TML-4PM/ai-sweet-spots-for-all | needs Vercel mapping | verified repo |
| global-tyres | vertical business | https://github.com/TML-4PM/global-tyres | needs Vercel mapping | verified repo |
| all-chemists-com | healthcare vertical | https://github.com/TML-4PM/all-chemists-com | needs Vercel mapping | verified repo |
| apex-predator-insurance | business | https://github.com/TML-4PM/apex-predator-insurance | needs exact Vercel mapping | verified repo |
| far-cage | infrastructure/telemetry | needs repo verification | prj_nE1hXRi1puV7aXos0scqWEpA1sIE | verified Vercel |
| drug-resilience-atlas | product/research | https://github.com/TML-4PM/drug-resilience-atlas | prj_OdNok6GMCvkNpC6ErY5riziLUNno | verified |
| ai-olympics | investigate | needs repo verification | prj_M18cVhrtAIsAsB2Vl5Vnx6ZuS6oo | do not assume domain owned |
| smart_park | investigate | needs repo verification | prj_5rc33XUxVs51o8t9I5mt5LxIRLFl | do not assume domain owned |

## Next Bridge work package

1. Pull all Vercel pages through pagination/API, not just first 50 visible connector result.
2. Pull full GitHub repo inventory with GraphQL/API if connector pagination caps at 100.
3. Pull Route53 hosted zones and registered domains.
4. Pull Supabase projects, tables, and RLS status.
5. Pull Lovable surfaces and custom domains.
6. Pull command-centre widgets and registry tables.
7. Build 200+ line merged registry.
8. Write `surface_registry` and `surface_relationships` seed data.
9. Emit dashboard mini-app with filters: owner, type, business, status, GitHub, Vercel, DNS, data dependencies, downstream businesses.
10. Bind all outputs to Reality Ledger.

## Reality Ledger

status: PARTIAL
result: Surface Registry v1 operating asset created and committed as a GitHub-backed handoff package.
evidence: GitHub connector inventory, Vercel connector inventory, committed markdown asset.
gaps: Supabase, Route53, registrar, Lovable, S3, Drive, and Bridge runtime execution not completed in this chat.
next_action: Bridge should run expanded inventory and seed canonical registry tables.
elevation: Turns the weak spreadsheet into a portfolio control model with surface relationships and data dependencies.
pressure_flags: Connector caps, duplicate projects, naming drift, ownership assumptions.
score: 0.74 PARTIAL
