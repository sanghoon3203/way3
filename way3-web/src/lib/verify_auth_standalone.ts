
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient({
    datasources: {
        db: {
            url: 'file:../../dev.db', // Adjusted path: src/lib/ -> src/ -> / (project root) -> dev.db? No, src/lib is 2 levels deep from root? No way3-web/src/lib. dev.db is in way3-web/
            // way3-web/dev.db
            // way3-web/src/lib/here.ts
            // ../../dev.db seems correct
        },
    },
});

async function main() {
    console.log('🔍 Starting Auth Verification (Standalone TS)...');
    const testUsername = 'auth_ts_' + Date.now();
    const testPassword = 'password123';

    try {
        // 1. Signup Simulation
        console.log('1️⃣  Simulating Signup...');
        const hashedPassword = await bcrypt.hash(testPassword, 10);
        const textEmail = `auth_ts_${Date.now()}@example.com`;

        const newUser = await prisma.user.create({
            data: {
                username: testUsername,
                email: textEmail,
                password: hashedPassword,
            },
        });
        console.log(`✅ User created: ${newUser.username} (ID: ${newUser.id})`);

        // 2. Login Simulation
        console.log('2️⃣  Simulating Login...');
        const foundUser = await prisma.user.findUnique({
            where: { username: testUsername },
        });

        if (!foundUser) throw new Error('User not found!');

        console.log(`Found user: ${foundUser.username}, Hashed Password: ${foundUser.password}`);

        const match = await bcrypt.compare(testPassword, foundUser.password);
        if (match) {
            console.log('✅ Password Match! Login Logic Logic is working.');
        } else {
            console.error('❌ Password Mismatch!');
        }

    } catch (error) {
        console.error('❌ Auth Verification Failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
