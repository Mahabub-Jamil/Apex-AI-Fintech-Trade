import { NextResponse } from 'next/server';
import { genAI } from '@/lib/gemini';
import { aiAdviseSchema } from '@/lib/validations';
import { ZodError } from 'zod';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { portfolio, riskTolerance } = aiAdviseSchema.parse(body);

        const portfolioString = portfolio
            .map(p => `${p.amount} ${p.symbol} (Value: $${p.currentValue.toFixed(2)})`)
            .join(', ');

        const prompt = `You are an expert crypto portfolio manager. Review this virtual portfolio: ${portfolioString}. 
    The user's risk tolerance is ${riskTolerance}.
    Provide a brief strategic advice on this allocation (max 3 bullet points) and an overall risk score from 1 (Safest) to 10 (Riskiest).`;

        let result;
        try {
            const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' }, { apiVersion: 'v1beta' });
            result = await model.generateContent(prompt);
        } catch (initialError: any) {
            console.warn('gemini-2.5-flash failed, falling back to gemini-2.0-flash:', initialError?.message);
            const fallbackModel = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' }, { apiVersion: 'v1beta' });
            result = await fallbackModel.generateContent(prompt);
        }

        const text = result.response.text();

        return NextResponse.json({ success: true, advice: text });
    } catch (error: any) {
        if (error instanceof ZodError) {
            return NextResponse.json({ success: false, error: error.issues }, { status: 400 });
        }
        console.error('Advise API Error Details:', error?.message || error);
        return NextResponse.json({ success: false, error: error?.message || 'Internal Server Error' }, { status: 500 });
    }
}
