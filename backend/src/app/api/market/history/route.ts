import { NextResponse } from 'next/server';

export const runtime = 'edge';

const COINGECKO_API_URL = 'https://api.coingecko.com/api/v3';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const coinId = searchParams.get('coinId');
    const days = searchParams.get('days') || '7'; // Default to 7 days
    const vs_currency = searchParams.get('vs_currency') || 'usd';

    if (!coinId) {
        return NextResponse.json({ success: false, error: 'Missing coinId parameter' }, { status: 400 });
    }

    // CoinGecko OHLC endpoint: /coins/{id}/ohlc
    // Valid days: 1, 7, 14, 30, 90, 180, 365, max
    const url = `${COINGECKO_API_URL}/coins/${coinId}/ohlc?vs_currency=${vs_currency}&days=${days}`;

    const headers: Record<string, string> = {
        'Accept': 'application/json',
    };

    if (process.env.COINGECKO_API_KEY) {
        headers['x-cg-demo-api-key'] = process.env.COINGECKO_API_KEY;
    }

    try {
        const response = await fetch(url, { headers });
        if (!response.ok) {
            return NextResponse.json({ success: false, error: `CoinGecko API error: ${response.status}` }, { status: response.status });
        }
        const data = await response.json();
        
        // Data format: [ [time, open, high, low, close], ... ]
        return NextResponse.json({ success: true, data });
    } catch (error) {
        console.error('History API Error:', error);
        return NextResponse.json({ success: false, error: 'Internal Server Error' }, { status: 500 });
    }
}
