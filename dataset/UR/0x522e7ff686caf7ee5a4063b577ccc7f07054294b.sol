 

pragma solidity ^0.4.18;

contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

 
contract Autobid {
   
  address public admin;          
  address public token;          
  uint public exchangeRate;      
  uint public expirationTime;    
  bool public active;            

   
  event TokenClaim(address tokenContract, address claimant, uint ethDeposited, uint tokensGranted);
  event Redemption(address redeemer, uint tokensDeposited, uint redemptionAmount);

   
  modifier autobidActive() {
     
    require(active);

     
    require(now < expirationTime);
    _;
  }

  modifier autobidExpired() {
    require(!active);
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

   
  function Autobid(address _admin, address _token, uint _exchangeRate, uint _expirationTime) public {
    admin = _admin;
    token = _token;
    exchangeRate = _exchangeRate;
    expirationTime = _expirationTime;
    active = true;
  }

   
  function () public payable autobidActive {
     
    uint tokenQuantity = msg.value * exchangeRate;

     
    require(Token(token).transfer(msg.sender, tokenQuantity));

     
    expirationCheck();

     
    TokenClaim(token, msg.sender, msg.value, tokenQuantity);
  }

   
  function redeemTokens(uint amount) public autobidActive {
     
     
    require(Token(token).transferFrom(msg.sender, this, amount));

    uint redemptionValue = amount / exchangeRate; 

    msg.sender.transfer(redemptionValue);

     
    Redemption(msg.sender, amount, redemptionValue);
  }

   
  function expirationCheck() public {
     
    if (now > expirationTime) {
      active = false;
    }

     
    uint remainingTokenSupply = Token(token).balanceOf(this);
    if (remainingTokenSupply < exchangeRate) {
      active = false;
    }
  }

   
  function adminWithdraw(uint amount) public autobidExpired onlyAdmin {
     
    msg.sender.transfer(amount);

     
    Redemption(msg.sender, 0, amount);
  }

   
  function adminWithdrawTokens(uint amount) public autobidExpired onlyAdmin {
     
    require(Token(token).transfer(msg.sender, amount));

     
    TokenClaim(token, msg.sender, 0, amount);
  }

   
  function adminWithdrawMiscTokens(address tokenContract, uint amount) public autobidExpired onlyAdmin {
     
    require(Token(tokenContract).transfer(msg.sender, amount));

     
    TokenClaim(tokenContract, msg.sender, 0, amount);
  }
}