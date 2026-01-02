import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding database...');

    // Hash the password
    const hashedPassword = await bcrypt.hash('password123', 10);

    // Create test user
    const testUser = await prisma.user.upsert({
        where: { username: 'login_test_user' },
        update: {},
        create: {
            username: 'login_test_user',
            email: 'test@example.com',
            password: hashedPassword,
            currentChapter: 'prologue',
            credits: 1000,
            inventorySlots: 20,
        },
    });

    console.log('✅ Test user created:', {
        id: testUser.id,
        username: testUser.username,
        email: testUser.email,
    });

    console.log('\n📝 Login credentials:');
    console.log('   Username: login_test_user');
    console.log('   Password: password123');
}

main()
    .catch((e) => {
        console.error('❌ Seeding failed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
