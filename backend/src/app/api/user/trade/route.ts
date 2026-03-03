import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';
import { tradeSchema } from '@/lib/validations';
import { ZodError } from 'zod';

export async function POST(request: Request) {
    try {
        const body = await request.json();

        // Server-side validation with Zod
        const parsedParams = tradeSchema.parse(body);

        const tradeData = {
            ...parsedParams,
            timestamp: parsedParams.timestamp ? new Date(parsedParams.timestamp) : new Date(),
        };

        // Save to Firestore under users/{userId}/trades subcollection
        const tradeRef = await db
            .collection('users')
            .doc(tradeData.userId)
            .collection('trades')
            .add(tradeData);

        return NextResponse.json({
            success: true,
            tradeId: tradeRef.id,
            data: tradeData
        });
    } catch (error: any) {
        console.error('Trade API Error:', error);
        if (error instanceof ZodError) {
            return NextResponse.json({ success: false, error: error.issues }, { status: 400 });
        }
        return NextResponse.json({ success: false, error: 'Internal Server Error' }, { status: 500 });
    }
}
