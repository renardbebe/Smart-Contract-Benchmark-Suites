 

pragma solidity ^0.4.23;

 
 

contract Database {

    address public owner;

    constructor() public {
      owner = msg.sender;
    }
    
    function withdraw() public {
      require(msg.sender == owner);
      owner.transfer(address(this).balance);
    }

     
     
    event Table(uint256 indexed _row, bytes32 indexed _column, bytes32 indexed _value);
     

    function put(uint256 _row, string _column, string _value) public {
        emit Table(_row, keccak256(_column), keccak256(_value));
    }
}