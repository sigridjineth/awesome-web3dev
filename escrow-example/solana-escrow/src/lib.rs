// lib.rs

pub mod entrypoint;
pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
