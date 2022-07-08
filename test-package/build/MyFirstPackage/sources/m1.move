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
}