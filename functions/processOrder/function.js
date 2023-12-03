const { Client } = require("pg");
const AWS = require("aws-sdk");

exports.handler = async (event) => {
  const topicArn = process.env.PRODUCE_SNS_TOPIC;
  console.log("The SNS event is ", event.Records[0].Sns.Message);

  const dbConfig = {
    user: process.env.RDS_USERNAME,
    host: process.env.RDS_HOST,
    database: process.env.RDS_DATABASE,
    password: process.env.RDS_PASSWORD,
    port: process.env.RDS_PORT,
  };

  const client = new Client(dbConfig);

  const sns = new AWS.SNS();
  try {
    await client.connect();
    const orderData = JSON.parse(event.Records[0].Sns.Message);
    const { order_status, delivery_date, name, phone_number, order_items } =
      orderData;

    console.log("the order data is ", orderData);
    console.log("the order details is ", order_status);
    console.log("the order items are ", order_items);
    await client.query("BEGIN");
    const orderInsertQuery = `
      INSERT INTO orders (order_status, delivery_date, name, phone_number)
      VALUES ($1, $2, $3, $4)
      RETURNING id;
    `;
    const orderValues = [order_status, delivery_date, name, phone_number];

    const orderResult = await client.query(orderInsertQuery, orderValues);
    const orderId = orderResult.rows[0].id;

    // Bulk insert into 'order_items' table
    const orderItemsInsertQuery = `
      INSERT INTO order_items (order_id, sku_id, qty, price)
      VALUES ${order_items.map(
        (_, index) =>
          `($${index * 4 + 1}, $${index * 4 + 2}, $${index * 4 + 3}, $${
            index * 4 + 4
          })`
      )
      .join(",")}
    `;

    const orderItemsValues = order_items.flatMap((orderItem) => [
      orderId,
      orderItem.sku_id,
      orderItem.qty,
      orderItem.price,
    ]);

    await client.query(orderItemsInsertQuery, orderItemsValues);

    const updateStockSnsParams = {
      Message: JSON.stringify({
        orderId,
        orderItems: order_items,
      }),
      TopicArn: topicArn,
    };

    await sns.publish(updateStockSnsParams).promise();

    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error processing order:", error);

    return {
      statusCode: 400,
      body: JSON.stringify({ message: error.message }),
    };
  } finally {
    await client.end();
  }
};
