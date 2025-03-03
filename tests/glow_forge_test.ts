import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures brand registration validates input",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Try to register with empty name
        let block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr(types.uint(107));
        
        // Register with valid name
        block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("Eco Brand")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

[... Original test content ...]
