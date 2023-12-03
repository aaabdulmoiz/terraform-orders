const AWS = require("aws-sdk");
const { Client } = require("pg");

exports.handler = async (event) => {
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
    const sns = new AWS.SNS();
    // SNS topic ARN
    const topicArn = process.env.PRODUCE_SNS_TOPIC;

    const orderData = JSON.parse(event.body);
    console.log('The order data is ', orderData)
    console.log('the status is ', orderData.order_status);
    console.log('the order items are ', orderData.order_items)

    const isValidOrder = await validateInventory(client, orderData.order_items);

    if (!isValidOrder) {
      throw new Error(
        "Invalid order: Some items are not available in the inventory."
      );
    }
    // Publish the message to the SNS topic
    const params = {
      Message: JSON.stringify(orderData),
      TopicArn: topicArn,
    };
    const result = await sns.publish(params).promise();
    console.log("Message published successfully:", result.MessageId);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: 'Your order has been processed.'
      }),
    };
  } catch (error) {
    const response = {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: error.message,
      }),
    };

    return response;
  }
};

async function validateInventory(client, orderItems) {
  try {
    // Fetch the current inventory quantities for the ordered SKUs
    const skuIds = orderItems.map((orderItem) => orderItem.sku_id);
    const inventoryQuery = `
      SELECT id, sku_qty
      FROM inventory
      WHERE id IN (${skuIds.join(",")})
    `;

    const { rows } = await client.query(inventoryQuery);

    // Check if there's enough quantity for each ordered SKU
    for (const orderItem of orderItems) {
      const inventoryItem = rows.find((item) => item.id === orderItem.sku_id);

      if (!inventoryItem || inventoryItem.sku_qty < orderItem.qty) {
        // Insufficient quantity for the ordered SKU
        return false;
      }
    }

    // All items are available in sufficient quantities
    return true;
  } catch (error) {
    console.error("Error validating inventory:", error);
    throw error;
  }
}
