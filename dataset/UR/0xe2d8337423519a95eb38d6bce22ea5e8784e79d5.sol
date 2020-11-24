 

pragma solidity ^0.4.13;        
   
  contract CentraAsiaWhiteList { 
 
      using SafeMath for uint;  
 
      address public owner;
      uint public operation;
      mapping(uint => address) public operation_address;
      mapping(uint => uint) public operation_amount; 
      
   
       
      modifier onlyOwner() {
          if (msg.sender != owner) {
              throw;
          }
          _;
      }
   
       
      function CentraAsiaWhiteList() {
          owner = msg.sender; 
          operation = 0;         
      }
      
       
      function() payable {    
 
        if(msg.value < 0) throw;
        if(this.balance > 47000000000000000000000) throw;  
        if(now > 1505865600)throw;  
        
        operation_address[operation] = msg.sender;
        operation_amount[operation] = msg.value;        
        operation = operation.add(1);
      }
 
       
      function withdraw() onlyOwner returns (bool result) {
          owner.send(this.balance);
          return true;
      }
      
 }
 
  
  library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }
 
    function div(uint a, uint b) internal returns (uint) {
       
      uint c = a / b;
       
      return c;
    }
 
    function sub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }
 
    function add(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
    }
 
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a >= b ? a : b;
    }
 
    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
      return a < b ? a : b;
    }
 
    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a >= b ? a : b;
    }
 
    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
      return a < b ? a : b;
    }
 
    function assert(bool assertion) internal {
      if (!assertion) {
        throw;
      }
    }
  }