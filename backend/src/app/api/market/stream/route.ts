import { NextResponse } from 'next/server';

export const runtime = 'edge';

const COINGECKO_API_URL = 'https://api.coingecko.com/api/v3';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const vs_currency = searchParams.get('vs_currency') || 'usd';
    const per_page = searchParams.get('per_page') || '50';
    const page = searchParams.get('page') || '1';

    const defaultParams = `vs_currency=${vs_currency}&order=market_cap_desc&per_page=${per_page}&page=${page}&sparkline=true&price_change_percentage=24h`;
    const url = `${COINGECKO_API_URL}/coins/markets?${defaultParams}`;

    const headers: Record<string, string> = {
        'Accept': 'application/json',
    };

    if (process.env.COINGECKO_API_KEY) {
        headers['x-cg-demo-api-key'] = process.env.COINGECKO_API_KEY;
    }

    const stream = new ReadableStream({
        async start(controller) {
            // Function to fetch and push data
            const fetchData = async () => {
                try {
                    const response = await fetch(url, { headers });
                    if (!response.ok) {
                        console.error('Failed to fetch from CoinGecko:', response.status);
                        // Push an error event or handle gracefully. For now, we just skip this tick.
                        return;
                    }
                    const data = await response.json();
                    
                    // Format SSE data
                    const sseFormat = `data: ${JSON.stringify({ success: true, data })}\n\n`;
                    controller.enqueue(new TextEncoder().encode(sseFormat));
                } catch (error) {
                    console.error('SSE Fetch Error:', error);
                }
            };

            // Fetch immediately on connection
            await fetchData();

            // Set up polling interval every 3 seconds (Rate limit safe for CoinGecko free tier ~ 20-30/min)
            const intervalId = setInterval(fetchData, 3000);

            // Clean up when the client disconnects or stream is closed
            request.signal.addEventListener('abort', () => {
                clearInterval(intervalId);
                controller.close();
            });
        },
        cancel() {
            // This is called when the reader cancels the stream
            console.log('Stream canceled by client');
        }
    });

    return new NextResponse(stream, {
        headers: {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*', // Adjust as necessary for CORS
        },
    });
}
