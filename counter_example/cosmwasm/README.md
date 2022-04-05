# Counter Example for Terra/Cosmwasm Smart Contract
* This contract has been created based on the cosmwasm network.
## Deploy
* set no-admin flag to render contract immutable
```
INIT='{"count": 2}'
```
```
wasmd tx wasm instantiate $CODE_ID "$INIT" \
    --from wallet --label "counter example" $TXFLAG -y --no-admin
```
* check whether a contract has deployed flawlessly
```
wasmd query wasm list-contract-by-code $CODE_ID $NODE --output json
```
```
CONTRACT=$(wasmd query wasm list-contract-by-code $CODE_ID $NODE --output json | jq -r '.contracts[-1]')
echo $CONTRACT
```
* querying the count variable
```
wasmd query wasm contract $CONTRACT $NODE
```
* querying a balance of the contract
```
wasmd query bank balances $CONTRACT $NODE
```
* dumping entire contract state
```
wasmd query wasm contract-state all $CONTRACT $NODE
```
* note that we prefix the key "config" with two bytes indicating its length
```
echo -n config | xxd -ps
```
* querying one key directly
```
wasmd query wasm contract-state raw $CONTRACT 636f6e666967 $NODE --hex
```
* attempting a smart query that executes against the contract
```
wasmd query wasm contract-state all $CONTRACT $NODE --output "json" | jq -r '.models[0].value' | base64 -d
```
* try incrementing the count
```
TRY_INCREMENT='{"increment": {"count": 3}}'
```
```
wasmd tx wasm execute $CONTRACT "$TRY_INCREMENT" --amount 999upebble --from wallet $TXFLAG -y
```
* querying the count
```
QUERY='{"get_count":{}}'
```
```
wasmd query wasm contract-state smart $CONTRACT "$QUERY" $NODE --output json
```
* reseting the count
```
RESET='{"reset": {"count": 123}}'
```
```
wasmd tx wasm execute $CONTRACT "$RESET" --amount 999upebble --from wallet $TXFLAG -y
```

## Introduction

- The following factors should be taken into account while utilizing a smart contract on Ethereum.

  - 1. Initializing the contract singleton object in the form of `constructor()`
  - 2. A transaction that modifies the state of the block chain by distributing the smart contract to the zero address, while also generating a gas fee.
  - 3. A transaction that performs a function with modifiers like `view returns` but does not modify the blockchain's state (no gas charge). There is a query transaction, for example.

- Unlike Ethereum, Cosmwasm (for example, Terra) distinguishes between these three sorts of transactions a little better. One just need to implement the following three functions to write Terra's Smart Contract.

  - `initialize()`: initialization code
  - `execute()`: Transaction-handling code that modifies internal state.
  - `query()`: This function handles transactions in which the internal state is queried.

- To note, unlike Ethereum, the Cosmwasm ecosystem's smart contract deployment has gone through the following processes on its own: 1) Uploading code that is optimized wasm code but does not include the state or contract address. 2) Creating a new address by instantiating a contract with some starting state. Thanks to the spliting of two processes, a large number of contract addresses might share a single contract codebase, reducing attack vectors and storage requirements for entire nodes or validators.

## Contract Specification

- I have built the contract using the following link, see [tutorial](https://docs.terra.money/Tutorials/Smart-contracts/Write-smart-contract.html#start-with-a-template) in the Terra Documentation.
- The contract keeps the track of a value named `count`.
- When the contract is created and initalized, the default value is set.
- By invoking the function `increment()`, one can increase the value by one.
- By invoking the function `decrement()`, one can decrease the value by one.
- The owner of the contract can reset the value, which is `count` to a default value.
- By invoking the query function, the current value of count is served through JSON format.

## Defining State

- See `state.rs` to how cosmwasm define its `State` struct.

```Rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct State {
    pub count: i32,
    pub owner: Addr,
}

pub const STATE: Item<State> = Item::new("state");
```

- It supports serialization and deserialization with a `serde` attribute as well as cloning, debugging, partial equivalence, and JsonSchema.
- The state is used by the [crate attribute](https://docs.rs/cw-storage-plus/latest/cw_storage_plus/) called `cw_storage_plus` to be stored in Cosmwasm/Terra mainnet.
- The `item` attribute is utilized in the contract for saving single element. To see more, check the docs linked above as it supports `Map` which has the same position of Solidity's `mapping`.

## Instantiate the contract

- To deal with a instantiating contract, define the type of data/message to transmit in order to start the process. The message in the contract is to define a default `count`.
- To implement support for ```MigrateMsg``` in Terra network, add the MigrateMsg block.

```Rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MigrateMsg {}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    pub count: i32,
}
```

- Developers are expected to create the logic for what to do when such data/message is received.
- It is expected to update ```contract.rs``` by adding ```MigrateMsg``` to import in ```crate:msg``` and add the method above ```instantiate``` method.

```Rust
use crate::msg::{CountResponse, ExecuteMsg, InstantiateMsg, QueryMsg, MigrateMsg};

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let state = State {
        count: msg.count,
        owner: info.sender.clone(),
    };
    set_contract_version(deps.storage, CONTRACT_NAME, CONTRACT_VERSION)?;
    STATE.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("method", "instantiate")
        .add_attribute("owner", info.sender)
        .add_attribute("count", msg.count.to_string()))
}
```

- `DepsMut` : A name given to the dependency which contains instances of storage, api, and querier. it consists of the following parts.
  1. `storage` : Storage provides read and write access to persistent storage. You can think of it as an HDD, while `state.rs` is the schema of the DB. Cosmwasm uses levelDB for the implementation.
  2. `api`: Api is a callback to system functions implemented outside of the wasm modules. It consists of a bunch of cryptogaphic helper functions.
  3. `querier`: The query is created, and the result is parsed. Because it also accepts custom queries, the custom query type must be specified in the function arguments.
- `Env`: includes info about blocks and contracts.
  - `Height, time, and chain id` are all contained in a block.
    - `Contract`: a struct with just containing the contract's address.
- `Information`: provides the sender's address as well as the amount sent to the contract.
- `Msg`: The sender's parameters for establishing the contract are contained in this message.

- Setting contract version in the following code piece. Retrieving `state`, save it to `STATE`.

```Rust
use cw2::set_contract_version;
```

a. This is where you'll save the contract's name and version, which you'll provide outside of the contract.
b. Additionally, this function is derived from cw2, another package in the package/ directory.
c. You'll also keep this in a storage contract.

- Response: The code piece of ` Ok(Response:default())`` has its return type with  `<ResultResponse, ContractError>```, which means you'll get a Response if everything is well and a ContractError if something goes wrong.

  - `message`: it has a list of smart contract executions to be
  - `attributes`: a key-value pair for the sake of logging
  - `events` : what you have in mind when thinking of Solidity `Event`.
  - data: binary data, namely `Option<Binary>`
  - Using the function called `add_attribute()`, the provided code produces an empty response and adds attributes to `Response`.

  ## Execution process

- It is required to specify which message must be delivered in order for it to be executed. This time, though, there are two options for execution - `increment` and `reset`. ExecuteMsg is defined as a `enum` type.

```Rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    Increment {},
    Reset { count: i32 },
}
```

- This is a code that uses match to elegantly partition the code into increment and reset. This approach is also used in production and is regarded to be similar to Java Spring's Controller paradigm. Now we must implement the increment and reset codes. Let's start with increment.

```Rust
pub fn try_increment(deps: DepsMut) -> Result<Response, ContractError> {
    STATE.update(deps.storage, |mut state| -> Result<_, ContractError> {
        state.count += 1;
        Ok(state)
    })?;

    Ok(Response::new().add_attribute("method", "try_increment"))
}
```

- With `update` function, it could be applied to `STATE` by injecting Response and ContractError by wrapping them into Result.
- As stated in the definition, if `A: FnOnce(T)` is prepared, the update function could be applied to `Item` element.

```Rust
pub fn update<A, E>(&self, store: &mut dyn Storage, action: A) -> Result<T, E>
where
    A: FnOnce(T) -> Result<T, E>,
    E: From<StdError>,
```

- The item has been applied in the following ways.

```Rust
|mut state| -> Result<_, ContractError> {
        state.count += 1;
        Ok(state)
    })?;
``
```

- The reset function has similiar logic to increment function as it denies to execute if the info's sender is differed from a state's owner.
- Response is required to facilitate communication between smart contracts and their user interfaces. In traditional web development, a server response is provided in a callback to the frontend.

```Rust
pub fn try_reset(deps: DepsMut, info: MessageInfo, count: i32) -> Result<Response, ContractError> {
    STATE.update(deps.storage, |mut state| -> Result<_, ContractError> {
        if info.sender != state.owner {
            return Err(ContractError::Unauthorized {});
        }
        state.count = count;
        Ok(state)
    })?;
    Ok(Response::new().add_attribute("method", "reset"))
}
```

## Querying Methods

- `QueryMsg` provides an enum to allow multiple ways to query the state of the contract (each potentially executing code on a read-only store).

```Rust
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    // GetCount returns the current count as a json-encoded number
    GetCount {},
}

// We define a custom struct for each query response
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct CountResponse {
    pub count: i32,
}
```

- To extract value, STATE item utilizes load function while returning to CountResponse under the `StdResult<Binary>` type.

```Rust
#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetCount {} => to_binary(&query_count(deps)?),
    }
}

fn query_count(deps: Deps) -> StdResult<CountResponse> {
    let state = STATE.load(deps.storage)?;
    Ok(CountResponse { count: state.count })
```
