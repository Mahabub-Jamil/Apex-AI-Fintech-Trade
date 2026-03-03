import { NextResponse } from 'next/server';
import { genAI } from '@/lib/gemini';
import { aiSentimentSchema } from '@/lib/validations';
import { ZodError } from 'zod';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { coinSymbol, coinId } = aiSentimentSchema.parse(body);

        const prompt = `You are a financial analyst specializing in cryptocurrency. Provide a quick market sentiment analysis for ${coinSymbol} (${coinId}). 
    Analyze recent trends, potential catalysts, and give a sentiment score from 1 (Extreme Bearish) to 100 (Extreme Bullish). 
    Keep the response concise (maximum 3 sentences) and end with "Score: [Number] - [Bullish/Bearish/Neutral]".`;

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

        return NextResponse.json({ success: true, sentiment: text });
    } catch (error: any) {
        if (error instanceof ZodError) {
            return NextResponse.json({ success: false, error: error.issues }, { status: 400 });
        }
        console.error('Sentiment API Error Details:', error?.message || error);
        return NextResponse.json({ success: false, error: error?.message || 'Internal Server Error' }, { status: 500 });
    }
}
