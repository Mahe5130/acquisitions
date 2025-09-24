// Simple test script to verify Neon Local connection
// Run this inside the app container to test database connectivity

import 'dotenv/config';

const testConnection = async () => {
  console.log('🔍 Testing Neon Local connection...');
  console.log(
    'DATABASE_URL:',
    process.env.DATABASE_URL?.replace(/password=[^&]+/, 'password=***')
  );

  try {
    // For Node.js applications using standard postgres drivers
    // You might need to install pg if not already present
    const { Client } = await import('pg');

    const client = new Client({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false, // Required for Neon Local self-signed certs
      },
    });

    console.log('📡 Attempting to connect...');
    await client.connect();

    console.log('✅ Connected successfully!');

    // Test basic query
    const result = await client.query('SELECT version()');
    console.log('📊 PostgreSQL version:', result.rows[0].version);

    // Test table creation (basic functionality)
    await client.query(
      'CREATE TABLE IF NOT EXISTS connection_test (id SERIAL PRIMARY KEY, test_time TIMESTAMP DEFAULT NOW())'
    );
    await client.query('INSERT INTO connection_test DEFAULT VALUES');

    const testResult = await client.query(
      'SELECT COUNT(*) as count FROM connection_test'
    );
    console.log(
      '✅ Database operations working. Test records:',
      testResult.rows[0].count
    );

    await client.end();
    console.log('🎉 Connection test completed successfully!');
  } catch (error) {
    console.error('❌ Connection failed:', error.message);

    if (error.message.includes('ECONNREFUSED')) {
      console.log(
        '💡 Tip: Make sure the neon-local container is running and healthy'
      );
    }

    if (error.message.includes('authentication')) {
      console.log('💡 Tip: Check your NEON_API_KEY and project credentials');
    }

    if (error.message.includes('SSL')) {
      console.log(
        '💡 Tip: Neon Local uses self-signed certificates. Make sure ssl.rejectUnauthorized is set to false'
      );
    }

    process.exit(1);
  }
};

testConnection();
