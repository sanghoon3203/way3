
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';
import { z } from 'zod';

const moveSchema = z.object({
    fromSlot: z.number().min(0),
    toSlot: z.number().min(0),
});

export async function POST(req: Request) {
    try {
        const userPayload = await getCurrentUser();
        if (!userPayload) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const body = await req.json();
        const validation = moveSchema.safeParse(body);

        if (!validation.success) {
            return NextResponse.json(
                { error: 'Invalid slot index' },
                { status: 400 }
            );
        }

        const { fromSlot, toSlot } = validation.data;

        // Transaction for safe swapping
        await prisma.$transaction(async (tx: Parameters<Parameters<typeof prisma.$transaction>[0]>[0]) => {
            // 1. Get items at both slots
            const fromItem = await tx.inventoryItem.findUnique({
                where: {
                    userId_slotIndex: {
                        userId: userPayload.id,
                        slotIndex: fromSlot,
                    },
                },
            });

            const toItem = await tx.inventoryItem.findUnique({
                where: {
                    userId_slotIndex: {
                        userId: userPayload.id,
                        slotIndex: toSlot,
                    },
                },
            });

            if (!fromItem) {
                throw new Error('No item in source slot');
            }

            // 2. Perform Swap or Move
            if (toItem) {
                // Swap: Temp move 'toItem' to -1 (safe zone) first to avoid unique constraint
                // But since we have unique constraint on [userId, slotIndex], 
                // direct update might fail if we don't handle it carefully.
                // Strategy: 
                // A -> -1
                // B -> A
                // -1 (A) -> B

                // This requires a temporary update if relying on unique constraints directly.
                // Alternatively, delete and recreate? No, ID changes.
                // Let's use negative slot index as temporary storage.

                await tx.inventoryItem.update({
                    where: { id: toItem.id },
                    data: { slotIndex: -1 }, // Temp
                });

                await tx.inventoryItem.update({
                    where: { id: fromItem.id },
                    data: { slotIndex: toSlot },
                });

                await tx.inventoryItem.update({
                    where: { id: toItem.id },
                    data: { slotIndex: fromSlot },
                });

            } else {
                // Simple Move
                await tx.inventoryItem.update({
                    where: { id: fromItem.id },
                    data: { slotIndex: toSlot },
                });
            }
        });

        return NextResponse.json({ success: true });

    } catch (error: any) {
        console.error('Inventory move error:', error);
        return NextResponse.json(
            { error: error.message || 'Failed to move item' },
            { status: 500 }
        );
    }
}
