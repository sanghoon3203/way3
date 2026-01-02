const { PrismaClient } = require('@prisma/client');
const { PrismaBetterSqlite3 } = require('@prisma/adapter-better-sqlite3');
const path = require('path');

console.log('Creating PrismaClient with driver adapter...');

let prisma;
try {
    const dbPath = path.join(process.cwd(), 'dev.db');
    console.log('Database path:', dbPath);

    const adapter = new PrismaBetterSqlite3({ url: dbPath });
    prisma = new PrismaClient({ adapter });
    console.log('PrismaClient created successfully');
} catch (e) {
    console.error('Failed to create PrismaClient:');
    console.error(e);
    process.exit(1);
}

async function test() {
    try {
        console.log('Testing Prisma connection...');
        const users = await prisma.user.findMany();
        console.log('Users found:', users.length);
        if (users.length > 0) {
            console.log('Users:', JSON.stringify(users, null, 2));
        } else {
            console.log('No users in database yet.');
        }
    } catch (e) {
        console.error('Query Error:', e);
    } finally {
        await prisma.$disconnect();
    }
}

test();
