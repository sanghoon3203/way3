import { PrismaClient } from '@prisma/client';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
import path from 'path';

const prismaClientSingleton = () => {
    // Get database path
    const dbPath = path.join(process.cwd(), 'dev.db');

    // Create Prisma adapter with URL
    const adapter = new PrismaBetterSqlite3({ url: dbPath });

    // Create PrismaClient with adapter (required in Prisma v7)
    return new PrismaClient({ adapter });
};

type PrismaClientSingleton = ReturnType<typeof prismaClientSingleton>;

const globalForPrisma = globalThis as unknown as {
    prisma: PrismaClientSingleton | undefined;
};

const prisma = globalForPrisma.prisma ?? prismaClientSingleton();

export default prisma;

if (process.env.NODE_ENV !== 'production') {
    globalForPrisma.prisma = prisma;
}
