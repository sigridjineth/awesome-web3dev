use solana_program::program_error::ProgramError;
use std::convert::TryInto;

use crate::error::EscrowError::InvalidInstruction;

pub enum EscrowInstruction {
    /// Starts the trade by creating and populating an escrow account and
    /// transferring ownership of the given temp token account to the PDA
    /// 0. `[signer]` The account of the person initializing the escrow
    /// 1. `[writable]` Temporary token account that should be created prior to this instruction and owned by the initializer
    /// 2. `[]` The initializer's token account for the token they will receive should the trade go through
    /// 3. `[writable]` The escrow account, it will hold all necessary info about the trade.
    /// 4. `[]` The rent `sysvar`
    /// 5. `[]` The token program
    InitEscrow {
        /// The amount party A expects to receive of token Y
        amount: u64,
    },

    // Executes the trading by
    //
    // - Validates the trade would take place properly
    // - Executes the trade and move assets to both token owner's account
    // - Returns excessive amount to escrow's owner
    // - Closing the escrow acount
    // - Closing the temp acount
    //
    // Accounts expected:
    //
    /// 0. `[signer]` The account of the person initializing the exchange
    /// 1. `[w]` Request's token account which has sent, to receive if fail
    /// 2. `[w]` Request's token account to receive
    /// 3. `[w]` The escrow temp account, would move all amount to 2
    /// 4. `[w]` The initializer account, what for?
    /// 5. `[w]` The initializer token account to receive
    /// 6. `[w]` The escrow account
    /// 7. `[]` token program
    /// 8. `[]` pda
    Exchange { amount: u64 },

    // Executes the cancel by
    //
    // Accounts expected:
    //
    /// 0. `[signer]` The account of the person initializing the exchange
    /// 1. `[w]` Owner's return token acc
    /// 2. `[w]` Escrow temp token acc
    /// 3. `[w]` The escrow account
    /// 4. `[]` token program
    /// 5. `[]` pda
    CancelEscrow { amount: u64 },
}

impl EscrowInstruction {
    // unpact byte buffer
    pub fn unpack(input: &[u8]) -> Result<Self, ProgramError> {
        let (tag, rest) = input.split_first().ok_or(InvalidInstruction)?;

        Ok(match tag {
            0 => Self::InitEscrow {
                amount: Self::unpack_amount(rest)?,
            },
            1 => Self::Exchange {
                amount: Self::unpack_amount(rest)?,
            },
            2 => Self::CancelEscrow { amount: 0 },
            _ => return Err(InvalidInstruction.into()),
        })
    }

    fn unpack_amount(input: &[u8]) -> Result<u64, ProgramError> {
        let amount = input
            .get(..8)
            .and_then(|slice| slice.try_into().ok())
            .map(u64::from_le_bytes)
            .ok_or(InvalidInstruction)?;
        Ok(amount)
    }
}