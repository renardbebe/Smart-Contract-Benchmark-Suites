 

pragma solidity ^0.4.19;

 
contract Serum {

     
    address public minter;

     
    mapping (address => uint) public balances;

     
    event Sent(address from, address to, uint amount);
    event Mint(uint amount);

     
    function MyCoin() public {
        minter = msg.sender;
    }

     
     
    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
        Mint(amount);
    }

     
    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }
}