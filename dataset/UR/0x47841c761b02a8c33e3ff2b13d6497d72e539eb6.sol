 

pragma solidity ^0.4.21;
contract ERC20Token  {
  function transfer(address to, uint256 value) public returns (bool);
}

 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
   emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
   emit Unpause();
  }
}
 
contract Destructible is Pausable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}




contract PTMCrowdFund is Destructible {
    event PurchaseToken (address indexed from,uint256 weiAmount,uint256 _tokens);
     uint public priceOfToken=250000000000000; 
    ERC20Token erc20Token;
    using SafeMath for uint256;
    uint256 etherRaised;
    uint public constant decimals = 18;
    function PTMCrowdFund () public {
        owner = msg.sender;
        erc20Token = ERC20Token(0x7c32DB0645A259FaE61353c1f891151A2e7f8c1e);
    }
    function updatePriceOfToken(uint256 priceInWei) external onlyOwner {
        priceOfToken = priceInWei;
    }
    
    function updateTokenAddress ( address _tokenAddress) external onlyOwner {
        erc20Token = ERC20Token(_tokenAddress);
    }
    
      function()  public whenNotPaused payable {
          require(msg.value>0);
          uint256 tokens = (msg.value * (10 ** decimals)) / priceOfToken;
          erc20Token.transfer(msg.sender,tokens);
          etherRaised += msg.value;
          
      }
      
         
    function transferFundToAccount(address _accountByOwner) public onlyOwner {
        require(etherRaised > 0);
        _accountByOwner.transfer(etherRaised);
        etherRaised = 0;
    }

    
     
    function transferLimitedFundToAccount(address _accountByOwner, uint256 balanceToTransfer) public onlyOwner   {
        require(etherRaised > balanceToTransfer);
        _accountByOwner.transfer(balanceToTransfer);
        etherRaised = etherRaised.sub(balanceToTransfer);
    }
    
}