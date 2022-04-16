# Using Storage in CosmWasm Contracts: `Item` and `Map `

## Item.rs

* Item stores a single resource in `state` storage, with a unique key. It is appropriate for places where `singleton` is used, such as simple states and contract settings.

* The usage of an [`Item`](https://github.com/CosmWasm/cw-plus/blob/main/packages/storage-plus/src/item.rs) is pretty straight-forward. You must simply provide the proper type, as well as a database key not used by any other item. Then it will provide you with a nice interface to interact with such data.
* `may_load` will parse the data stored at the key if present, returns `Ok(None)` if no data there - returns an error on issues parsing.

####  `creation` to `may_load`

```Rust
// item.rs

/// save will serialize the model and store, returns an error on serialization issues
pub fn save(&self, store: &mut dyn Storage, data: &T) -> StdResult<()> {
  store.set(self.storage_key, &to_vec(data)?);
  Ok(())
}

pub fn may_load(&self, store: &dyn Storage) -> StdResult<Option<T>> {
  let value = store.get(self.storage_key);
  may_deserialize(&value);
}

// type_helper.rs
pub(crate) fn may_deserialize<T: DeserializeOwned>(
    value: &Option<Vec<u8>>,
) -> StdResult<Option<T>> {
    match value {
        Some(vec) => Ok(Some(from_slice(&vec)?)),
        None => Ok(None),
    }
}
```

```Rust
// config.rs

#[derive(Serialize, Deserialize, PartialEq, Debug)]
struct Config {
    pub owner: String,
    pub max_tokens: i32,
}

// note const constructor rather than 2 functions with Singleton
const CONFIG: Item<Config> = Item::new("config");

// demo.rs
fn demo() -> StdResult<()> {
    let mut store = MockStorage::new();

    // may_load returns Option<T>, so None if data is missing
    // load returns T and Err(StdError::NotFound{}) if data is missing
    let empty = CONFIG.may_load(&store)?;
    assert_eq!(None, empty);
    let cfg = Config {
        owner: "admin".to_string(),
        max_tokens: 1234,
    };
    CONFIG.save(&mut store, &cfg)?;
    let loaded = CONFIG.load(&store)?;
    assert_eq!(cfg, loaded);
```

![Screen Shot 2022-04-16 at 3 11 08 PM](https://user-images.githubusercontent.com/41055141/163670071-3b3a0c93-db95-49af-b951-c55d27f20891.png)

#### `update`

* It loads the data, perform the specified action, and store the result in the database.
* This is shorthand for some common sequences, which may be useful.
* It assumes, that data was initialized before, and if it doesn't exist, `Err(StdError::NotFound)` is returned.

##### `FnOnce` ? Understanding Closure in Rust

![img](https://miro.medium.com/max/1400/0*mmn1xMTh4_1Rm80d.jpg)

* All closures implement `FnOnce`: a closure that can't be called once doesn't deserve the name. Note that if a closure only implements `FnOnce`, it can be called only once.
* The "Once" in `FnOnce` refers to an upper bound on how many times the caller will invoke it, not how many times it *can* be invoked. You can always convert a closure that can be called many times into a closure that can only be called once: simply throw away any memory associated with the closure after the first call. But you can't convert it back the other way. [Note](https://stackoverflow.com/questions/30177395/when-does-a-closure-implement-fn-fnmut-and-fnonce)
* Unlike some other languages, Rust is explicit about our use of the `self` parameter. We have to specify `self` to be the first parameter of a function signature when we are implementing a struct (Like Python).

```Rust
// MyStruct to impl MyStruct (???)
struct MyStruct {
    text: &'static str,
    number: u32,
}

impl MyStruct {
    fn new (text: &'static str, number: u32) -> MyStruct {
        MyStruct {
            text: text,
            number: number,
        }
    }
    // We have to specify that 'self' is an argument.
    fn get_number (&self) -> u32 {
        self.number
    }
    // We can specify different kinds of ownership and mutability of self.
    fn inc_number (&mut self) {
        self.number += 1;
    }
    // There are three different types of 'self'
    fn destructor (self) {
        println!("Destructing {}", self.text);
    }
}
```

* The following two styles are in common.

```rust
obj.get_number();
MyStruct::get_number(&obj);
```

##### When there is a no context with the `fn` type (소문자 f)

* This closure adds three to the number of any object of type `MyStruct` it has been given. It can be executed anywhere without any issues, and the compiler will not give you any trouble.

![Screen Shot 2022-04-16 at 3 49 35 PM](https://user-images.githubusercontent.com/41055141/163670070-77416477-a91e-4d18-8727-2210b4e33362.png)

```rust
let obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);
let closure1 = |x: &MyStruct| x.get_number() + 3;

// insert `&obj1` to |x: &MyStruct|
assert_eq!(closure1(&obj1), 18);
assert_eq!(closure1(&obj2), 13);

// We can quite easily write `closure1` like this instead.
// It doesn't matter what code appears here, the function will behave exactly the same.
fn func1 (x: &MyStruct) -> u32 {
    x.get_number() + 3
}
assert_eq!(func1(&obj1), 18);
assert_eq!(func1(&obj2), 13);
```

##### When there is an immutable context and the `Fn` trait (대문자 F): adding a context to a closure

* `closure2` depends on the value of `obj1` (`obj1.get_number()`) and contains information about the surrounding scope.
* In this case, `closure2` will borrow `obj1` so that it can use it in the function body. We can still borrow `obj1` immutably, but if we were attempt to mutate `obj1` afterwards, we would get a borrowing error.

```rust
let obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);

// obj1 is borrowed by the closure immutably.
let closure2 = |x: &MyStruct| x.get_number() + obj1.get_number();
assert_eq!(closure2(&obj2), 25);

// We can borrow obj1 again immutably...
assert_eq!(obj1.get_number(), 15);

// But we can't borrow it mutably.
// obj1.inc_number();               // ERROR
```

![Screen Shot 2022-04-16 at 3 49 58 PM](https://user-images.githubusercontent.com/41055141/163670069-4075f457-ee3d-4379-878e-bae3f8eaac2e.png)

* If we try to rewrite our closure using `fn` syntax, everything we need to know inside of the function must be passed to it as an argument, so we add an additional argument to represent the context of the function.
* Note that the `Context` struct contains an immutable reference to `MyStruct` indicating that we won’t be able to modify it inside the function.

```rust
struct Context<'a>(&'a MyStruct);

let obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);

let ctx = Context(&obj1);

fn func2 (context: &Context, x: &MyStruct) -> u32 {
    x.get_number() + context.0.get_number()
}

assert_eq!(func2(&ctx, &obj2), 25);
// We can borrow obj1 again immutably...
assert_eq!(obj1.get_number(), 15);
// But we can't borrow it mutably.
// obj1.inc_number(); // ERROR
```

##### Mutable context and the `FnMut` trait: modifying `obj1` inside the closure

* If we modify `obj1` inside the closure, we get different results: This time we can’t borrow `obj1` mutably or immutably. (querying method also does not work.) We also have to annotate the closure as `mut`.

![Screen Shot 2022-04-16 at 4 14 23 PM](https://user-images.githubusercontent.com/41055141/163670068-6011e3b6-696d-4aac-ab1e-7a8251e17d18.png)

```rust
let mut obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);

// obj1 is borrowed by the closure mutably.
let mut closure3 = |x: &MyStruct| {
    obj1.inc_number();
    x.get_number() + obj1.get_number()
};

assert_eq!(closure3(&obj2), 26);
assert_eq!(closure3(&obj2), 27);
assert_eq!(closure3(&obj2), 28);

// We can't borrow obj1 mutably or immutably
// assert_eq!(obj1.get_number(), 18);   // ERROR
// obj1.inc_number();                   // ERROR
```

* If we wish to rewrite this function using `fn` syntax, we get the following.

```rust
struct Context<'a>(&'a mut MyStruct);
let mut obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);

let mut ctx = Context(&mut obj1);
// obj1 is borrowed by the closure mutably.
fn func3 (context: &mut Context, x: &MyStruct) -> u32 {
    context.0.inc_number();
    x.get_number() + context.0.get_number()
};

assert_eq!(func3(&mut ctx, &obj2), 26);
assert_eq!(func3(&mut ctx, &obj2), 27);
assert_eq!(func3(&mut ctx, &obj2), 28);
// We can't borrow obj1 mutably or immutably
// assert_eq!(obj1.get_number(), 18);       // ERROR
// obj1.inc_number();                       // ERROR
```

##### Owned Context

```rust
let obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);

// obj1 is owned by the closure
let closure4 = |x: &MyStruct| {
    obj1.destructor();
    x.get_number()
};
```

* We have to check the type of `closure4` *before* we use it:

```
// Does not compile:
// is_fn(closure4);
// is_Fn(&closure4);
// is_FnMut(&closure4);

// Compiles successfully:
is_FnOnce(&closure4);
```

* checking the behaviour as the following. Once we have called it the first time, we have destroyed `obj1`, so it no longer exists for the second call. Rust gives us an error about using a value after it has been moved. That’s why we have to check the types beforehand.

```rust
assert_eq!(closure4(&obj2), 10);

// We can't call closure4 twice...
// assert_eq!(closure4(&obj2), 10);             //ERROR

// We can't borrow obj1 mutably or immutably
// assert_eq!(obj1.get_number(), 15);           // ERROR
// obj1.inc_number();                           // ERROR
```

* rewriting this with an `fn` we can get the following.

```rust
struct Context(MyStruct);
let obj1 = MyStruct::new("Hello", 15);
let obj2 = MyStruct::new("More Text", 10);
let ctx = Context(obj1);

// obj1 is owned by the closure
fn func4 (context: Context, x: &MyStruct) -> u32 {
    context.0.destructor();
    x.get_number()
};
```

* the above code works as the following. When we write our closure using `fn` we have to use a `Context` struct that owns it’s value. When a closure takes ownership of it’s context, we say that it implements `FnOnce`. We can only call the function once, because after that, the context has been destroyed.

```rust
assert_eq!(func4(ctx, &obj2), 10);
// We can't call func4 twice...
// assert_eq!(func4(ctx, &obj2), 10);             //ERROR
// We can't borrow obj1 mutably or immutably
// assert_eq!(obj1.get_number(), 15);           // ERROR
// obj1.inc_number();                           // ERROR
```

#### Going back to `update` and `config`

* The closurer was to modify the state, so that it could not be able to borrow the attribute both immutably or mutably.
* The closurer should be run at a `FnOnce()` condition.

```Rust
// config.rs
		// update an item with a closure (includes read and write)
    // returns the newly saved value
    let output = CONFIG.update(&mut store, |mut c| -> StdResult<_> {
        c.max_tokens *= 2;
        Ok(c)
    })?;
    assert_eq!(2468, output.max_tokens);
}

closurer = |mut c| -> StdResult<_> {
        c.max_tokens *= 2;
        Ok(c)
}
```

```Rust
// item.rs
pub fn update<A, E>(&self, store: &mut dyn Storage, action: A) -> Result<T, E>
    where
        A: FnOnce(T) -> Result<T, E>,
        E: From<StdError>,
    {
      	// firstly load it
        let input = self.load(store)?;
      	// action closure and retrieve the answer
        let output = action(input)?;
      	// save the answer
        self.save(store, &output)?;
        Ok(output)
    }

/// load will return an error if no data is set at the given key, or on parse error
pub fn load(&self, store: &dyn Storage) -> StdResult<T> {
  let value = store.get(self.storage_key);
  must_deserialize(&value)
}

/// save will serialize the model and store, returns an error on serialization issues
pub fn save(&self, store: &mut dyn Storage, data: &T) -> StdResult<()> {
  store.set(self.storage_key, &to_vec(data)?);
  Ok(())
}
```

```rust
// type_helper.rs

/// must_deserialize parses json bytes from storage (Option), returning NotFound error if no data present
pub(crate) fn must_deserialize<T: DeserializeOwned>(value: &Option<Vec<u8>>) -> StdResult<T> {
    match value {
        Some(vec) => from_slice(&vec),
        None => Err(StdError::not_found(type_name::<T>())),
    }
}
```

### `remove`

```rust
// we can remove data as well
    CONFIG.remove(&mut store);
    let empty = CONFIG.may_load(&store)?;
    assert_eq!(None, empty);

 pub fn remove(&self, store: &mut dyn Storage) {
   store.remove(self.storage_key);
 }
```

##### dyn

* A **trait object** is an object that can contain objects of different types at the same time (e.g., a vector). The `dyn` keyword is used when declaring a trait object: The size of a trait is not known at compile-time; therefore, traits have to be wrapped inside a `Box` when creating a vector trait object.

```rust
fn main() {
    trait Animal {
        fn eat(&self);
    }

    struct Herbivore;
    struct Carnivore;

    impl Animal for Herbivore {
        fn eat(&self) {
            println!("I eat plants");
        }
    }
    impl Animal for Carnivore {
        fn eat(&self) {
            println!("I eat flesh");
        }
    }

    // Create a vector of Animals:
    let mut list: Vec<Box<dyn Animal>> = Vec::new();
    let goat = Herbivore;
    let dog = Carnivore;

    list.push(Box::new(goat));
    list.push(Box::new(dog));

    // Calling eat() for all animals in the list:
    for animal in &list{
        animal.eat();
    }
}
```

## `map.rs`

* The usage of a `Map` is a little more complex but it is rather pretty straight-forward. It is similiar to what it is called as `BTreeMap` which allows `key-value` lookups with typed values. It is deemed as a more robust key-value system than options like `Bucket`.
* It also supports simple binary keys and tuples which is `combined` too.

* Ethereum does not support the iteration: see [here](https://medium.com/rayonprotocol/iteration-%EA%B0%80%EB%8A%A5%ED%95%9C-mapping-%EC%9D%84-%EA%B0%80%EC%A7%80%EB%8A%94-%EC%8A%A4%EB%A7%88%ED%8A%B8-%EC%BB%A8%ED%8A%B8%EB%9E%99%ED%8A%B8-%EC%9E%91%EC%84%B1-7974eae80f2d) and [here](https://ethereum.stackexchange.com/questions/67597/how-do-i-loop-through-a-mapping-of-address) too - A mapping is a hash table with every possible key mapped to an instance of an element. Unlike arrays, this means you can't generate an error by referencing an element that doesn't exist, because they all exist. If nothing was written to a given slot then it will return a zero-ish instance (`false, 0, empty, 0x0`). Also unlike arrays, it's not possible to iterate the keys or find out how many keys exist, because they all exist.
* However, just beyond direct lookups, we have a super-power not found in Ethereum - iteration. That's right, you can list all items in a `Map`, or only part of them. All or part of the items in a Map can be listed out and processed.

### Normal Simple Keys Example

```rust
#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
struct Data {
    pub name: String,
    pub age: i32,
}

const PEOPLE: Map<&str, Data> = Map::new("people");
```

```rust
fn demo() -> StdResult<()> {
    let mut store = MockStorage::new();
    let data = Data {
        name: "John".to_string(),
        age: 32,
    };

    // load and save with extra key argument
    let empty = PEOPLE.may_load(&store, "john")?;
    assert_eq!(None, empty);
    PEOPLE.save(&mut store, "john", &data)?;
    let loaded = PEOPLE.load(&store, "john")?;
    assert_eq!(data, loaded);

    // nothing on another key
    let missing = PEOPLE.may_load(&store, "jack")?;
    assert_eq!(None, missing);

    // update function for new or existing keys
    let birthday = |d: Option<Data>| -> StdResult<Data> {
        match d {
            Some(one) => Ok(Data {
                name: one.name,
                age: one.age + 1,
            }),
            None => Ok(Data {
                name: "Newborn".to_string(),
                age: 0,
            }),
        }
    };

    let old_john = PEOPLE.update(&mut store, "john", birthday)?;
    assert_eq!(33, old_john.age);
    assert_eq!("John", old_john.name.as_str());

    let new_jack = PEOPLE.update(&mut store, "jack", birthday)?;
    assert_eq!(0, new_jack.age);
    assert_eq!("Newborn", new_jack.name.as_str());

    // update also changes the store
    assert_eq!(old_john, PEOPLE.load(&store, "john")?);
    assert_eq!(new_jack, PEOPLE.load(&store, "jack")?);

    // removing leaves us empty
    PEOPLE.remove(&mut store, "john");
    let empty = PEOPLE.may_load(&store, "john")?;
    assert_eq!(None, empty);

    Ok(())
}
```

```rust
// map.rs
/// may_load will parse the data stored at the key if present, returns Ok(None) if no data there. returns an error on issues parsing
pub fn may_load(&self, store: &dyn Storage, k: K) -> StdResult<Option<T>> {
  self.key(k).may_load(store)
}

/// Loads the data, perform the specified action, and store the result
/// in the database. This is shorthand for some common sequences, which may be useful.
/// If the data exists, `action(Some(value))` is called. Otherwise `action(None)` is called.
    pub fn update<A, E>(&self, store: &mut dyn Storage, k: K, action: A) -> Result<T, E>
    where
        A: FnOnce(Option<T>) -> Result<T, E>,
        E: From<StdError>,
    {
        self.key(k).update(store, action)
    }
```











### Reference

* https://medium.com/swlh/understanding-closures-in-rust-21f286ed1759
* https://www.educative.io/edpresso/what-is-the-dyn-keyword-in-rust