module my_first_package::m1 {
    use sui::id::VersionedID;
    use sui::tx_context::TxContext;

    struct Forge has key, store {
        id: VersionedID,
        swords_created: u64,
    }

    public fun sword_created(self: &Forge): u64 {
        self.swords_created
    }

    // module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        use sui::transfer;
        use sui::tx_context;

        // In order to keep track of the number of created swords we must initialize the forge object
        // and set its sword_create counts to 0. And module initializer is the perfect place to do it:
        let admin = Forge {
            id: tx_context::new_id(ctx),
            swords_created: 0
        };

        // transfer the forge object to the module publisher
        transfer::transfer(admin, tx_context::sender(ctx));
    }

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

    public entry fun sword_create(forge: &mut Forge, magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;
        // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/sources/tx_context.move
        use sui::tx_context;

        // create a sword
        let sword = Sword {
            id: tx_context::new_id(ctx),
            magic,
            strength,
        };

        // In order to use the forge, we need to modify the sword_create function to take the forge as a parameter
        // and to update the number of created swords at the end of the function:
        forge.swords_created = forge.swords_created + 1;

        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;

        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    #[test]
    public fun test_module_init() {
        use sui::test_scenario;

        // create test address representing a game admin
        let admin = @0xBABE;

        // first transaction to emulate module initialization
        let scenario = &mut test_scenario::begin(&admin);
            {
                init(test_scenario::ctx(scenario));
            };

        // second transaction to check if the forge has been created
        // and has initial value of zero swords created
        test_scenario::next_tx(scenario, &admin);
            {
                // extract the Forge object
                let forge = test_scenario::take_owned<Forge>(scenario);
                // verify number of created swords
                assert!(
                    sword_created((&forge)) == 0,
                    1
                );
                test_scenario::return_owned(scenario, forge);
            }
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

        // first transaction to emulate module initialization
        let scenario1 = &mut test_scenario::begin(&admin);
            {
                init(test_scenario::ctx(scenario1));
            };

        // first transaction executed by admin
        // We then create a scenario by starting the first transaction on behalf of the admin address
        // that creates a sword and transfers its ownership to the initial owner.
        test_scenario::next_tx(scenario1, &admin);
            {
                let forge = test_scenario::take_owned<Forge>(scenario1);
                // create the sword and transfer it to the initial owner
                sword_create(
                    &mut forge,
                    42,
                    7,
                    initial_owner,
                    test_scenario::ctx(scenario1)
                );
                test_scenario::return_owned(scenario1, forge);
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