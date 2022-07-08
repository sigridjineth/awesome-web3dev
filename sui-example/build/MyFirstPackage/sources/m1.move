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

    #[test]
    fun test_sword_transactions() {
        use sui::test_scenario;

        // We assume that we have one game admin user and two regular users representing players.
        let admin = @0xABBA;
        let initial_owner = @0xCAFE;
        let final_owner = @0xFACE;

        // first transaction executed by admin
        // We then create a scenario by starting the first transaction on behalf of the admin address
        // that creates a sword and transfers its ownership to the initial owner.
        let scenario1 = &mut test_scenario::begin(&admin);
            {
                // create the sword and transfer it to the initial owner
                sword_create(
                    42,
                    7,
                    initial_owner,
                    test_scenario::ctx(scenario1)
                )
            };

        // second transaction executed by the initial sword owner
        test_scenario::next_tx(scenario1, &initial_owner);
            {
                // extract the sword owned by the initial owner
                let sword = test_scenario::take_owned<Sword>(scenario1);

                // transfer the sword to the final owner
                sword_transfer(sword, final_owner, test_scenario::ctx(scenario1))
            };

        // third transaction executed by the final sword owner
        test_scenario::next_tx(scenario1, &final_owner);
            {
                // extract the sword owned by the final owner
                let sword = test_scenario::take_owned<Sword>(scenario1);

                // verify that the sword has expected properties
                assert!(
                    magic(&sword) == 42 && strength(&sword) == 7,
                    1
                );
                // return the sword to the object pool
                // https://github.com/MystenLabs/sui/blob/413056032ca878ea0a7115b8508c325244fbf9f1/doc/src/build/programming-with-objects/ch1-object-basics.md
                // once an object is available in Move code
                // (e.g., after its created or, retrieved from emulated storage), it cannot simply disappear.
                test_scenario::return_owned(scenario1, sword);
            };
    }
}