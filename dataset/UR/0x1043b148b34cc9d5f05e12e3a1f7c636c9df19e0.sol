 

 

pragma solidity ^0.5.1;

contract ERC20Cutted {
    
  function balanceOf(address who) public view returns (uint256);
  
  function transfer(address to, uint256 value) public;
  
}


contract SimpleDistributor {
    
  address public owner;
    
  ERC20Cutted public token = ERC20Cutted(0xCB459689182459186a5d690e3DA41dC65e754645);
    
  constructor() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner, "You must be owner!");
    _;
  } 
   
  function distribute(address[] memory receivers, uint[] memory balances) public onlyOwner {
    for(uint i = 0; i < receivers.length; i++) {
      token.transfer(receivers[i], balances[i]);
    }
  } 
  
  function retrieveCurrentTokensToOwner() public {
    retrieveTokens(owner, address(token));
  }

  function retrieveTokens(address to, address anotherToken) public onlyOwner {
    ERC20Cutted alienToken = ERC20Cutted(anotherToken);
    alienToken.transfer(to, alienToken.balanceOf(address(this)));
  }
  
  function setToken(address newToken) public onlyOwner {
    token = ERC20Cutted(newToken);  
  }

}