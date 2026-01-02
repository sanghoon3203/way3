
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
    datasources: {
        db: {
            url: 'file:./dev.db',
        },
    },
});

async function main() {
    console.log('Testing Prisma Connection...');
    try {
        const count = await prisma.user.count();
        console.log('User count:', count);

        const newUser = await prisma.user.create({
            data: {
                username: 'test_standalone_' + Date.now(),
                email: 'test_standalone_' + Date.now() + '@example.com',
                password: 'hashed_password',
            }
        });
        console.log('Created user:', newUser.username);
    } catch (e) {
        console.error('Prisma Error:', e);
    } finally {
        await prisma.$disconnect();
    }
}

main();
