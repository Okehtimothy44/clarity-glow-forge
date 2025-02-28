import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

[... Original test content ...]

Clarinet.test({
    name: "Can update brand profile",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register brand
        let block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("Eco Brand")
            ], wallet1.address)
        ]);
        
        // Update profile
        let updateBlock = chain.mineBlock([
            Tx.contractCall('glow-forge', 'update-brand-profile', [
                types.uint(1),
                types.ascii("Updated Eco Brand")
            ], wallet1.address)
        ]);
        
        updateBlock.receipts[0].result.expectOk();
        
        let brandInfo = chain.callReadOnlyFn(
            'glow-forge',
            'get-brand-by-id',
            [types.uint(1)],
            wallet1.address
        );
        
        let brand = brandInfo.result.expectSome().expectTuple();
        assertEquals(brand['name'], "Updated Eco Brand");
    }
});
