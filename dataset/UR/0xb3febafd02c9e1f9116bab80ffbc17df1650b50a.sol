 

pragma solidity ^0.4.23;


 
 
contract iERC20 {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}





 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "mul failed");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub fail");
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "add fail");
    return c;
  }
}

 

 
 
 
 
contract TokenSales {
  using SafeMath for uint256;

   
   
   
   
   
   
  event TokenPurchase(
    address indexed token,
    address indexed seller,
    address indexed purchaser,
    uint256 value,
    uint256 amount
  );

  mapping(address => mapping(address => uint)) public saleAmounts;
  mapping(address => mapping(address => uint)) public saleRates;

   
   
   
   
   
   
   
  function createSale(iERC20 token, uint256 rate, uint256 addedTokens) public {
    uint currentSaleAmount = saleAmounts[msg.sender][token];
    if(addedTokens > 0 || currentSaleAmount > 0) {
      saleRates[msg.sender][token] = rate;
    }
    if (addedTokens > 0) {
      saleAmounts[msg.sender][token] = currentSaleAmount.add(addedTokens);
      token.transferFrom(msg.sender, address(this), addedTokens);
    }
  }

   
   
   
  function buy(iERC20 token, address seller) public payable {
    uint size;
    address sender = msg.sender;
    assembly { size := extcodesize(sender) }
    require(size == 0);  
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);

    uint rate = saleRates[seller][token];
    uint amount = saleAmounts[seller][token];
    require(rate > 0);

    uint256 tokens = weiAmount.mul(rate);
    saleAmounts[seller][token] = amount.sub(tokens);

    emit TokenPurchase(
      token,
      seller,
      msg.sender,
      weiAmount,
      tokens
    );

    token.transfer(msg.sender, tokens);
    seller.transfer(msg.value);
  }

   
   
  function cancelSale(iERC20 token) public {
    uint amount = saleAmounts[msg.sender][token];
    require(amount > 0);

    delete saleAmounts[msg.sender][token];
    delete saleRates[msg.sender][token];

    if (amount > 0) {
      token.transfer(msg.sender, amount);
    }
  }

   
  function () external payable {
    revert();
  }
}