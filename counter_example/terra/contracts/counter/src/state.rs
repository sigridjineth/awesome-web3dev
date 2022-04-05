use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use cosmwasm_std::Addr;
use cw_storage_plus::Item;

// A singleton struct ```State``` contains the following:
// 1. a 32-bit integer count
// 2. an address ```owner```
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
// The state contains.. 1) count - 32bit integer 2) owner, the address type
pub struct State {
    pub count: i32,
    pub owner: Addr,
}

// Smart contract has the ability to keep persistent state by native LevelDB, which is a key-value based store.
pub const STATE: Item<State> = Item::new("state");
