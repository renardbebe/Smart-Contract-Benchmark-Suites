 

pragma solidity 0.4.25;

contract ERC20Interface {
  function transfer(address to, uint256 tokens) public returns (bool success);
}

contract DonationWallet {

  address public owner = msg.sender;
  
  event Deposit(address sender, uint256 amount);
  
  function() payable public {
     
    require(msg.value > 0);
    
     
    if(msg.value > 1 szabo) {
        emit Deposit(msg.sender, msg.value);        
    }
    
     
    address(owner).transfer(msg.value);
  }
  
   
  function transferTokens(address tokenAddress, uint256 tokens) public returns(bool success) {
    require(msg.sender == owner);
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }

}