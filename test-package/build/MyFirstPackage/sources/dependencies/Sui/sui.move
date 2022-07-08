// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Coin<SUI> is the token used to pay for gas in Sui
module sui::sui {
    use sui::coin;
    use sui::coin::TreasuryCap;
    use sui::tx_context::TxContext;

    friend sui::genesis;

    /// Name of the coin
    struct SUI has drop {}

    /// Register the token to acquire its `TreasuryCap`.
    /// This should be called only once during genesis creation.
    public(friend) fun new(ctx: &mut TxContext): TreasuryCap<SUI> {
        coin::create_currency(SUI{}, ctx)
    }

    /// Transfer to a recipient
    public entry fun transfer(c: coin::Coin<SUI>, recipient: address) {
        coin::transfer(c, recipient)
    }

}
