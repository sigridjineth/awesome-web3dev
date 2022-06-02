import * as anchor from "@project-serum/anchor";
import { Program } from "@project-serum/anchor";
import { assert } from "chai";
import { CounterAnchor } from "../target/types/counter_anchor";
const { SystemProgram } = anchor.web3;

describe("counter_anchor", () => {
  // Configure the client to use the local cluster.
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);
  const counterAccount = anchor.web3.Keypair.generate();

  const program = anchor.workspace.CounterAnchor as Program<CounterAnchor>;

  it("should be initialized!", async () => {
    await program.rpc.initialize({
      accounts: {
        counterAccount: counterAccount.publicKey,
        user: provider.wallet.publicKey,
        systemProgram: SystemProgram.programId
      },
      signers: [counterAccount]
    })
  });

  it("should increment counts correctly from `1`", async() => {
    // given
    const NUMBER_ONE = "1";
    
    // when
    await program.rpc.increase(new anchor.BN(NUMBER_ONE), {
      accounts: {
        counterAccount: counterAccount.publicKey
      }
    })

    // then
    const counter = await program.account.counter.fetch(counterAccount.publicKey);
    assert.ok(counter.count.toString() === NUMBER_ONE);
  });

  it("should initialize to `0` when overflows from uint64", async() => {
    // given
    const U64_MAX = "18446744073709551615"

    // when
    await program.rpc.increase(new anchor.BN(U64_MAX), {
      accounts: {
        counterAccount: counterAccount.publicKey
      }
    })

    // then
    const counter = await program.account.counter.fetch(counterAccount.publicKey);
    assert.ok(counter.count.toString() === U64_MAX);
  });

  it("should decrement counts from `U64_MAX` to be `0`", async() => {
    // given
    const NUMBER_ZERO = "0";
    const U64_MAX = "18446744073709551615"
    
    // when
    await program.rpc.decrease(new anchor.BN(U64_MAX), {
      accounts: {
        counterAccount: counterAccount.publicKey
      }
    })

    // then
    const counter = await program.account.counter.fetch(counterAccount.publicKey);
    assert.ok(counter.count.toString() === NUMBER_ZERO);
  });

  it("should decrement counts `1` correctly from `0` to be `0`", async() => {
    // given
    const NUMBER_ZERO = "0";
    const NUMBER_ONE = "1";
    
    // when
    await program.rpc.decrease(new anchor.BN(NUMBER_ONE), {
      accounts: {
        counterAccount: counterAccount.publicKey
      }
    })

    // then
    const counter = await program.account.counter.fetch(counterAccount.publicKey);
    assert.ok(counter.count.toString() === NUMBER_ZERO);
  });
});
