 

pragma solidity ^0.4.9;

contract Bogotcoin {
      
     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  function giveBlockReward() {
    balanceOf[block.coinbase] += 1;
    
  }
 function Bogotcoin() {

         initialSupply = 100000000000000;
        name ="Bogotcoin";
        decimals = 6;
        symbol = "BGA";
        
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
                                   
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                           
      
    }

    
    function () {
        throw;    
    }
}