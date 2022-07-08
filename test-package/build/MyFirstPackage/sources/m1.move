module my_first_package::m1 {
    use sui::id::VersionedID;

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

    #[test]
    public fun test_sword_create() {
        use sui::tx_context;

        // create a dummy instance of TXContext so that to create sword object
        let ctx = tx_context::dummy();

        // create a sword
        let sword = Sword {
            id: tx_context::new_id(&mut ctx),
            magic: 42,
            strength: 7
        };

        // check if accessor function returns correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);
    }
}