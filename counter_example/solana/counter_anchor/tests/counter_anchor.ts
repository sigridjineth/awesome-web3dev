import * as anchor from "@project-serum/anchor";
import { Program } from "@project-serum/anchor";
import { CounterAnchor } from "../target/types/counter_anchor";

describe("counter_anchor", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.CounterAnchor as Program<CounterAnchor>;

  it("Is initialized!", async () => {
    // Add your test here.
    const tx = await program.methods.initialize().rpc();
    console.log("Your transaction signature", tx);
  });
});
