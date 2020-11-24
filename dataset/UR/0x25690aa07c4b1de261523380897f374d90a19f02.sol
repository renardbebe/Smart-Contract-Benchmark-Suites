 

pragma solidity ^0.4.0;

contract GBank {

    address creator;

    mapping (address => uint) balances;

    function GBank(uint startAmount) {
        balances[msg.sender] = startAmount;
        creator = msg.sender;
    }

    function getBalance(address a) constant returns (uint) {
        return balances[a];
    }

    function transfer(address to, uint amount) {

         
        if (msg.sender == to) {
            throw;
        }

         
        if (amount > balances[msg.sender]) {
            throw;
        }

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}