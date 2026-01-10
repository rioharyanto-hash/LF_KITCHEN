// Script untuk seed products ke Supabase
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://srbsiligtgvftjhggatw.supabase.co';
const supabaseKey = 'sb_publishable_RNqhJ0iz_WGeuRZFYFfR2A_nzVbJNGd';

const supabase = createClient(supabaseUrl, supabaseKey);

const products = [
    // Snack Box Category
    { name: 'Aarem-aarem', description: 'Snack tradisional', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Makaroni Schotel', description: 'Makaroni panggang dengan keju', unit_price: 3500, special_price: 5000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Makaroni Bolognese Keju', description: 'Makaroni dengan saus bolognese dan keju', unit_price: 3500, special_price: 5000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Risol Bolognese', description: 'Risol dengan isian bolognese', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Risol Mayo', description: 'Risol dengan mayonaise', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Lemper', description: 'Ketan isi ayam', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Kroket', description: 'Kroket kentang isi daging', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Bitterballen', description: 'Bitterballen isi ragout', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Mini Pizza', description: 'Pizza mini', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Martabak', description: 'Martabak telur mini', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Pastel', description: 'Pastel isi bihun sayur', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Pie Buah', description: 'Pie dengan topping buah segar', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Soes', description: 'Kue soes klasik', unit_price: 3000, special_price: 3500, category: 'Snack Box', stock_qty: 0 },
    { name: 'Soes Buah', description: 'Soes dengan isian buah', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Soes Eclair', description: 'Soes eclair coklat', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Muffin Coklat', description: 'Muffin rasa coklat', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Muffin Keju', description: 'Muffin rasa keju', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Muffin Pisang', description: 'Muffin rasa pisang', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Onde-onde', description: 'Onde-onde wijen', unit_price: 2500, special_price: 3000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Brownies Kenari (potong)', description: 'Brownies kenari per potong', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Brownies Almond (potong)', description: 'Brownies almond per potong', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Brownies Mete (potong)', description: 'Brownies mete per potong', unit_price: 3500, special_price: 4000, category: 'Snack Box', stock_qty: 0 },
    { name: 'Brownkus Kotak Coklat (potong)', description: 'Brownkus coklat per potong', unit_price: 2500, special_price: 3000, category: 'Snack Box', stock_qty: 0 },

    // Minuman Category
    { name: 'Air Mineral Botol', description: 'Air mineral kemasan botol', unit_price: 3000, special_price: 3000, category: 'Minuman', stock_qty: 0 },
    { name: 'Air Mineral Gelas', description: 'Air mineral kemasan gelas', unit_price: 1000, special_price: 1000, category: 'Minuman', stock_qty: 0 },

    // Kemasan Category
    { name: 'Dus Snack Box', description: 'Kemasan dus untuk snack box', unit_price: 2500, special_price: 2500, category: 'Kemasan', stock_qty: 0 },

    // Kue Kering (Toples) Category
    { name: 'Cokelat Keju S', description: 'Toples kecil', unit_price: 55000, special_price: 55000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Cokelat Keju M', description: 'Toples medium', unit_price: 95000, special_price: 95000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Corn Flakes S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Corn Flakes M', description: 'Toples medium', unit_price: 80000, special_price: 80000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Crincle S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Crincle M', description: 'Toples medium', unit_price: 80000, special_price: 80000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Kastengels S', description: 'Toples kecil', unit_price: 65000, special_price: 65000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Kastengels M', description: 'Toples medium', unit_price: 110000, special_price: 110000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Lidah Kucing S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Lidah Kucing M', description: 'Toples medium', unit_price: 85000, special_price: 85000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Nastar S', description: 'Toples kecil', unit_price: 60000, special_price: 60000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Nastar M', description: 'Toples medium', unit_price: 105000, special_price: 105000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Putri Salju Ijo Mete S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Putri Salju Ijo Mete M', description: 'Toples medium', unit_price: 80000, special_price: 80000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Putri Salju Keju S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Putri Salju Keju M', description: 'Toples medium', unit_price: 90000, special_price: 90000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Sagu Keju S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Sagu Keju M', description: 'Toples medium', unit_price: 80000, special_price: 80000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Skyppy S', description: 'Toples kecil', unit_price: 50000, special_price: 50000, category: 'Kue Kering', stock_qty: 0 },
    { name: 'Skyppy M', description: 'Toples medium', unit_price: 80000, special_price: 80000, category: 'Kue Kering', stock_qty: 0 },

    // Kue Basah (Loyang/Cup) Category
    { name: 'Croisant', description: 'Croisant fresh', unit_price: 3500, special_price: 3500, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Zuppa Soup', description: 'Zuppa soup per cup', unit_price: 13000, special_price: 13000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Keju (loyang)', description: 'Brownies keju 1 loyang', unit_price: 55000, special_price: 55000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Choco Chips (loyang)', description: 'Brownies choco chips 1 loyang', unit_price: 45000, special_price: 45000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Kenari (loyang)', description: 'Brownies kenari 1 loyang', unit_price: 50000, special_price: 50000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Almond (loyang)', description: 'Brownies almond 1 loyang', unit_price: 50000, special_price: 50000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Mete (loyang)', description: 'Brownies mete 1 loyang', unit_price: 50000, special_price: 50000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Chichoc (loyang)', description: 'Brownies chichoc 1 loyang', unit_price: 55000, special_price: 55000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownies Silverqueen (loyang)', description: 'Brownies silverqueen 1 loyang', unit_price: 60000, special_price: 60000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bronkus Oval Coklat', description: 'Bronkus oval rasa coklat', unit_price: 25000, special_price: 25000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bronkus Oval Keju', description: 'Bronkus oval rasa keju', unit_price: 25000, special_price: 25000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bronkus Oval Pandan', description: 'Bronkus oval rasa pandan', unit_price: 25000, special_price: 25000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bronkus Oval Ketan Hitam', description: 'Bronkus oval rasa ketan hitam', unit_price: 30000, special_price: 30000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownkus Kotak Coklat (loyang)', description: 'Brownkus kotak coklat 1 loyang', unit_price: 60000, special_price: 60000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownkus Kotak Keju (loyang)', description: 'Brownkus kotak keju 1 loyang', unit_price: 65000, special_price: 65000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Brownkus Kotak Pandan (loyang)', description: 'Brownkus kotak pandan 1 loyang', unit_price: 65000, special_price: 65000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bolu Pandan', description: 'Bolu pandan 1 loyang', unit_price: 65000, special_price: 65000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bolu Marmer', description: 'Bolu marmer 1 loyang', unit_price: 65000, special_price: 65000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bolu Pisang', description: 'Bolu pisang 1 loyang', unit_price: 70000, special_price: 70000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Rainbow Kukus', description: 'Kue rainbow kukus 1 loyang', unit_price: 85000, special_price: 85000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Lapis Surabaya', description: 'Lapis surabaya 1 loyang', unit_price: 150000, special_price: 150000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Bolu Batik', description: 'Bolu batik 1 loyang', unit_price: 50000, special_price: 50000, category: 'Kue Basah', stock_qty: 0 },
    { name: 'Cake Tape', description: 'Cake tape 1 loyang', unit_price: 70000, special_price: 70000, category: 'Kue Basah', stock_qty: 0 },
];

async function seedProducts() {
    console.log('Starting product seed...');
    console.log(`Total products to insert: ${products.length}`);

    const { data, error } = await supabase
        .from('products')
        .insert(products)
        .select();

    if (error) {
        console.error('Error inserting products:', error);
        return;
    }

    console.log(`✅ Successfully inserted ${data.length} products!`);
}

seedProducts();
