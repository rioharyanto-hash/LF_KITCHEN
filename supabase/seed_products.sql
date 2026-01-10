-- LF Kitchen - Product Seed Data
-- Generated from PRICE LIST.xlsx

-- Clear existing products (optional - uncomment if you want to reset)
-- DELETE FROM products;

-- Insert Snack Box Items
INSERT INTO
    products (
        name,
        description,
        unit_price,
        special_price,
        category,
        stock_qty
    )
VALUES
    -- Snack Box Category
    (
        'Aarem-aarem',
        'Snack tradisional',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Makaroni Schotel',
        'Makaroni panggang dengan keju',
        3500,
        5000,
        'Snack Box',
        0
    ),
    (
        'Makaroni Bolognese Keju',
        'Makaroni dengan saus bolognese dan keju',
        3500,
        5000,
        'Snack Box',
        0
    ),
    (
        'Risol Bolognese',
        'Risol dengan isian bolognese',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Risol Mayo',
        'Risol dengan mayonaise',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Lemper',
        'Ketan isi ayam',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Kroket',
        'Kroket kentang isi daging',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Bitterballen',
        'Bitterballen isi ragout',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Mini Pizza',
        'Pizza mini',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Martabak',
        'Martabak telur mini',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Pastel',
        'Pastel isi bihun sayur',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Pie Buah',
        'Pie dengan topping buah segar',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Soes',
        'Kue soes klasik',
        3000,
        3500,
        'Snack Box',
        0
    ),
    (
        'Soes Buah',
        'Soes dengan isian buah',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Soes Eclair',
        'Soes eclair coklat',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Muffin Coklat',
        'Muffin rasa coklat',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Muffin Keju',
        'Muffin rasa keju',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Muffin Pisang',
        'Muffin rasa pisang',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Onde-onde',
        'Onde-onde wijen',
        2500,
        3000,
        'Snack Box',
        0
    ),
    (
        'Brownies Kenari (potong)',
        'Brownies kenari per potong',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Brownies Almond (potong)',
        'Brownies almond per potong',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Brownies Mete (potong)',
        'Brownies mete per potong',
        3500,
        4000,
        'Snack Box',
        0
    ),
    (
        'Brownkus Kotak Coklat (potong)',
        'Brownkus coklat per potong',
        2500,
        3000,
        'Snack Box',
        0
    ),

-- Minuman Category
(
    'Air Mineral Botol',
    'Air mineral kemasan botol',
    3000,
    3000,
    'Minuman',
    0
),
(
    'Air Mineral Gelas',
    'Air mineral kemasan gelas',
    1000,
    1000,
    'Minuman',
    0
),

-- Kemasan Category
(
    'Dus Snack Box',
    'Kemasan dus untuk snack box',
    2500,
    2500,
    'Kemasan',
    0
),

-- Kue Kering (Toples) Category
(
    'Cokelat Keju S',
    'Toples kecil',
    55000,
    55000,
    'Kue Kering',
    0
),
(
    'Cokelat Keju M',
    'Toples medium',
    95000,
    95000,
    'Kue Kering',
    0
),
(
    'Corn Flakes S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Corn Flakes M',
    'Toples medium',
    80000,
    80000,
    'Kue Kering',
    0
),
(
    'Crincle S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Crincle M',
    'Toples medium',
    80000,
    80000,
    'Kue Kering',
    0
),
(
    'Kastengels S',
    'Toples kecil',
    65000,
    65000,
    'Kue Kering',
    0
),
(
    'Kastengels M',
    'Toples medium',
    110000,
    110000,
    'Kue Kering',
    0
),
(
    'Lidah Kucing S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Lidah Kucing M',
    'Toples medium',
    85000,
    85000,
    'Kue Kering',
    0
),
(
    'Nastar S',
    'Toples kecil',
    60000,
    60000,
    'Kue Kering',
    0
),
(
    'Nastar M',
    'Toples medium',
    105000,
    105000,
    'Kue Kering',
    0
),
(
    'Putri Salju Ijo Mete S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Putri Salju Ijo Mete M',
    'Toples medium',
    80000,
    80000,
    'Kue Kering',
    0
),
(
    'Putri Salju Keju S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Putri Salju Keju M',
    'Toples medium',
    90000,
    90000,
    'Kue Kering',
    0
),
(
    'Sagu Keju S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Sagu Keju M',
    'Toples medium',
    80000,
    80000,
    'Kue Kering',
    0
),
(
    'Skyppy S',
    'Toples kecil',
    50000,
    50000,
    'Kue Kering',
    0
),
(
    'Skyppy M',
    'Toples medium',
    80000,
    80000,
    'Kue Kering',
    0
),

-- Kue Basah (Loyang/Cup) Category
(
    'Croisant',
    'Croisant fresh',
    3500,
    3500,
    'Kue Basah',
    0
),
(
    'Zuppa Soup',
    'Zuppa soup per cup',
    13000,
    13000,
    'Kue Basah',
    0
),
(
    'Brownies Keju (loyang)',
    'Brownies keju 1 loyang',
    55000,
    55000,
    'Kue Basah',
    0
),
(
    'Brownies Choco Chips (loyang)',
    'Brownies choco chips 1 loyang',
    45000,
    45000,
    'Kue Basah',
    0
),
(
    'Brownies Kenari (loyang)',
    'Brownies kenari 1 loyang',
    50000,
    50000,
    'Kue Basah',
    0
),
(
    'Brownies Almond (loyang)',
    'Brownies almond 1 loyang',
    50000,
    50000,
    'Kue Basah',
    0
),
(
    'Brownies Mete (loyang)',
    'Brownies mete 1 loyang',
    50000,
    50000,
    'Kue Basah',
    0
),
(
    'Brownies Chichoc (loyang)',
    'Brownies chichoc 1 loyang',
    55000,
    55000,
    'Kue Basah',
    0
),
(
    'Brownies Silverqueen (loyang)',
    'Brownies silverqueen 1 loyang',
    60000,
    60000,
    'Kue Basah',
    0
),
(
    'Bronkus Oval Coklat',
    'Bronkus oval rasa coklat',
    25000,
    25000,
    'Kue Basah',
    0
),
(
    'Bronkus Oval Keju',
    'Bronkus oval rasa keju',
    25000,
    25000,
    'Kue Basah',
    0
),
(
    'Bronkus Oval Pandan',
    'Bronkus oval rasa pandan',
    25000,
    25000,
    'Kue Basah',
    0
),
(
    'Bronkus Oval Ketan Hitam',
    'Bronkus oval rasa ketan hitam',
    30000,
    30000,
    'Kue Basah',
    0
),
(
    'Brownkus Kotak Coklat (loyang)',
    'Brownkus kotak coklat 1 loyang',
    60000,
    60000,
    'Kue Basah',
    0
),
(
    'Brownkus Kotak Keju (loyang)',
    'Brownkus kotak keju 1 loyang',
    65000,
    65000,
    'Kue Basah',
    0
),
(
    'Brownkus Kotak Pandan (loyang)',
    'Brownkus kotak pandan 1 loyang',
    65000,
    65000,
    'Kue Basah',
    0
),
(
    'Bolu Pandan',
    'Bolu pandan 1 loyang',
    65000,
    65000,
    'Kue Basah',
    0
),
(
    'Bolu Marmer',
    'Bolu marmer 1 loyang',
    65000,
    65000,
    'Kue Basah',
    0
),
(
    'Bolu Pisang',
    'Bolu pisang 1 loyang',
    70000,
    70000,
    'Kue Basah',
    0
),
(
    'Rainbow Kukus',
    'Kue rainbow kukus 1 loyang',
    85000,
    85000,
    'Kue Basah',
    0
),
(
    'Lapis Surabaya',
    'Lapis surabaya 1 loyang',
    150000,
    150000,
    'Kue Basah',
    0
),
(
    'Bolu Batik',
    'Bolu batik 1 loyang',
    50000,
    50000,
    'Kue Basah',
    0
),
(
    'Cake Tape',
    'Cake tape 1 loyang',
    70000,
    70000,
    'Kue Basah',
    0
);