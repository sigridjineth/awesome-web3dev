use anchor_lang::prelude::*;

declare_id!("3GCv7hWQa91ddxieEN3fxWMpcRrE365gK6wMNg75k6ao");

#[program]
pub mod counter_anchor {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, counter_account_bump: u8) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        counter_account.count = 0;
        ctx.accounts.counter_account.bump = counter_account_bump;
        return Ok(())
    }

    pub fn increase(ctx: Context<Increase>, increment: u64) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        let current_count = counter_account.count;

        if u64::MAX - current_count >= increment {
            counter_account.count = current_count + increment;
            return Ok(());
        }
        
        counter_account.count = u64::MAX;
        return Ok(())
    }

    pub fn decrease(ctx: Context<Decrease>, decrement: u64) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        let current_count = counter_account.count;

        if current_count >= decrement {
            counter_account.count = current_count - decrement;
            return Ok(());
        }
        
        counter_account.count = 0;
        return Ok(())
    }

    pub fn reset(ctx: Context<Reset>, reset: u64) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        counter_account.count = reset;
        return Ok(())
    }
}

/*
    1. A Solana program’s input is just a raw buffer of bytes containing account public keys and various information for the program.
    2. Each instruction in an Anchor program has a related structure which defines the format of all the information,
    and the Accounts trait determines how this structure can be created from the result of the deserialize function. 
*/
#[derive(Accounts)]
/*
    Programs can own accounts using PDAs. By assigning PDAs to accounts, a program can claim ownership of accounts without having to deal with public and private keys.
    With PDAs, a program can sign for specific addresses without a private key. Since PDAs are not public keys, they have no associated private keys.
*/
#[instruction(counter_account_bump: u8)]
pub struct Initialize<'info> {
    pub system_program: Program<'info, System>,
    /*
        1. `init` tells Anchor that calling this instruction should create an account corresponding to the BaseAccount structure.
        The account is initialized with the 8-byte discriminator and the rest of the buffer is zeroed out.

        2. `payer` indicates which account provides the tokens (called lamports) to pay for the newly-created account’s rent.
        Here, it’s the user account listed next in the structure.
        Anchor will transfer two year’s worth of lamports from the payer into the account so that it can be rent-exempt.

        3. `space` is the number of bytes required to store the account’s data.
        This is specified when the account is created and can never be changed.
        Again, Anchor needs 8 bytes and then the rest is the space taken up by the serialized structure.
        You can omit this and Anchor will automatically calculate the needed space,
        but if your structure includes dynamically sized values such as Strings or Vecs then this won’t work right.
    */
    #[account(init, space = 8 + 41, seeds = [b"counter_account".as_ref()], payer = user, bump)]
    pub counter_account: Account<'info, Counter>,

    /*
        #[account(mut)] tells Anchor that your instruction may alter the account,
        so it should serialize the account structure back to the input buffer, where Solana will update its data if allowed.
    */
    #[account(mut)]
    pub user: Signer<'info>
}

#[derive(Accounts)]
pub struct Increase<'info> {
    #[account(mut, seeds = [b"counter_account".as_ref()], bump = counter_account.bump)]
    pub counter_account: Account<'info, Counter>
}

#[derive(Accounts)]
pub struct Decrease<'info> {
    #[account(mut)]
    pub counter_account: Account<'info, Counter>
}

#[derive(Accounts)]
pub struct Reset<'info> {
    #[account(mut)]
    pub counter_account: Account<'info, Counter>
}

/*
    1. We need to create an account to store our data.
    Accounts are just the way of storing and accessing the data in Solana sealevel.

    2. On Solana, any account can store state but the storage for smart contracts is only used to store the immutable byte code.
    The state of a smart contract is actually completely stored in other accounts.

    3. To ensure that contracts can’t modify another contract’s state,
    each account assigns an owner contract which has exclusive control over state mutations.
*/
#[account]
#[derive(Default)]
pub struct Counter {
    pub count: u64,
    pub bump: u8
}