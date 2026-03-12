import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';

export async function GET() {
    try {
        const usersSnapshot = await db.collection('users').get();
        const users = usersSnapshot.docs.map(doc => ({
            id: doc.id,
            holdings: doc.data().holdings
        }));
        
        return NextResponse.json({ success: true, users });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
