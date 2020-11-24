 

pragma solidity ^0.4.11;

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract BitFluxADContract {
    
   
  ERC20Interface public token;

  
   
   
  address public wallet;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BitFluxADContract(address _wallet, address _tokenAddress) public 
  {
    require(_wallet != 0x0);
    require (_tokenAddress != 0x0);
    wallet = _wallet;
    token = ERC20Interface(_tokenAddress);
  }
  
   
  function () public payable {
    throw;
  }

      
    function BulkTransfer(address[] tokenHolders, uint amount) public {
        require(msg.sender==wallet);
        for(uint i = 0; i<tokenHolders.length; i++)
        {
            token.transferFrom(wallet,tokenHolders[i],amount);
        }
    }
}