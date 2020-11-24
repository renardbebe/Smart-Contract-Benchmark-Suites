 

pragma solidity ^0.4.16;
 

 
 


contract Ownable {
  address public owner;
  address public admin;

   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  modifier onlyAdmin() {
    if (msg.sender != admin) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract tntsend is Ownable {
    address public tokenaddress;
   
    
    function tntsend(){
        tokenaddress = 	0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8;
        admin = msg.sender;
    }
    function setupairdrop(address _tokenaddr,address _admin) onlyOwner {
        tokenaddress = _tokenaddr;
        admin= _admin;
    }
    
    function multisend(address[] dests, uint256[] values)
    onlyAdmin
    returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
           ERC20(tokenaddress).transfer(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }
}