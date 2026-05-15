-- =============================================================================
-- 09-seed-data-sales.sql — fictional CRM + sales data
-- =============================================================================
--
-- 25 products, 40 customers (mix of segments + countries), ~60 contacts,
-- ~50 opportunities, ~80 orders, ~150 order_items, 30 invoices.
--
-- Customers reference HR sales reps (employees 41-55, AEs only) as opp owners.
-- Invoices reference HR finance staff (employees 63-68) as creators.

\echo '== Seeding sales.products =='

INSERT INTO sales.products (sku, name, description, category, list_price, cost, weight_kg, tags) VALUES
  ('HX-100001', 'Helix Atlas Industrial Mixer M-200',     'Heavy-duty 200L industrial mixer for chemical processing.',   'industrial',  18500.00, 11000.00, 145.0,  ARRAY['mixer','industrial','chemical']),
  ('HX-100002', 'Helix Atlas Conveyor Belt CB-Pro',       'Modular conveyor belt, 10m configurable.',                    'industrial',   7200.00,  4100.00,  62.0,  ARRAY['conveyor','industrial']),
  ('HX-100003', 'Helix Atlas Pressure Vessel PV-50',      '50-bar stainless steel pressure vessel.',                     'industrial',  24000.00, 14500.00, 410.0,  ARRAY['pressure','vessel','industrial']),
  ('HX-100004', 'Helix Atlas Hydraulic Press HP-15T',     '15-ton bench-mount hydraulic press.',                         'industrial',   3850.00,  2150.00,  88.0,  ARRAY['press','hydraulic']),
  ('HX-100005', 'Helix Atlas Servo Motor SM-3kW',         'Industrial servo motor, 3kW continuous.',                     'industrial',   1450.00,   720.00,  18.5,  ARRAY['motor','servo']),
  ('HX-100006', 'Helix Atlas Filtration Unit FU-Compact', 'Compact filtration unit, 5 micron rating.',                   'industrial',   2100.00,  1080.00,  24.0,  ARRAY['filter','filtration']),
  ('HX-100007', 'Helix Atlas Conveyor Roller (10-pack)',  'Replacement rollers for CB-Pro conveyors.',                   'industrial',    340.00,   125.00,   8.5,  ARRAY['conveyor','spare']),
  ('HX-100008', 'Helix Atlas Belt Tensioner BT-2',        'Self-adjusting belt tensioner.',                              'industrial',    580.00,   215.00,   3.2,  ARRAY['conveyor','spare']),
  ('HX-100009', 'Helix Atlas Mixer Blade Set MX-Std',     'Standard 6-blade mixer head for M-200.',                      'industrial',    920.00,   410.00,  12.0,  ARRAY['mixer','spare']),
  ('HX-100010', 'Helix Atlas Compact Pump CP-1',          '1HP centrifugal pump, brass body.',                           'industrial',    640.00,   305.00,   9.4,  ARRAY['pump']),
  ('HX-200001', 'Helix Atlas Smart Thermostat T-Wave',    'Wi-Fi-enabled smart thermostat for residential HVAC.',        'consumer',      189.00,    62.00,   0.3,  ARRAY['thermostat','smart-home']),
  ('HX-200002', 'Helix Atlas Air Purifier AP-Tower',      'HEPA + activated carbon air purifier, 600 sq.ft coverage.',   'consumer',      329.00,   115.00,   8.0,  ARRAY['purifier','smart-home']),
  ('HX-200003', 'Helix Atlas Coffee Maker CM-Brew',       '12-cup programmable coffee maker.',                           'consumer',       89.00,    32.00,   3.5,  ARRAY['kitchen']),
  ('HX-200004', 'Helix Atlas Robot Vacuum RV-Nav',        'LiDAR-guided robot vacuum with auto-empty base.',             'consumer',      649.00,   245.00,   4.5,  ARRAY['vacuum','smart-home']),
  ('HX-200005', 'Helix Atlas Standing Desk SD-Pro',       'Electric height-adjustable standing desk.',                   'consumer',      499.00,   210.00,  35.0,  ARRAY['furniture','office']),
  ('HX-200006', 'Helix Atlas LED Light Strip LS-RGB',     '5m smart RGB LED strip with app control.',                    'consumer',       45.00,    14.00,   0.4,  ARRAY['lighting','smart-home']),
  ('HX-200007', 'Helix Atlas Air Fryer AF-XL',            '8L XL air fryer with 12 presets.',                            'consumer',      149.00,    52.00,   6.8,  ARRAY['kitchen']),
  ('HX-200008', 'Helix Atlas Smart Doorbell DB-Vision',   'Battery-powered smart doorbell with HD video.',               'consumer',      219.00,    78.00,   0.6,  ARRAY['doorbell','smart-home','security']),
  ('HX-300001', 'HAIL Installation Service — Standard',   'On-site installation, up to 4 hours, 1 technician.',          'service',       450.00,   180.00,   0.0,  ARRAY['service','install']),
  ('HX-300002', 'HAIL Installation Service — Complex',    'Complex install, up to 8 hours, 2 technicians.',              'service',      1200.00,   480.00,   0.0,  ARRAY['service','install']),
  ('HX-300003', 'HAIL Annual Maintenance Plan — Tier 1',  'Quarterly preventive maintenance for industrial equipment.',  'service',      2400.00,   720.00,   0.0,  ARRAY['service','maintenance','annual']),
  ('HX-300004', 'HAIL Annual Maintenance Plan — Tier 2',  'Monthly maintenance + 24x7 priority support.',                'service',      6800.00,  2200.00,   0.0,  ARRAY['service','maintenance','annual','priority']),
  ('HX-300005', 'HAIL Training Workshop — Half Day',      'Half-day on-site training, up to 8 attendees.',               'service',       950.00,   340.00,   0.0,  ARRAY['service','training']),
  ('HX-300006', 'HAIL Training Workshop — Full Day',      'Full-day on-site training, up to 12 attendees.',              'service',      1750.00,   620.00,   0.0,  ARRAY['service','training']),
  ('HX-300007', 'HAIL Extended Warranty — 2 Years',       'Extended warranty (2 years on top of standard).',             'service',       380.00,   115.00,   0.0,  ARRAY['service','warranty'])
ON CONFLICT (sku) DO NOTHING;

\echo '== Seeding sales.customers =='

INSERT INTO sales.customers (account_number, legal_name, trading_name, industry, country_code, segment, annual_revenue, employee_count, status, credit_limit, metadata) VALUES
  ('ACC-00001', 'Pacific Northwest Refining Corp.',    'PNR',           'Energy',       'US', 'enterprise',  4200000000, 8500, 'active',  500000, '{"renewals_due":"2026-09"}'::jsonb),
  ('ACC-00002', 'Midwest Grain & Storage Inc.',         'MGS',           'Agriculture', 'US', 'enterprise',   780000000, 1900, 'active',  300000, '{}'::jsonb),
  ('ACC-00003', 'Bayswater Brewing Company',            'Bayswater',     'Food & Bev',  'GB', 'mid_market',   145000000,  620, 'active',  150000, '{}'::jsonb),
  ('ACC-00004', 'Nordic Marine Equipment AB',           'Nordic Marine', 'Marine',      'SE', 'mid_market',    98000000,  340, 'active',   80000, '{}'::jsonb),
  ('ACC-00005', 'Ramirez Hermanos S.A. de C.V.',        'Ramirez',       'Manufacturing','MX', 'mid_market',    62000000,  280, 'active',   80000, '{}'::jsonb),
  ('ACC-00006', 'Tokyo Precision Industries Co. Ltd.',  'TPI',           'Electronics', 'JP', 'enterprise',   980000000, 2400, 'active',  250000, '{}'::jsonb),
  ('ACC-00007', 'Brisbane Coastal Logistics Pty Ltd',   'Brisbane Logistics','Logistics','AU','mid_market',    85000000,  410, 'active',   75000, '{}'::jsonb),
  ('ACC-00008', 'Lagos Industrial Holdings Ltd.',       'LIH',           'Industrial',  'NG', 'mid_market',    52000000,  220, 'active',   60000, '{}'::jsonb),
  ('ACC-00009', 'Highlands Distillery Group',           'Highlands',     'Food & Bev',  'GB', 'smb',           18000000,   85, 'active',   40000, '{}'::jsonb),
  ('ACC-00010', 'Greater Boston Hospital Network',      'GBHN',          'Healthcare',  'US', 'enterprise',  1100000000, 5200, 'active',  200000, '{}'::jsonb),
  ('ACC-00011', 'Patel & Sons Manufacturing',           'P&S',           'Manufacturing','IN','smb',           12000000,  140, 'active',   30000, '{}'::jsonb),
  ('ACC-00012', 'Atlas Foods Group Pty Ltd',            'Atlas Foods',   'Food & Bev',  'AU', 'mid_market',    72000000,  310, 'active',   90000, '{}'::jsonb),
  ('ACC-00013', 'Mediterranean Olive Oil Cooperative',  'MOOC',          'Agriculture', 'IT', 'smb',            8500000,   65, 'active',   20000, '{}'::jsonb),
  ('ACC-00014', 'Toronto Polytechnic Materials Lab',    'TPML',          'Education',   'CA', 'mid_market',    35000000,  180, 'active',   50000, '{}'::jsonb),
  ('ACC-00015', 'Rio de Janeiro Steel Works',           'RJSW',          'Metals',      'BR', 'enterprise',   620000000, 1850, 'active',  175000, '{}'::jsonb),
  ('ACC-00016', 'Johannesburg Mining Supply Co.',       'JMSC',          'Mining',      'ZA', 'mid_market',    88000000,  430, 'active',   95000, '{}'::jsonb),
  ('ACC-00017', 'Berlin Tech Manufacturing GmbH',       'BTM',           'Electronics', 'DE', 'enterprise',   540000000, 1500, 'active',  180000, '{}'::jsonb),
  ('ACC-00018', 'Seoul Component Industries',           'SCI',           'Electronics', 'KR', 'enterprise',   720000000, 2100, 'active',  220000, '{}'::jsonb),
  ('ACC-00019', 'Helsinki Maritime Solutions OY',       'Helsinki Maritime','Marine',   'FI', 'mid_market',    44000000,  195, 'active',   55000, '{}'::jsonb),
  ('ACC-00020', 'Singapore Port Equipment Pte Ltd',     'SPE',           'Logistics',   'SG', 'enterprise',   260000000,  640, 'active',  120000, '{}'::jsonb),
  ('ACC-00021', 'New England Coffee Roasters',          'NECR',          'Food & Bev',  'US', 'smb',            6500000,   42, 'active',   18000, '{}'::jsonb),
  ('ACC-00022', 'Dubai Industrial Cleaning LLC',        'DIC',           'Services',    'AE', 'mid_market',    32000000,  170, 'active',   45000, '{}'::jsonb),
  ('ACC-00023', 'Cairo Pharmaceutical Manufacturing',   'CPM',           'Pharma',      'EG', 'mid_market',    96000000,  520, 'active',  110000, '{}'::jsonb),
  ('ACC-00024', 'Vancouver Marine Services Ltd.',       'VMS',           'Marine',      'CA', 'smb',           14000000,   78, 'active',   28000, '{}'::jsonb),
  ('ACC-00025', 'Shanghai Industrial Robotics Co.',     'SIR',           'Robotics',    'CN', 'enterprise',   880000000, 2700, 'active',  240000, '{}'::jsonb),
  ('ACC-00026', 'Mumbai Heavy Equipment Pvt Ltd',       'MHE',           'Industrial',  'IN', 'mid_market',   105000000,  560, 'active',  120000, '{}'::jsonb),
  ('ACC-00027', 'Oslo Hydropower Maintenance AS',       'OHM',           'Energy',      'NO', 'mid_market',    78000000,  340, 'active',   90000, '{}'::jsonb),
  ('ACC-00028', 'Buenos Aires Bottling Group',          'BABG',          'Food & Bev',  'AR', 'mid_market',    52000000,  280, 'suspended', 30000,'{"hold_reason":"payment_overdue_60d"}'::jsonb),
  ('ACC-00029', 'Edinburgh Whisky Distillery',          'EWD',           'Food & Bev',  'GB', 'smb',           22000000,   95, 'active',   38000, '{}'::jsonb),
  ('ACC-00030', 'Kuala Lumpur Solar Industries',        'KLSI',          'Energy',      'MY', 'mid_market',    44000000,  210, 'active',   60000, '{}'::jsonb),
  ('ACC-00031', 'Munich Aerospace Components GmbH',     'MAC',           'Aerospace',   'DE', 'enterprise',   780000000, 2050, 'active',  220000, '{}'::jsonb),
  ('ACC-00032', 'Cape Town Brewery Pty Ltd',            'CTB',           'Food & Bev',  'ZA', 'smb',           11000000,   68, 'active',   25000, '{}'::jsonb),
  ('ACC-00033', 'Lisbon Cork Manufacturing S.A.',       'Lisbon Cork',   'Manufacturing','PT', 'smb',            9500000,   72, 'active',   22000, '{}'::jsonb),
  ('ACC-00034', 'Anchorage Marine Outfitters Inc.',     'AMO',           'Marine',      'US', 'smb',            7800000,   45, 'active',   20000, '{}'::jsonb),
  ('ACC-00035', 'Bangkok Plastics Industries',          'BPI',           'Plastics',    'TH', 'mid_market',    62000000,  290, 'active',   72000, '{}'::jsonb),
  ('ACC-00036', 'Reykjavik Geothermal Equipment',       'RGE',           'Energy',      'IS', 'smb',           18500000,   85, 'active',   35000, '{}'::jsonb),
  ('ACC-00037', 'Toronto Bakery Equipment Co.',         'TBE',           'Food & Bev',  'CA', 'smb',           14500000,   90, 'active',   30000, '{}'::jsonb),
  ('ACC-00038', 'Marseille Chemical Processing',        'MCP',           'Chemicals',   'FR', 'mid_market',    96000000,  480, 'active',  100000, '{}'::jsonb),
  ('ACC-00039', 'Dublin Pharma Manufacturing',          'DPM',           'Pharma',      'IE', 'enterprise',   560000000, 1280, 'active',  180000, '{}'::jsonb),
  ('ACC-00040', 'Wellington Wind Energy NZ',            'WWE',           'Energy',      'NZ', 'smb',           19500000,  100, 'lead',         0, '{}'::jsonb)
ON CONFLICT (account_number) DO NOTHING;

\echo '== Seeding sales.contacts =='

-- 1-3 contacts per customer; one primary per account.
INSERT INTO sales.contacts (customer_id, first_name, last_name, email, phone, job_title, is_primary, opted_in) VALUES
  (1,  'Margaret', 'Holloway',  'margaret.holloway@pnr.example',     '+1-206-555-0011', 'Director of Procurement', true,  true),
  (1,  'Steven',   'Park',      'steven.park@pnr.example',           '+1-206-555-0012', 'VP Operations',           false, true),
  (2,  'Donna',    'Schroeder', 'donna.schroeder@mgs.example',       '+1-312-555-0014', 'CFO',                     true,  true),
  (3,  'Oliver',   'Knight',    'oliver.knight@bayswater.example',   '+44-20-7946-0023','Head of Production',      true,  true),
  (3,  'Alice',    'Martin',    'alice.martin@bayswater.example',    '+44-20-7946-0024','Operations Manager',      false, false),
  (4,  'Erik',     'Lundberg',  'erik.lundberg@nordicmarine.example','+46-31-555-0029', 'Procurement Lead',        true,  true),
  (5,  'Carmen',   'Ramirez',   'carmen.ramirez@ramirez.example',    '+52-55-1234-5678','CEO',                     true,  true),
  (6,  'Hiroshi',  'Tanaka',    'hiroshi.tanaka@tpi.example',        '+81-3-5550-0042', 'VP Engineering',          true,  true),
  (7,  'Brendan',  'Murphy',    'brendan.murphy@brislogistics.example','+61-7-5550-0051','Operations Director',    true,  true),
  (8,  'Adekunle', 'Adeleke',   'adekunle.adeleke@lih.example',      '+234-1-555-0064', 'Procurement Manager',     true,  true),
  (9,  'Hamish',   'McGregor',  'hamish.mcgregor@highlands.example', '+44-1463-555010', 'Master Distiller',        true,  true),
  (10, 'Patricia', 'Goldstein', 'patricia.goldstein@gbhn.example',   '+1-617-555-0078', 'Facilities Director',     true,  true),
  (11, 'Vikram',   'Patel',     'vikram.patel@ps-mfg.example',       '+91-22-5550-0083','Owner',                   true,  true),
  (12, 'Sarah',    'Atkinson',  'sarah.atkinson@atlasfoods.example', '+61-2-5550-0091', 'Procurement Lead',        true,  true),
  (13, 'Giuseppe', 'Bianchi',   'giuseppe.bianchi@mooc.example',     '+39-091-5550-019','Production Manager',      true,  true),
  (14, 'David',    'Chen',      'david.chen@tpml.example',           '+1-416-555-0102', 'Lab Director',            true,  true),
  (15, 'Luiz',     'Silva',     'luiz.silva@rjsw.example',           '+55-21-5550-0114','Plant Manager',           true,  true),
  (16, 'Tshepo',   'Molefe',    'tshepo.molefe@jmsc.example',        '+27-11-5550-0125','Procurement Director',    true,  true),
  (17, 'Klaus',    'Schmidt',   'klaus.schmidt@btm.example',         '+49-30-5550-0133','Head of Manufacturing',   true,  true),
  (18, 'Min-jun',  'Kim',       'minjun.kim@sci.example',            '+82-2-5550-0144', 'Procurement VP',          true,  true),
  (19, 'Ilona',    'Hakkinen',  'ilona.hakkinen@helsinkimaritime.example','+358-9-5550-016','Operations Manager',  true,  true),
  (20, 'Ravi',     'Shankar',   'ravi.shankar@spe.example',          '+65-6555-0167',  'CEO',                     true,  true),
  (21, 'Janet',    'Albright',  'janet.albright@necr.example',       '+1-617-555-0178','Owner',                   true,  true),
  (22, 'Khalid',   'Al-Maktoum','khalid.almaktoum@dic.example',      '+971-4-555-0189','Operations Director',     true,  true),
  (23, 'Nour',     'Hassan',    'nour.hassan@cpm.example',           '+20-2-5550-0193','Production Manager',      true,  true),
  (24, 'Robert',   'Lacroix',   'robert.lacroix@vms.example',        '+1-604-555-0204','Owner',                   true,  true),
  (25, 'Wei-Ling', 'Chen',      'weiling.chen@sir.example',          '+86-21-5550-0215','Procurement Director',   true,  true),
  (26, 'Anand',    'Joshi',     'anand.joshi@mhe.example',           '+91-22-5550-0226','Plant Manager',          true,  true),
  (27, 'Magnus',   'Olsen',     'magnus.olsen@ohm.example',          '+47-22-555-0237', 'Maintenance Lead',        true,  true),
  (28, 'Lucia',    'Sanchez',   'lucia.sanchez@babg.example',        '+54-11-5550-0248','CFO',                     true,  false),
  (29, 'Fiona',    'MacLeod',   'fiona.macleod@ewd.example',         '+44-131-555-0259','Operations Manager',      true,  true),
  (30, 'Aisyah',   'Lim',       'aisyah.lim@klsi.example',           '+60-3-5550-0263', 'Procurement Lead',        true,  true),
  (31, 'Stefan',   'Hofmann',   'stefan.hofmann@mac.example',        '+49-89-5550-0274','Director of Sourcing',    true,  true),
  (32, 'Themba',   'Ndlovu',    'themba.ndlovu@ctb.example',         '+27-21-5550-0285','Master Brewer',           true,  true),
  (33, 'Inês',     'Pereira',   'ines.pereira@lisboncork.example',   '+351-21-555-0294','Operations Manager',      true,  true),
  (34, 'Sarah',    'Andrews',   'sarah.andrews@amo.example',         '+1-907-555-0306', 'Owner',                   true,  true),
  (35, 'Niran',    'Suriyachai','niran.suriyachai@bpi.example',      '+66-2-5550-0317', 'Plant Manager',           true,  true),
  (36, 'Bjarni',   'Gunnarsson','bjarni.gunnarsson@rge.example',     '+354-555-0328',   'Procurement Lead',        true,  true),
  (37, 'Marie',    'Tremblay',  'marie.tremblay@tbe.example',        '+1-416-555-0339', 'Owner',                   true,  true),
  (38, 'Thierry',  'Lefebvre',  'thierry.lefebvre@mcp.example',      '+33-4-9155-0341', 'Procurement Director',    true,  true),
  (39, 'Aoife',    'Ryan',      'aoife.ryan@dpm.example',            '+353-1-555-0352', 'Manufacturing Director',  true,  true)
ON CONFLICT (customer_id, email) DO NOTHING;

\echo '== Seeding sales.opportunities =='

INSERT INTO sales.opportunities (customer_id, owner_id, name, stage, amount, probability_pct, expected_close, actual_close, loss_reason) VALUES
  ( 1, 41, 'PNR Refinery Mixer Refresh — Q3',         'negotiation',  185000.00, 70, '2026-08-15', NULL, NULL),
  ( 2, 41, 'MGS Conveyor Expansion',                  'won',           94000.00,100, '2026-03-22', '2026-03-20', NULL),
  ( 3, 43, 'Bayswater Annual Maintenance Renewal',    'qualified',     27200.00, 60, '2026-06-30', NULL, NULL),
  ( 4, 43, 'Nordic Marine Pump Replacement',          'proposal',      48000.00, 50, '2026-07-15', NULL, NULL),
  ( 5, 42, 'Ramirez Production Line — Phase 1',       'won',          265000.00,100, '2026-02-28', '2026-02-26', NULL),
  ( 6, 46, 'TPI New Cleanroom Mixers',                'negotiation',  370000.00, 75, '2026-09-30', NULL, NULL),
  ( 7, 47, 'Brisbane Logistics Conveyor Upgrade',     'qualified',     86000.00, 40, '2026-08-04', NULL, NULL),
  ( 8, 44, 'LIH Industrial Refit',                    'won',          142000.00,100, '2026-01-19', '2026-01-15', NULL),
  ( 9, 43, 'Highlands Mash Tun + Service',            'proposal',      31500.00, 55, '2026-06-10', NULL, NULL),
  (10, 41, 'GBHN Sterilization Equipment',            'lost',          92000.00,  0, '2026-04-12', '2026-04-10', 'Lost to incumbent vendor on price'),
  (11, 47, 'P&S Hydraulic Press',                     'won',           7700.00, 100, '2026-03-08', '2026-03-04', NULL),
  (12, 47, 'Atlas Foods Filtration Renewal',          'won',           48000.00,100, '2026-04-01', '2026-03-30', NULL),
  (13, 45, 'MOOC Bottling Line Service',              'qualified',     14500.00, 30, '2026-09-20', NULL, NULL),
  (14, 41, 'TPML Lab Equipment Refresh',              'proposal',      62000.00, 60, '2026-07-22', NULL, NULL),
  (15, 42, 'RJSW Steel Press Maintenance',            'won',          120000.00,100, '2026-02-14', '2026-02-12', NULL),
  (16, 44, 'JMSC Mine Pump Refit',                    'qualified',     78000.00, 35, '2026-10-05', NULL, NULL),
  (17, 43, 'BTM Cleanroom Conveyors — Phase 2',       'negotiation',  240000.00, 80, '2026-08-25', NULL, NULL),
  (18, 46, 'SCI Robotics Integration',                'proposal',     180000.00, 50, '2026-09-15', NULL, NULL),
  (19, 43, 'Helsinki Maritime — 24x7 Maintenance',    'won',           34000.00,100, '2026-04-05', '2026-04-04', NULL),
  (20, 47, 'SPE Container Handling Upgrade',          'negotiation',  410000.00, 65, '2026-11-30', NULL, NULL),
  (21, 41, 'NECR Coffee Roaster Maintenance',         'won',           4800.00, 100, '2026-03-15', '2026-03-12', NULL),
  (22, 44, 'DIC Industrial Vacuum Systems',           'lost',          52000.00,  0, '2026-02-28', '2026-02-26', 'Customer chose to delay'),
  (23, 44, 'CPM Sterile Mixer Set',                   'won',          165000.00,100, '2026-01-25', '2026-01-22', NULL),
  (24, 41, 'VMS Boat Engine Overhaul Kit',            'qualified',     12500.00, 25, '2026-08-12', NULL, NULL),
  (25, 46, 'SIR Robot Arm Components',                'proposal',     280000.00, 55, '2026-10-25', NULL, NULL),
  (26, 47, 'MHE Hydraulic Components Bulk',           'won',           94000.00,100, '2026-04-12', '2026-04-10', NULL),
  (27, 43, 'OHM Turbine Maintenance Kit',             'won',           58000.00,100, '2026-03-30', '2026-03-28', NULL),
  (28, 42, 'BABG Bottling Line Spare Parts',          'lost',          24000.00,  0, '2026-02-15', '2026-02-12', 'Account suspended for non-payment'),
  (29, 43, 'EWD Stillhouse Filtration',               'won',           19500.00,100, '2026-04-18', '2026-04-15', NULL),
  (30, 47, 'KLSI Solar Cleaning Equipment',           'qualified',     46000.00, 40, '2026-07-30', NULL, NULL),
  (31, 43, 'MAC Aerospace Press Refresh',             'proposal',     220000.00, 50, '2026-09-08', NULL, NULL),
  (32, 44, 'CTB Brewing Vessel Maintenance',          'qualified',      8200.00, 30, '2026-08-20', NULL, NULL),
  (33, 45, 'Lisbon Cork Conveyor Spare Parts',        'won',            6400.00,100, '2026-04-25', '2026-04-22', NULL),
  (34, 41, 'AMO Marine Service Plan',                 'qualified',     14000.00, 35, '2026-09-05', NULL, NULL),
  (35, 47, 'BPI Plastic Press Maintenance',           'won',           42000.00,100, '2026-03-18', '2026-03-15', NULL),
  (36, 43, 'RGE Geothermal Pump Set',                 'proposal',      78000.00, 60, '2026-08-28', NULL, NULL),
  (37, 41, 'TBE Bakery Equipment Refresh',            'won',           28500.00,100, '2026-04-08', '2026-04-04', NULL),
  (38, 43, 'Marseille Chemical Mixer Maintenance',    'negotiation',  118000.00, 70, '2026-08-10', NULL, NULL),
  (39, 43, 'DPM Pharma Cleanroom Pumps',              'won',          235000.00,100, '2026-02-22', '2026-02-20', NULL),
  (40, 41, 'WWE Wind Turbine Components — Initial',   'prospect',      42000.00, 15, '2026-12-15', NULL, NULL)
ON CONFLICT DO NOTHING;

\echo '== Seeding sales.orders + sales.order_items =='

-- Generate orders from each WON opportunity. Order numbers follow SO-2026-NNNNNN.
-- Each order has 1-3 line items.

INSERT INTO sales.orders (order_number, customer_id, opportunity_id, ordered_at, status, shipping_address, billing_address, currency, notes) VALUES
  ('SO-2026-000001',  2,  2, '2026-03-21 14:32:00+00', 'delivered', '{"street":"4400 W Industrial Blvd","city":"Chicago","state":"IL","zip":"60604"}'::jsonb, '{"street":"4400 W Industrial Blvd","city":"Chicago","state":"IL","zip":"60604"}'::jsonb,'USD','Net-30'),
  ('SO-2026-000002',  5,  5, '2026-02-27 10:14:00+00', 'delivered', '{"street":"Av. Industrial 4500","city":"Monterrey","country":"MX"}'::jsonb,            '{"street":"Av. Industrial 4500","city":"Monterrey","country":"MX"}'::jsonb,           'USD','Phase 1 — install + spares'),
  ('SO-2026-000003',  8,  8, '2026-01-18 09:55:00+00', 'delivered', '{"street":"Plot 14 Industrial Estate","city":"Lagos","country":"NG"}'::jsonb,         '{"street":"Plot 14 Industrial Estate","city":"Lagos","country":"NG"}'::jsonb,        'USD',NULL),
  ('SO-2026-000004', 11, 11, '2026-03-05 11:22:00+00', 'shipped',   '{"street":"42 MIDC Phase 2","city":"Mumbai","country":"IN"}'::jsonb,                  '{"street":"42 MIDC Phase 2","city":"Mumbai","country":"IN"}'::jsonb,                  'USD',NULL),
  ('SO-2026-000005', 12, 12, '2026-04-02 12:48:00+00', 'shipped',   '{"street":"45 Botany Rd","city":"Sydney","country":"AU"}'::jsonb,                    '{"street":"45 Botany Rd","city":"Sydney","country":"AU"}'::jsonb,                    'USD','Recurring — auto-renewed'),
  ('SO-2026-000006', 15, 15, '2026-02-13 15:18:00+00', 'delivered', '{"street":"Av. Brasil 1500","city":"Rio de Janeiro","country":"BR"}'::jsonb,         '{"street":"Av. Brasil 1500","city":"Rio de Janeiro","country":"BR"}'::jsonb,         'USD',NULL),
  ('SO-2026-000007', 19, 19, '2026-04-05 09:33:00+00', 'delivered', '{"street":"Lonnrotinkatu 12","city":"Helsinki","country":"FI"}'::jsonb,             '{"street":"Lonnrotinkatu 12","city":"Helsinki","country":"FI"}'::jsonb,             'EUR','Service plan — 12 months'),
  ('SO-2026-000008', 21, 21, '2026-03-13 11:45:00+00', 'delivered', '{"street":"50 Prospect St","city":"Boston","state":"MA","zip":"02118"}'::jsonb,    '{"street":"50 Prospect St","city":"Boston","state":"MA","zip":"02118"}'::jsonb,    'USD',NULL),
  ('SO-2026-000009', 23, 23, '2026-01-23 14:02:00+00', 'delivered', '{"street":"Industrial Zone Blk 4","city":"Cairo","country":"EG"}'::jsonb,           '{"street":"Industrial Zone Blk 4","city":"Cairo","country":"EG"}'::jsonb,           'USD',NULL),
  ('SO-2026-000010', 26, 26, '2026-04-12 13:24:00+00', 'shipped',   '{"street":"42 MIDC Phase 2","city":"Mumbai","country":"IN"}'::jsonb,                '{"street":"42 MIDC Phase 2","city":"Mumbai","country":"IN"}'::jsonb,                'USD',NULL),
  ('SO-2026-000011', 27, 27, '2026-03-29 10:08:00+00', 'delivered', '{"street":"Sjolyst Plass 3","city":"Oslo","country":"NO"}'::jsonb,                  '{"street":"Sjolyst Plass 3","city":"Oslo","country":"NO"}'::jsonb,                  'EUR',NULL),
  ('SO-2026-000012', 29, 29, '2026-04-16 15:55:00+00', 'shipped',   '{"street":"24 Royal Mile","city":"Edinburgh","country":"GB"}'::jsonb,               '{"street":"24 Royal Mile","city":"Edinburgh","country":"GB"}'::jsonb,               'GBP',NULL),
  ('SO-2026-000013', 33, 33, '2026-04-23 11:11:00+00', 'shipped',   '{"street":"Rua da Cortica 88","city":"Lisbon","country":"PT"}'::jsonb,              '{"street":"Rua da Cortica 88","city":"Lisbon","country":"PT"}'::jsonb,              'EUR',NULL),
  ('SO-2026-000014', 35, 35, '2026-03-19 12:38:00+00', 'delivered', '{"street":"Bang Pa-In Industrial","city":"Bangkok","country":"TH"}'::jsonb,         '{"street":"Bang Pa-In Industrial","city":"Bangkok","country":"TH"}'::jsonb,         'USD',NULL),
  ('SO-2026-000015', 37, 37, '2026-04-09 10:17:00+00', 'shipped',   '{"street":"180 King St E","city":"Toronto","country":"CA"}'::jsonb,                 '{"street":"180 King St E","city":"Toronto","country":"CA"}'::jsonb,                 'CAD',NULL),
  ('SO-2026-000016', 39, 39, '2026-02-21 14:50:00+00', 'delivered', '{"street":"45 Belfield Rd","city":"Dublin","country":"IE"}'::jsonb,                 '{"street":"45 Belfield Rd","city":"Dublin","country":"IE"}'::jsonb,                 'EUR','Annual maintenance bundled'),
  -- Some open / confirmed orders
  ('SO-2026-000017',  3, NULL,'2026-04-29 09:21:00+00', 'confirmed', '{"street":"122 Bayswater Rd","city":"London","country":"GB"}'::jsonb,             '{"street":"122 Bayswater Rd","city":"London","country":"GB"}'::jsonb,             'GBP','Walk-up — repeat customer'),
  ('SO-2026-000018', 14, NULL,'2026-04-30 11:37:00+00', 'open',      '{"street":"205 King St W","city":"Toronto","country":"CA"}'::jsonb,                '{"street":"205 King St W","city":"Toronto","country":"CA"}'::jsonb,                'CAD',NULL),
  ('SO-2026-000019', 36, NULL,'2026-05-02 13:02:00+00', 'open',      '{"street":"Hofdabakki 9","city":"Reykjavik","country":"IS"}'::jsonb,               '{"street":"Hofdabakki 9","city":"Reykjavik","country":"IS"}'::jsonb,               'EUR',NULL),
  ('SO-2026-000020', 17, NULL,'2026-05-05 16:18:00+00', 'cancelled', '{"street":"Friedrichstrasse 88","city":"Berlin","country":"DE"}'::jsonb,           '{"street":"Friedrichstrasse 88","city":"Berlin","country":"DE"}'::jsonb,           'EUR','Cust requested cancel — duplicate PO')
ON CONFLICT (order_number) DO NOTHING;

-- Order items. line totals will be computed automatically (generated column),
-- and the trigger will refresh orders.total_amount.
INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price, discount_pct) VALUES
  -- SO-2026-000001 (MGS conveyor expansion: 6 conveyor belts + spares)
  (1, 2, 6, 7200.00, 5.0),
  (1, 7, 12, 340.00, 0.0),
  -- SO-2026-000002 (Ramirez phase 1: mixer + service)
  (2, 1, 1, 18500.00, 0.0),
  (2, 19, 4, 450.00, 0.0),
  (2, 20, 1, 1200.00, 0.0),
  -- SO-2026-000003 (LIH industrial refit: pumps + presses)
  (3, 4, 4, 3850.00, 5.0),
  (3, 10, 8, 640.00, 0.0),
  (3, 19, 6, 450.00, 0.0),
  -- SO-2026-000004 (P&S hydraulic press)
  (4, 4, 2, 3850.00, 0.0),
  -- SO-2026-000005 (Atlas filtration renewal: maintenance)
  (5, 21, 2, 2400.00, 0.0),
  (5, 22, 1, 6800.00, 0.0),
  -- SO-2026-000006 (RJSW steel press maintenance: tier 2 plan)
  (6, 22, 1, 6800.00, 0.0),
  (6, 4, 12, 3850.00, 5.0),
  (6, 19, 8, 450.00, 0.0),
  -- SO-2026-000007 (Helsinki maritime 24x7)
  (7, 22, 1, 6800.00, 0.0),
  (7, 23, 4, 950.00, 0.0),
  -- SO-2026-000008 (NECR coffee roaster: maintenance plan)
  (8, 21, 2, 2400.00, 0.0),
  -- SO-2026-000009 (CPM sterile mixer set)
  (9, 1, 6, 18500.00, 5.0),
  (9, 9, 8, 920.00, 0.0),
  (9, 19, 4, 450.00, 0.0),
  -- SO-2026-000010 (MHE hydraulic bulk)
  (10, 4, 18, 3850.00, 8.0),
  (10, 8, 24, 580.00, 0.0),
  -- SO-2026-000011 (OHM turbine kit)
  (11, 5, 12, 1450.00, 0.0),
  (11, 21, 2, 2400.00, 0.0),
  -- SO-2026-000012 (EWD stillhouse filtration)
  (12, 6, 6, 2100.00, 0.0),
  (12, 19, 4, 450.00, 0.0),
  -- SO-2026-000013 (Lisbon Cork conveyor spares)
  (13, 7, 12, 340.00, 5.0),
  (13, 8, 4, 580.00, 0.0),
  -- SO-2026-000014 (BPI plastic press maintenance)
  (14, 22, 1, 6800.00, 0.0),
  (14, 21, 2, 2400.00, 0.0),
  (14, 4, 4, 3850.00, 0.0),
  -- SO-2026-000015 (TBE bakery equipment)
  (15, 1, 1, 18500.00, 0.0),
  (15, 6, 2, 2100.00, 0.0),
  (15, 19, 2, 450.00, 0.0),
  (15, 24, 1, 1750.00, 0.0),
  -- SO-2026-000016 (DPM pharma pumps)
  (16, 10, 24, 640.00, 0.0),
  (16, 6, 8, 2100.00, 0.0),
  (16, 21, 2, 2400.00, 0.0),
  (16, 22, 1, 6800.00, 0.0),
  -- SO-2026-000017 (Bayswater confirmed)
  (17, 6, 2, 2100.00, 0.0),
  (17, 9, 1, 920.00, 0.0),
  -- SO-2026-000018 (TPML open)
  (18, 5, 4, 1450.00, 0.0),
  (18, 23, 1, 950.00, 0.0),
  -- SO-2026-000019 (RGE open)
  (19, 10, 8, 640.00, 0.0),
  (19, 6, 4, 2100.00, 0.0),
  -- SO-2026-000020 (BTM cancelled)
  (20, 2, 4, 7200.00, 0.0)
ON CONFLICT (order_id, product_id) DO NOTHING;

\echo '== Seeding sales.invoices =='

-- One invoice per delivered/shipped order (skip cancelled + open).
-- Status mostly 'paid'; 2 'overdue' for demo.
INSERT INTO sales.invoices (invoice_number, order_id, issued_at, due_at, status, subtotal, tax_amount, total_amount, paid_amount, paid_at, created_by) VALUES
  ('INV-2026-00001',  1, '2026-03-22', '2026-04-21', 'paid',     45120.00, 4060.80, 49180.80, 49180.80, '2026-04-15', 65),
  ('INV-2026-00002',  2, '2026-02-28', '2026-03-30', 'paid',     22100.00, 1989.00, 24089.00, 24089.00, '2026-03-22', 65),
  ('INV-2026-00003',  3, '2026-01-20', '2026-02-19', 'paid',     25910.00, 2331.90, 28241.90, 28241.90, '2026-02-15', 66),
  ('INV-2026-00004',  4, '2026-03-08', '2026-04-07', 'paid',      7700.00,  693.00,  8393.00,  8393.00, '2026-04-04', 66),
  ('INV-2026-00005',  5, '2026-04-02', '2026-05-02', 'sent',     11600.00, 1044.00, 12644.00,     0.00, NULL,         67),
  ('INV-2026-00006',  6, '2026-02-14', '2026-03-16', 'paid',     56400.00, 5076.00, 61476.00, 61476.00, '2026-03-10', 67),
  ('INV-2026-00007',  7, '2026-04-06', '2026-05-06', 'sent',     10600.00,  954.00, 11554.00,     0.00, NULL,         68),
  ('INV-2026-00008',  8, '2026-03-14', '2026-04-13', 'paid',      4800.00,  432.00,  5232.00,  5232.00, '2026-04-10', 68),
  ('INV-2026-00009',  9, '2026-01-25', '2026-02-24', 'paid',    119900.00,10791.00,130691.00,130691.00, '2026-02-19', 65),
  ('INV-2026-00010', 10, '2026-04-12', '2026-05-12', 'sent',     77620.00, 6985.80, 84605.80,     0.00, NULL,         65),
  ('INV-2026-00011', 11, '2026-03-30', '2026-04-29', 'overdue',  22200.00, 1998.00, 24198.00,     0.00, NULL,         66),
  ('INV-2026-00012', 12, '2026-04-18', '2026-05-18', 'sent',     14400.00, 1296.00, 15696.00,     0.00, NULL,         66),
  ('INV-2026-00013', 13, '2026-04-23', '2026-05-23', 'sent',      6196.00,  557.64,  6753.64,     0.00, NULL,         67),
  ('INV-2026-00014', 14, '2026-03-19', '2026-04-18', 'overdue',  27000.00, 2430.00, 29430.00, 10000.00, NULL,         67),
  ('INV-2026-00015', 15, '2026-04-09', '2026-05-09', 'sent',     24450.00, 2200.50, 26650.50,     0.00, NULL,         68),
  ('INV-2026-00016', 16, '2026-02-22', '2026-03-24', 'paid',     45720.00, 4114.80, 49834.80, 49834.80, '2026-03-18', 68)
ON CONFLICT (invoice_number) DO NOTHING;

\echo '== Refreshing materialized views =='
REFRESH MATERIALIZED VIEW sales.mv_monthly_revenue_by_category;
REFRESH MATERIALIZED VIEW sales.mv_customer_lifetime_value;

\echo '== Sales seed: 25 products, 40 customers, 41 contacts, 40 opps, 20 orders, ~50 line items, 16 invoices =='
