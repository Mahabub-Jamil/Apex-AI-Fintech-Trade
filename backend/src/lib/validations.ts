import { z } from 'zod';

export const tradeSchema = z.object({
    userId: z.string().min(1, 'User ID is required'),
    assetSymbol: z.string().min(1, 'Asset symbol is required'),
    side: z.enum(['BUY', 'SELL']),
    amount: z.number().positive('Amount must be positive'),
    priceAtTrade: z.number().positive('Price must be positive'),
    timestamp: z.string().datetime().optional(), // ISO string, defaults to now on server
});

export const aiAdviseSchema = z.object({
    portfolio: z.array(
        z.object({
            symbol: z.string(),
            amount: z.number(),
            currentValue: z.number(),
        })
    ),
    riskTolerance: z.enum(['LOW', 'MEDIUM', 'HIGH']).default('MEDIUM'),
});

export const aiSentimentSchema = z.object({
    coinId: z.string().min(1, 'Coin ID is required'),
    coinSymbol: z.string().min(1, 'Coin symbol is required'),
});
