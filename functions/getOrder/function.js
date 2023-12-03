const { Client } = require("pg");

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

    const { phone_number } = event.queryStringParameters || {};

    // Validate that phone_number is provided
    if (!phone_number) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: "phone_number is a required query parameter.",
        }),
      };
    }

    // Fetch orders with their associated order items based on the provided phone_number
    const ordersQuery = `
      SELECT
        orders.id AS order_id,
        orders.order_status,
        orders.delivery_date,
        orders.name,
        orders.phone_number,
        order_items.sku_id,
        order_items.qty,
        order_items.price
      FROM
        orders
      LEFT JOIN
        order_items ON orders.id = order_items.order_id
      WHERE
        orders.phone_number = $1
      ORDER BY
        orders.id;
    `;

    const { rows } = await client.query(ordersQuery, [phone_number]);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        data: rows
      }),
    };
  } catch (error) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: error.message
      })
    };
  } finally {
    await client.end();
  }
};
