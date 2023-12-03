const { Client } = require('pg');

exports.handler = async (event) => {
    // Replace these with your actual database connection details
    const dbConfig = {
      user: process.env.RDS_USERNAME,
      host: process.env.RDS_HOST,
      database: process.env.RDS_DATABASE,
      password: process.env.RDS_PASSWORD,
      port: process.env.RDS_PORT,
    };
  
    const client = new Client(dbConfig);
  
    try {
      await client.connect();
  
      // Create 'orders' table if it doesn't exist
      await client.query(`
        CREATE TABLE IF NOT EXISTS orders (
          id SERIAL PRIMARY KEY,
          order_status VARCHAR(255),
          delivery_date DATE,
          name VARCHAR(255),
          phone_number VARCHAR(255),
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
      `);

      // Create 'inventory' table if it doesn't exist
      await client.query(`
        CREATE TABLE IF NOT EXISTS inventory (
          id SERIAL PRIMARY KEY,
          sku_name VARCHAR(255),
          sku_qty INT,
          current_price NUMERIC(10, 2),
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
      `);
  
      // Create 'order_items' table if it doesn't exist
      await client.query(`
        CREATE TABLE IF NOT EXISTS order_items (
          id SERIAL PRIMARY KEY,
          order_id INT REFERENCES orders(id),
          sku_id INT REFERENCES inventory(id),
          qty INT,
          price NUMERIC(10, 2),
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
      `);

      const insertQuery = `
      INSERT INTO inventory (sku_name, sku_qty, current_price) VALUES
        ('${generateRandomProductName()}', 100, 19.99),
        ('${generateRandomProductName()}', 50, 29.99),
        ('${generateRandomProductName()}', 75, 14.99),
        ('${generateRandomProductName()}', 200, 9.99);
    `;

    await client.query(insertQuery);

    console.log('Dummy data inserted into the inventory table.');
  
  
      return {
        statusCode: 200,
        body: JSON.stringify('Tables created successfully'),
      };
    } catch (error) {
      console.error('Error creating tables:', error);
      return {
        statusCode: 500,
        body: error.message,
      };
    } finally {
      await client.end();
    }
  };

  function generateRandomProductName() {
    const adjectives = ['Blue', 'Green', 'Red', 'Yellow', 'Awesome', 'Fantastic'];
    const nouns = ['Car', 'Shirt', 'Phone', 'Book', 'Table', 'Chair'];
    const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
    const noun = nouns[Math.floor(Math.random() * nouns.length)];
    return `${adjective} ${noun}`;
  }