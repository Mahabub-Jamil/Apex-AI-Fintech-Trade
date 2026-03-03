import { NextResponse } from 'next/server';

const COINGECKO_API_URL = 'https://api.coingecko.com/api/v3';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const vs_currency = searchParams.get('vs_currency') || 'usd';
    const per_page = searchParams.get('per_page') || '50';
    const page = searchParams.get('page') || '1';

    try {
        const defaultParams = `vs_currency=${vs_currency}&order=market_cap_desc&per_page=${per_page}&page=${page}&sparkline=true&price_change_percentage=24h`;
        let url = `${COINGECKO_API_URL}/coins/markets?${defaultParams}`;

        const headers: Record<string, string> = {
            'Accept': 'application/json',
        };

        if (process.env.COINGECKO_API_KEY) {
            headers['x-cg-demo-api-key'] = process.env.COINGECKO_API_KEY; // Or pro header if using pro
        }

        const response = await fetch(url, { headers });

        if (!response.ok) {
            return NextResponse.json({ error: 'Failed to fetch from CoinGecko' }, { status: response.status });
        }

        const data = await response.json();
        return NextResponse.json({ success: true, data });
    } catch (error: any) {
        console.error('Market Stream Error:', error);
        return NextResponse.json({ success: false, error: 'Internal Server Error' }, { status: 500 });
    }
}
