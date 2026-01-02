
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Checking UserQuests...');
    const userQuests = await prisma.userQuest.findMany({
        include: {
            user: true
        }
    });

    if (userQuests.length === 0) {
        console.log('No user quests found.');
    } else {
        userQuests.forEach(uq => {
            console.log(`User: ${uq.user.username}, Quest: ${uq.questId}, Status: ${uq.status}, StartedAt: ${uq.startedAt}`);
        });
    }
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
