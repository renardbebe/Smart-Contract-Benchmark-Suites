 

pragma solidity ^0.4.6;

 


 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

 
contract MiniMeToken {


     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) returns (bool);


}



 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SWTConverter is TokenController {

    MiniMeToken public tokenContract;    
    ERC20 public arcToken;               

    function SWTConverter(
        address _tokenAddress,           
        address _arctokenaddress         
    ) {
        tokenContract = MiniMeToken(_tokenAddress);  
        arcToken = ERC20(_arctokenaddress);
    }

 
 
 


 function proxyPayment(address _owner) payable returns(bool) {
        return false;
    }

 
 
 
 
 
 
    function onTransfer(address _from, address _to, uint _amount) returns(bool) {
        return true;
    }

 
 
 
 
 
 
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool)
    {
        return true;
    }


 
 
 function convert(uint _amount){

         
         
        if (!arcToken.transferFrom(msg.sender, 0x0, _amount)) {
            throw;
        }

         
        if (!tokenContract.generateTokens(msg.sender, _amount)) {
            throw;
        }
    }


}