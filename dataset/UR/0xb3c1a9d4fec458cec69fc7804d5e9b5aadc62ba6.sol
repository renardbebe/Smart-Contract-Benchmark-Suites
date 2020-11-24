 

pragma solidity 0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract FundsSplitter {
    using SafeMath for uint256;

    address public client;
    address public starbase;
    uint256 public starbasePercentage;

    ERC20 public star;
    ERC20 public tokenOnSale;

     
    constructor(
        address _client,
        address _starbase,
        uint256 _starbasePercentage,
        ERC20 _star,
        ERC20 _tokenOnSale
    )
        public
    {
        client = _client;
        starbase = _starbase;
        starbasePercentage = _starbasePercentage;
        star = _star;
        tokenOnSale = _tokenOnSale;
    }

     
    function() public payable {
        splitFunds(msg.value);
    }

     
    function splitStarFunds() public {
        uint256 starFunds = star.balanceOf(address(this));
        uint256 starbaseShare = starFunds.mul(starbasePercentage).div(100);

        star.transfer(starbase, starbaseShare);
        star.transfer(client, star.balanceOf(address(this)));  
    }

     
    function splitFunds(uint256 value) internal {
        uint256 starbaseShare = value.mul(starbasePercentage).div(100);

        starbase.transfer(starbaseShare);
        client.transfer(address(this).balance);  
    }

     
    function withdrawRemainingTokens() public {
        tokenOnSale.transfer(client, tokenOnSale.balanceOf(address(this)));
    }
}