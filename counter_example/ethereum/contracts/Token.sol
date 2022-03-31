// The following code is used by the Solidity compiler to validate the version.
pragma solidity ^0.8.0;

// This is the main building block for smart contracts
contract Token {
    /*
        name: some string type variables to identify the token
        token: the ticker to differentiate each tokens
    */
    string public name = "Joon Jung";
    string public token = "JOON";

    // the fixed amount of tokens that is stored in an unsigned integer type variable.
    uint256 public totalSupply = 980805;

    // the address type is used to store ETH accounts.
    address public owner;

    // A mapping is basically key-value map, which stores the balance of each accounts.
    mapping(address => uint256) balances;

    // The constructor is executed only once when the contract is created.
    constructor() {
        // When initiating the contract, the all of the token supply applies to the msg.sender - the contract owner.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // The external modifier is used when hoping to make a function to be callable only from outside of the contract.
    function transfer(address to, uint256 amount) external {
        // check whether the transaction has enough value to send. The second parameter is used as an error message when reverting the transaction.
        require(balances[msg.sender] >= amount, "We have no enough tokens.");

        // the total balance is being canceled by the amount given.
        balances[msg.sender] -= amount;
        // the amount given is transferred to a receiver address.
        balances[to] += amount;
    }

    // The read only function to retrieve the token balance of a given account.
    // @modifier : view is used when the function does not allow developers to modify the state of contract.
    // It which only allows to call without executing a transaction.
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

}