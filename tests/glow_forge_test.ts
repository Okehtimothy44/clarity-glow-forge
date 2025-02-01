import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new brand with initial tier and rewards",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("Eco Brand")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let brandInfo = chain.callReadOnlyFn(
            'glow-forge',
            'get-brand-by-id',
            [types.uint(1)],
            deployer.address
        );
        
        let brand = brandInfo.result.expectSome().expectTuple();
        assertEquals(brand['name'], "Eco Brand");
        assertEquals(brand['verified'], false);
        assertEquals(brand['tier'], "bronze");
        assertEquals(brand['reward-points'], "u0");
    }
});

Clarinet.test({
    name: "Brand earns reward points when adding products",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // First register brand
        let block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("Eco Brand")
            ], wallet1.address)
        ]);
        
        // Add product
        let productBlock = chain.mineBlock([
            Tx.contractCall('glow-forge', 'add-product', [
                types.uint(1), // brand-id
                types.ascii("Eco Product"),
                types.ascii("Sustainable product description"),
                types.uint(85), // eco-score
                types.list([types.ascii("GreenCert"), types.ascii("EcoCert")])
            ], wallet1.address)
        ]);
        
        productBlock.receipts[0].result.expectOk().expectUint(1);
        
        let brandInfo = chain.callReadOnlyFn(
            'glow-forge',
            'get-brand-by-id',
            [types.uint(1)],
            wallet1.address
        );
        
        let brand = brandInfo.result.expectSome().expectTuple();
        assertEquals(brand['reward-points'], "u10"); // Bronze tier multiplier (1) * 10 points
    }
});

Clarinet.test({
    name: "Brand tier updates with sustainability score",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register brand
        let block = chain.mineBlock([
            Tx.contractCall('glow-forge', 'register-brand', [
                types.ascii("Eco Brand")
            ], wallet1.address)
        ]);
        
        // Update score to reach silver tier
        let updateBlock = chain.mineBlock([
            Tx.contractCall('glow-forge', 'update-sustainability-score', [
                types.uint(1),
                types.uint(70)
            ], deployer.address)
        ]);
        
        updateBlock.receipts[0].result.expectOk();
        
        let brandInfo = chain.callReadOnlyFn(
            'glow-forge',
            'get-brand-by-id',
            [types.uint(1)],
            deployer.address
        );
        
        let brand = brandInfo.result.expectSome().expectTuple();
        assertEquals(brand['tier'], "silver");
    }
});
