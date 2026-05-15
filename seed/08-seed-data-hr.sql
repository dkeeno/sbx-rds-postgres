-- =============================================================================
-- 08-seed-data-hr.sql — fictional enterprise HR data
-- =============================================================================
--
-- Company: Helix Atlas Industrial Ltd ("HAIL"). Headcount ~80, 6 departments,
-- mix of management + IC roles. Names are realistic-but-invented (no real
-- people). All ids deterministic via INSERT ... SELECT for repeatable tests.
--
-- Volume:
--   departments      8
--   positions       18
--   employees       80 (across 6 departments)
--   payroll        ~80 (one current month per employee)
--   leave_requests ~25 mixed statuses
--
-- Note: tg_a_*_audit triggers will fire on every INSERT — check
-- audit.change_log after this file runs to see ~190 rows accumulated.

\echo '== Seeding hr.departments =='

INSERT INTO hr.departments (code, name, cost_center, parent_id, budget_annual) VALUES
  ('EXEC', 'Executive Office',     'CC-1000', NULL, 1500000.00),
  ('FIN',  'Finance',              'CC-2000', NULL,  900000.00),
  ('HR',   'People & Culture',     'CC-3000', NULL,  600000.00),
  ('ENG',  'Engineering',          'CC-4000', NULL, 3500000.00),
  ('OPS',  'Operations',           'CC-5000', NULL, 2200000.00),
  ('SAL',  'Sales',                'CC-6000', NULL, 1800000.00),
  ('MKT',  'Marketing',            'CC-7000', NULL,  700000.00),
  ('SUP',  'Customer Support',     'CC-8000', NULL,  500000.00)
ON CONFLICT (code) DO NOTHING;

\echo '== Seeding hr.positions =='

INSERT INTO hr.positions (title, job_family, level, salary_min, salary_max, is_management) VALUES
  ('CEO',                     'Executive',   10, 350000, 500000, true),
  ('CFO',                     'Executive',    9, 280000, 400000, true),
  ('CTO',                     'Executive',    9, 280000, 400000, true),
  ('VP Engineering',          'Engineering',  8, 220000, 320000, true),
  ('Engineering Manager',     'Engineering',  6, 160000, 220000, true),
  ('Senior Software Engineer','Engineering',  5, 130000, 180000, false),
  ('Software Engineer',       'Engineering',  4,  90000, 130000, false),
  ('Junior Software Engineer','Engineering',  3,  65000,  95000, false),
  ('Director of Sales',       'Sales',        7, 180000, 260000, true),
  ('Account Executive',       'Sales',        5, 100000, 160000, false),
  ('Sales Development Rep',   'Sales',        3,  55000,  85000, false),
  ('Operations Manager',      'Operations',   6, 110000, 160000, true),
  ('Operations Specialist',   'Operations',   4,  65000,  95000, false),
  ('Finance Manager',         'Finance',      6, 120000, 170000, true),
  ('Senior Accountant',       'Finance',      5,  90000, 130000, false),
  ('Accountant',              'Finance',      3,  60000,  85000, false),
  ('HR Business Partner',     'HR',           5,  85000, 125000, false),
  ('Customer Support Lead',   'Support',      4,  60000,  90000, true)
ON CONFLICT DO NOTHING;

\echo '== Seeding hr.employees (80 people) =='

-- Executives + dept leads first (so they exist as managers for the rest).
INSERT INTO hr.employees (employee_number, first_name, last_name, email, phone, date_of_birth, hired_at, department_id, position_id, manager_id, base_salary, metadata) VALUES
  ('E000001', 'Marcus',   'Caldwell',     'marcus.caldwell@hail.example',     '+1-415-555-0101', '1968-03-22', '2014-01-06', (SELECT id FROM hr.departments WHERE code='EXEC'), (SELECT id FROM hr.positions WHERE title='CEO'),                NULL, 425000.00, '{"location":"San Francisco","timezone":"PST"}'::jsonb),
  ('E000002', 'Priya',    'Ramaswamy',    'priya.ramaswamy@hail.example',     '+1-415-555-0102', '1972-07-11', '2015-04-13', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='CFO'),                1, 340000.00, '{"location":"San Francisco"}'::jsonb),
  ('E000003', 'Daniel',   'O''Brien',     'daniel.obrien@hail.example',       '+1-415-555-0103', '1975-11-30', '2015-06-01', (SELECT id FROM hr.departments WHERE code='ENG'),  (SELECT id FROM hr.positions WHERE title='CTO'),                1, 355000.00, '{"location":"San Francisco","github":"dobrien"}'::jsonb),
  ('E000004', 'Sofia',    'Mendez',       'sofia.mendez@hail.example',        '+1-415-555-0104', '1980-02-14', '2016-09-12', (SELECT id FROM hr.departments WHERE code='ENG'),  (SELECT id FROM hr.positions WHERE title='VP Engineering'),     3, 265000.00, '{"location":"Austin","github":"smendez"}'::jsonb),
  ('E000005', 'Wei',      'Zhang',        'wei.zhang@hail.example',           '+1-415-555-0105', '1983-05-20', '2017-02-20', (SELECT id FROM hr.departments WHERE code='SAL'),  (SELECT id FROM hr.positions WHERE title='Director of Sales'),  1, 215000.00, '{"location":"New York"}'::jsonb),
  ('E000006', 'Aisha',    'Khan',         'aisha.khan@hail.example',          '+1-415-555-0106', '1978-09-04', '2017-08-14', (SELECT id FROM hr.departments WHERE code='HR'),   (SELECT id FROM hr.positions WHERE title='HR Business Partner'),1, 105000.00, '{"location":"San Francisco","languages":["en","ur","ar"]}'::jsonb),
  ('E000007', 'James',    'McCallister',  'james.mccallister@hail.example',   '+1-415-555-0107', '1976-12-18', '2018-01-22', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Manager'), 1, 142000.00, '{"location":"Chicago"}'::jsonb),
  ('E000008', 'Léa',      'Beaumont',     'lea.beaumont@hail.example',        '+1-415-555-0108', '1981-04-09', '2018-07-30', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Finance Manager'),    2, 148000.00, '{"location":"London"}'::jsonb),
  ('E000009', 'Olumide',  'Adebayo',      'olumide.adebayo@hail.example',     '+1-415-555-0109', '1985-06-25', '2019-03-04', (SELECT id FROM hr.departments WHERE code='ENG'),  (SELECT id FROM hr.positions WHERE title='Engineering Manager'),4, 195000.00, '{"location":"Lagos","github":"oadebayo"}'::jsonb),
  ('E000010', 'Hannah',   'Bergstrom',    'hannah.bergstrom@hail.example',    '+1-415-555-0110', '1986-08-13', '2019-05-15', (SELECT id FROM hr.departments WHERE code='ENG'),  (SELECT id FROM hr.positions WHERE title='Engineering Manager'),4, 198000.00, '{"location":"Stockholm","github":"hbergstrom"}'::jsonb)
ON CONFLICT (employee_number) DO NOTHING;

-- Engineering ICs (employees 11-40)
INSERT INTO hr.employees (employee_number, first_name, last_name, email, hired_at, department_id, position_id, manager_id, base_salary, metadata) VALUES
  ('E000011', 'Rohan',    'Patel',       'rohan.patel@hail.example',       '2020-01-13', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'),  9, 155000, '{"github":"rpatel"}'::jsonb),
  ('E000012', 'Maeve',    'O''Sullivan', 'maeve.osullivan@hail.example',   '2020-02-24', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'),  9, 162000, '{"github":"mosullivan"}'::jsonb),
  ('E000013', 'Ravi',     'Krishnamurthy','ravi.krishnamurthy@hail.example','2020-03-09', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 118000, '{"github":"rkrishna"}'::jsonb),
  ('E000014', 'Eleanor',  'Whitfield',   'eleanor.whitfield@hail.example', '2020-04-21', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 122000, '{"github":"ewhitfield"}'::jsonb),
  ('E000015', 'Tomasz',   'Kowalski',    'tomasz.kowalski@hail.example',   '2020-05-18', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 115000, '{"github":"tkowalski"}'::jsonb),
  ('E000016', 'Ananya',   'Iyer',        'ananya.iyer@hail.example',       '2020-08-03', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 110000, '{"github":"aiyer"}'::jsonb),
  ('E000017', 'Idris',    'Owusu',       'idris.owusu@hail.example',       '2021-01-11', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'),  9, 165000, '{"github":"iowusu"}'::jsonb),
  ('E000018', 'Yui',      'Nakamura',    'yui.nakamura@hail.example',      '2021-02-15', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 119000, '{"github":"ynakamura"}'::jsonb),
  ('E000019', 'Carlos',   'Vega',        'carlos.vega@hail.example',       '2021-04-05', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),  9,  82000, '{"github":"cvega"}'::jsonb),
  ('E000020', 'Naledi',   'Mokoena',     'naledi.mokoena@hail.example',    '2021-04-19', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'), 10,  78000, '{"github":"nmokoena"}'::jsonb),
  ('E000021', 'Henrik',   'Lindqvist',   'henrik.lindqvist@hail.example',  '2021-06-07', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 124000, '{}'::jsonb),
  ('E000022', 'Yara',     'Haddad',      'yara.haddad@hail.example',       '2021-07-12', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 121000, '{}'::jsonb),
  ('E000023', 'Fabian',   'Werner',      'fabian.werner@hail.example',     '2021-09-01', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'),  9, 158000, '{}'::jsonb),
  ('E000024', 'Elif',     'Yıldız',      'elif.yildiz@hail.example',       '2021-10-18', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'), 10,  80000, '{}'::jsonb),
  ('E000025', 'Mateus',   'Ferreira',    'mateus.ferreira@hail.example',   '2022-01-10', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 116000, '{}'::jsonb),
  ('E000026', 'Anastasia','Volkova',     'anastasia.volkova@hail.example', '2022-02-22', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'), 10, 168000, '{}'::jsonb),
  ('E000027', 'Bilal',    'Rashid',      'bilal.rashid@hail.example',      '2022-04-04', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 125000, '{}'::jsonb),
  ('E000028', 'Zoe',      'Papadakis',   'zoe.papadakis@hail.example',     '2022-05-16', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 117000, '{}'::jsonb),
  ('E000029', 'Tariq',    'Mahmoud',     'tariq.mahmoud@hail.example',     '2022-08-29', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),  9,  76000, '{}'::jsonb),
  ('E000030', 'Camila',   'Restrepo',    'camila.restrepo@hail.example',   '2022-10-04', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 113000, '{}'::jsonb),
  ('E000031', 'Niamh',    'Brennan',     'niamh.brennan@hail.example',     '2023-01-23', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),  9,  79000, '{}'::jsonb),
  ('E000032', 'Sergei',   'Petrov',      'sergei.petrov@hail.example',     '2023-03-13', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 120000, '{}'::jsonb),
  ('E000033', 'Beatriz',  'Carneiro',    'beatriz.carneiro@hail.example',  '2023-05-08', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 114000, '{}'::jsonb),
  ('E000034', 'Jin',      'Park',        'jin.park@hail.example',          '2023-07-17', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Senior Software Engineer'), 10, 161000, '{}'::jsonb),
  ('E000035', 'Sara',     'Andersson',   'sara.andersson@hail.example',    '2023-09-25', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),  9,  77000, '{}'::jsonb),
  ('E000036', 'Kwame',    'Asante',      'kwame.asante@hail.example',      '2024-01-08', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 112000, '{}'::jsonb),
  ('E000037', 'Lina',     'Hassan',      'lina.hassan@hail.example',       '2024-03-19', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),         9, 118000, '{}'::jsonb),
  ('E000038', 'Quentin',  'Dubois',      'quentin.dubois@hail.example',    '2024-06-04', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'), 10,  78000, '{}'::jsonb),
  ('E000039', 'Aaliyah',  'Robinson',    'aaliyah.robinson@hail.example',  '2024-08-12', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),  9,  80000, '{}'::jsonb),
  ('E000040', 'Diego',    'Rivera',      'diego.rivera@hail.example',      '2024-10-21', (SELECT id FROM hr.departments WHERE code='ENG'), (SELECT id FROM hr.positions WHERE title='Software Engineer'),        10, 115000, '{}'::jsonb)
ON CONFLICT (employee_number) DO NOTHING;

-- Sales (employees 41-55)
INSERT INTO hr.employees (employee_number, first_name, last_name, email, hired_at, department_id, position_id, manager_id, base_salary, metadata) VALUES
  ('E000041', 'Rebecca',   'Townsend',   'rebecca.townsend@hail.example',  '2019-09-04', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 145000, '{"region":"NAMER-East"}'::jsonb),
  ('E000042', 'Felipe',    'Gomes',      'felipe.gomes@hail.example',      '2020-04-13', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 138000, '{"region":"LATAM"}'::jsonb),
  ('E000043', 'Astrid',    'Holmberg',   'astrid.holmberg@hail.example',   '2020-09-21', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 142000, '{"region":"EMEA-North"}'::jsonb),
  ('E000044', 'Mohammed',  'Al-Faisal',  'mohammed.alfaisal@hail.example', '2021-03-08', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 135000, '{"region":"EMEA-MEA"}'::jsonb),
  ('E000045', 'Ines',      'Costa',      'ines.costa@hail.example',        '2021-08-23', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 128000, '{"region":"EMEA-South"}'::jsonb),
  ('E000046', 'Hiroshi',   'Tanaka',     'hiroshi.tanaka@hail.example',    '2022-01-31', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 132000, '{"region":"APAC-North"}'::jsonb),
  ('E000047', 'Charlotte', 'Burke',      'charlotte.burke@hail.example',   '2022-06-13', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 130000, '{"region":"APAC-South"}'::jsonb),
  ('E000048', 'Mauricio',  'Ortega',     'mauricio.ortega@hail.example',   '2022-11-07', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 126000, '{"region":"NAMER-West"}'::jsonb),
  ('E000049', 'Tobias',    'Schaefer',   'tobias.schaefer@hail.example',   '2023-02-20', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Sales Development Rep'), 5,  68000, '{}'::jsonb),
  ('E000050', 'Mei',       'Lin',        'mei.lin@hail.example',           '2023-04-17', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Sales Development Rep'), 5,  70000, '{}'::jsonb),
  ('E000051', 'Olusola',   'Bankole',    'olusola.bankole@hail.example',   '2023-09-25', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Sales Development Rep'), 5,  65000, '{}'::jsonb),
  ('E000052', 'Anna',      'Novak',      'anna.novak@hail.example',        '2024-02-12', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Sales Development Rep'), 5,  72000, '{}'::jsonb),
  ('E000053', 'Sebastian', 'Holtz',      'sebastian.holtz@hail.example',   '2024-05-06', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 122000, '{}'::jsonb),
  ('E000054', 'Layla',     'Ahmadi',     'layla.ahmadi@hail.example',      '2024-07-22', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Sales Development Rep'), 5,  68000, '{}'::jsonb),
  ('E000055', 'Edward',    'Pemberton',  'edward.pemberton@hail.example',  '2024-11-04', (SELECT id FROM hr.departments WHERE code='SAL'), (SELECT id FROM hr.positions WHERE title='Account Executive'),    5, 125000, '{}'::jsonb)
ON CONFLICT (employee_number) DO NOTHING;

-- Operations + Finance + HR + Support (employees 56-80)
INSERT INTO hr.employees (employee_number, first_name, last_name, email, hired_at, department_id, position_id, manager_id, base_salary, metadata) VALUES
  ('E000056', 'Roberto',   'De Luca',    'roberto.deluca@hail.example',    '2019-04-22', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  82000, '{}'::jsonb),
  ('E000057', 'Esther',    'Brockwell',  'esther.brockwell@hail.example',  '2020-07-14', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  79000, '{}'::jsonb),
  ('E000058', 'Hugo',      'Bernal',     'hugo.bernal@hail.example',       '2021-01-26', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  85000, '{}'::jsonb),
  ('E000059', 'Saoirse',   'Doherty',    'saoirse.doherty@hail.example',   '2021-09-13', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  78000, '{}'::jsonb),
  ('E000060', 'Mateo',     'Ramos',      'mateo.ramos@hail.example',       '2022-04-19', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  76000, '{}'::jsonb),
  ('E000061', 'Khadija',   'Sow',        'khadija.sow@hail.example',       '2023-08-07', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  80000, '{}'::jsonb),
  ('E000062', 'Inka',      'Rauhala',    'inka.rauhala@hail.example',      '2024-03-25', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  82000, '{}'::jsonb),
  ('E000063', 'Cyrus',     'Pourian',    'cyrus.pourian@hail.example',     '2019-11-04', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Senior Accountant'),     8, 105000, '{}'::jsonb),
  ('E000064', 'Linnea',    'Sjöberg',    'linnea.sjoberg@hail.example',    '2020-06-09', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Senior Accountant'),     8, 112000, '{}'::jsonb),
  ('E000065', 'Daud',      'Hussain',    'daud.hussain@hail.example',      '2021-05-12', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Accountant'),            8,  72000, '{}'::jsonb),
  ('E000066', 'Margot',    'Lefèvre',    'margot.lefevre@hail.example',    '2022-02-08', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Accountant'),            8,  74000, '{}'::jsonb),
  ('E000067', 'Antoine',   'Roux',       'antoine.roux@hail.example',      '2022-10-25', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Accountant'),            8,  70000, '{}'::jsonb),
  ('E000068', 'Hye-jin',   'Choi',       'hyejin.choi@hail.example',       '2023-12-04', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Accountant'),            8,  73000, '{}'::jsonb),
  ('E000069', 'Beth',      'Ashworth',   'beth.ashworth@hail.example',     '2018-11-12', (SELECT id FROM hr.departments WHERE code='HR'),   (SELECT id FROM hr.positions WHERE title='HR Business Partner'),   6, 102000, '{}'::jsonb),
  ('E000070', 'Marcellus', 'Williams',   'marcellus.williams@hail.example','2020-08-03', (SELECT id FROM hr.departments WHERE code='HR'),   (SELECT id FROM hr.positions WHERE title='HR Business Partner'),   6, 108000, '{}'::jsonb),
  ('E000071', 'Tatiana',   'Russo',      'tatiana.russo@hail.example',     '2022-03-17', (SELECT id FROM hr.departments WHERE code='HR'),   (SELECT id FROM hr.positions WHERE title='HR Business Partner'),   6,  98000, '{}'::jsonb),
  ('E000072', 'Adam',      'Kowalewski', 'adam.kowalewski@hail.example',   '2023-06-26', (SELECT id FROM hr.departments WHERE code='HR'),   (SELECT id FROM hr.positions WHERE title='HR Business Partner'),   6,  94000, '{}'::jsonb),
  ('E000073', 'Lakshmi',   'Subramanian','lakshmi.subramanian@hail.example','2019-10-15',(SELECT id FROM hr.departments WHERE code='SUP'), (SELECT id FROM hr.positions WHERE title='Customer Support Lead'),NULL, 84000, '{}'::jsonb),
  ('E000074', 'Pavel',     'Horák',      'pavel.horak@hail.example',       '2021-02-09', (SELECT id FROM hr.departments WHERE code='SUP'), (SELECT id FROM hr.positions WHERE title='Customer Support Lead'),73,  68000, '{}'::jsonb),
  ('E000075', 'Hala',      'Fakhouri',   'hala.fakhouri@hail.example',     '2022-07-14', (SELECT id FROM hr.departments WHERE code='SUP'), (SELECT id FROM hr.positions WHERE title='Customer Support Lead'),73,  65000, '{}'::jsonb),
  ('E000076', 'Brendan',   'McGrath',    'brendan.mcgrath@hail.example',   '2023-04-03', (SELECT id FROM hr.departments WHERE code='SUP'), (SELECT id FROM hr.positions WHERE title='Customer Support Lead'),73,  64000, '{}'::jsonb),
  ('E000077', 'Selma',     'Karlsson',   'selma.karlsson@hail.example',    '2024-01-29', (SELECT id FROM hr.departments WHERE code='SUP'), (SELECT id FROM hr.positions WHERE title='Customer Support Lead'),73,  66000, '{}'::jsonb),
  ('E000078', 'Andre',     'Petrov',     'andre.petrov@hail.example',      '2018-07-30', (SELECT id FROM hr.departments WHERE code='OPS'),  (SELECT id FROM hr.positions WHERE title='Operations Specialist'), 7,  88000, '{}'::jsonb),
  ('E000079', 'Olga',      'Petrenko',   'olga.petrenko@hail.example',     '2017-05-15', (SELECT id FROM hr.departments WHERE code='FIN'),  (SELECT id FROM hr.positions WHERE title='Senior Accountant'),     8, 118000, '{}'::jsonb),
  ('E000080', 'Connor',    'Walsh',      'connor.walsh@hail.example',      '2024-09-02', (SELECT id FROM hr.departments WHERE code='ENG'),  (SELECT id FROM hr.positions WHERE title='Junior Software Engineer'),9,  80000, '{}'::jsonb)
ON CONFLICT (employee_number) DO NOTHING;

\echo '== Backfilling departments.manager_id =='

UPDATE hr.departments SET manager_id = 1 WHERE code = 'EXEC';
UPDATE hr.departments SET manager_id = 2 WHERE code = 'FIN';
UPDATE hr.departments SET manager_id = 6 WHERE code = 'HR';
UPDATE hr.departments SET manager_id = 4 WHERE code = 'ENG';
UPDATE hr.departments SET manager_id = 7 WHERE code = 'OPS';
UPDATE hr.departments SET manager_id = 5 WHERE code = 'SAL';
UPDATE hr.departments SET manager_id = 73 WHERE code = 'SUP';

\echo '== Seeding hr.payroll (1 month per active employee) =='

-- Generate one payroll record covering 2026-04 for every active employee.
-- Tax = 22% of gross, pension = 5%, no other deductions.
INSERT INTO hr.payroll (employee_id, pay_period, gross_pay, taxes, pension, paid_at)
SELECT
  e.id,
  daterange('2026-04-01'::date, '2026-05-01'::date, '[)'),
  ROUND((e.base_salary / 12.0)::NUMERIC, 2),
  ROUND((e.base_salary / 12.0 * 0.22)::NUMERIC, 2),
  ROUND((e.base_salary / 12.0 * 0.05)::NUMERIC, 2),
  '2026-04-30'::date
FROM hr.employees e
WHERE e.deleted_at IS NULL AND e.terminated_at IS NULL
ON CONFLICT DO NOTHING;

\echo '== Seeding hr.leave_requests (mixed statuses) =='

INSERT INTO hr.leave_requests (employee_id, leave_type, period, status, approver_id, notes) VALUES
  (11, 'annual',     daterange('2026-06-15','2026-06-29','[)'), 'approved', 9,  'Family wedding'),
  (12, 'annual',     daterange('2026-07-06','2026-07-13','[)'), 'approved', 9,  'Vacation'),
  (13, 'sick',       daterange('2026-04-22','2026-04-25','[)'), 'approved', 9,  'Flu'),
  (14, 'parental',   daterange('2026-09-01','2026-12-01','[)'), 'pending',  9,  'Parental leave'),
  (15, 'annual',     daterange('2026-05-26','2026-05-31','[)'), 'approved', 10, 'Spring break'),
  (16, 'unpaid',     daterange('2026-08-04','2026-08-25','[)'), 'pending',  10, 'Personal travel'),
  (17, 'annual',     daterange('2026-12-22','2027-01-05','[)'), 'pending',  9,  'Christmas'),
  (18, 'sick',       daterange('2026-04-08','2026-04-09','[)'), 'approved', 10, ''),
  (19, 'annual',     daterange('2026-06-22','2026-06-26','[)'), 'rejected', 9,  'Sprint freeze'),
  (20, 'jury',       daterange('2026-05-04','2026-05-08','[)'), 'approved', 10, 'Civic duty'),
  (21, 'annual',     daterange('2026-07-13','2026-07-27','[)'), 'approved', 9,  'Honeymoon'),
  (22, 'sick',       daterange('2026-05-12','2026-05-13','[)'), 'approved', 10, ''),
  (41, 'annual',     daterange('2026-08-10','2026-08-21','[)'), 'pending',  5,  'Beach trip'),
  (42, 'annual',     daterange('2026-09-14','2026-09-25','[)'), 'pending',  5,  ''),
  (43, 'parental',   daterange('2026-11-01','2027-02-01','[)'), 'approved', 5,  'Parental leave'),
  (44, 'bereavement',daterange('2026-04-15','2026-04-19','[)'), 'approved', 5,  ''),
  (45, 'annual',     daterange('2026-07-20','2026-07-24','[)'), 'cancelled',5,  'Customer escalation'),
  (56, 'sick',       daterange('2026-04-29','2026-04-30','[)'), 'approved', 7,  ''),
  (57, 'annual',     daterange('2026-06-01','2026-06-08','[)'), 'approved', 7,  ''),
  (63, 'annual',     daterange('2026-12-15','2026-12-31','[)'), 'pending',  8,  'Year-end'),
  (64, 'sick',       daterange('2026-04-15','2026-04-16','[)'), 'approved', 8,  ''),
  (69, 'annual',     daterange('2026-08-04','2026-08-15','[)'), 'pending',  6,  ''),
  (73, 'annual',     daterange('2026-05-19','2026-05-23','[)'), 'approved', NULL,'Self-approved (lead)'),
  (75, 'sick',       daterange('2026-04-21','2026-04-23','[)'), 'approved', 73, ''),
  (80, 'annual',     daterange('2026-06-09','2026-06-13','[)'), 'pending',  9,  'Newest hire — needs OK')
ON CONFLICT DO NOTHING;

\echo '== HR seed: 8 departments, 18 positions, 80 employees, ~80 payroll rows, 25 leave requests =='
