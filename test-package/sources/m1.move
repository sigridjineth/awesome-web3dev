module my_first_package::m1 {
    use sui::id::VersionedID;
    use sui::tx_context::TxContext;

    struct Sword has key, store {
        id: VersionedID,
        magic: u64,
        strength: u64,
    }

    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public entry fun sword_create(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;
        // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/sources/tx_context.move
        use sui::tx_context;

        // create a sword
        let sword = Sword {
            id: tx_context::new_id(ctx),
            magic,
            strength,
        };

        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;

        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    #[test]
    public fun test_sword_create() {
        use sui::tx_context;
        use sui::transfer;

        // create a dummy instance of TXContext so that to create sword object
        let ctx = tx_context::dummy();

        // create a sword
        let sword = Sword {
            // dummy context is passed to `tx_context::new_id`
            id: tx_context::new_id(&mut ctx),
            magic: 42,
            strength: 7
        };

        // check if accessor function returns correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);

        // create a dummy address and transfer the sword
        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);
    }
}