 

pragma solidity ^0.4.20;

contract Envelop {
     
     
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }
    
    address public owner;

     
    function Envelop() public {
        owner = msg.sender;
    }
    
    mapping(address => uint) public accounts;
    bytes32 public hashKey;
     
    function start(string _key) public onlyOwner{
        hashKey = sha3(_key);
    }
    
    function bid(string _key) public {
        if (sha3(_key) == hashKey && accounts[msg.sender] != 1) {
            accounts[msg.sender] = 1;
            msg.sender.transfer(1e16);
        }
    }
    
    function () payable {
    }
}