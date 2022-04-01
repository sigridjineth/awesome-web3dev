use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

// InstanitateMsg is provided when a user creates a contract through a ```MsgInstantiateContract```
// This function provides the contract with its configuration as well as its initial state
// Uploading of a contract's code and the instnatiation of a contract are regarded as separate events, which is unlike on Ethereum.
// This allows "a small set of contract archetypes" to exist as multiple instances sharing the same base code but configured with different parameters.
// throwing JSON msg like ```{ "count": 100 }```

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub count: i32,
    // after the function receives, let us go to ```instantiate()``` function in the contract.rs
}

// The ```ExecuteMsg``` is a JSON message set which is passed to the ```execute()``` function through a ```MsgExecuteContract```.
// Note: the striking difference between ```InstantiateMsg``` is that the ```ExecuteMsg``` can exist as several different type of messages. 
// .. to execute different types of functions that smart contract can provide for users.
// Let us see below: the execute() function can demultiplexes the following different types of messages (```increment``` and ```reset```)
// to its appropriate message handler logic.
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
// using an enum to multiplex over the different types of messages that our contract can understand.
// the serde attribute rewrites our attribute keys in snake case and lower case,
// so we'll have increment and reset instead of Increment and Reset when serializing and deserializing across JSON.
pub enum ExecuteMsg {
    Increment {},
    Reset { count: i32 },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    // GetCount returns the current count as a json-encoded number
    // the request would be like the following: { "get_count" : {} }
    GetCount {},
}

// We define a custom struct for each query response
// The response would be like the following: { "count": 5 }
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct CountResponse {
    pub count: i32,
}
