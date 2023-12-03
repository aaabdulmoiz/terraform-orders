const { Client } = require("pg");

exports.handler = async (event) => {
  // Replace these with your actual database connection details
  const snsMessage = JSON.parse(event.Records[0].Sns.Message);
  const orderId = snsMessage.orderId;
  const orderItems = snsMessage.orderItems;
  
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

    await client.query("BEGIN");

    for (const orderItem of orderItems) {
      const updateInventoryQuery = `
        UPDATE inventory
        SET sku_qty = sku_qty - $1
        WHERE id = $2;
      `;

      const updateInventoryValues = [orderItem.qty, orderItem.sku_id];

      await client.query(updateInventoryQuery, updateInventoryValues);
    }

    // Commit the transaction
    await client.query("COMMIT");

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Inventory updated successfully" }),
    };
  } catch (error) {
    await client.query("ROLLBACK");
    return {
      statusCode: 400,
      body: error.message,
    };
  } finally {
    await client.end();
  }
};
