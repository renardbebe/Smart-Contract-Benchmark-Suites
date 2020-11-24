 

pragma solidity ^0.4.21;

 

 
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

 

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint256);
    function balanceOf(address owner) external returns(uint256);
}

contract CupExchange {
    using SafeMath for uint256;
    using SafeMath for int256;

    address public owner;
    token internal teamCup;
    token internal cup;
    uint256 public exchangePrice;  
    bool public halting = true;

    event Halted(bool halting);
    event Exchange(address user, uint256 distributedAmount, uint256 collectedAmount);

     
    constructor(address cupToken, address teamCupToken) public {
        owner = msg.sender;
        teamCup = token(teamCupToken);
        cup = token(cupToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function exchange() public {
        require(msg.sender != address(0x0));
        require(msg.sender != address(this));
        require(!halting);

         
        uint256 allowance = cup.allowance(msg.sender, this);
        require(allowance > 0);
        require(cup.transferFrom(msg.sender, this, allowance));

         
        uint256 teamCupBalance = teamCup.balanceOf(address(this));
        uint256 teamCupAmount = allowance * exchangePrice;
        require(teamCupAmount <= teamCupBalance);
        require(teamCup.transfer(msg.sender, teamCupAmount));

        emit Exchange(msg.sender, teamCupAmount, allowance);
    }

     
    function safeWithdrawal(address safeAddress) public onlyOwner {
        require(safeAddress != address(0x0));
        require(safeAddress != address(this));

        uint256 balance = teamCup.balanceOf(address(this));
        teamCup.transfer(safeAddress, balance);
    }

     
    function setExchangePrice(int256 price) public onlyOwner {
        require(price > 0);
        exchangePrice = uint256(price);
    }

    function halt() public onlyOwner {
        halting = true;
        emit Halted(halting);
    }

    function unhalt() public onlyOwner {
        halting = false;
        emit Halted(halting);
    }
}

 

contract ENCupExchange is CupExchange {
    address public cup = 0x0750167667190A7Cd06a1e2dBDd4006eD5b522Cc;
    address public teamCup = 0x9B03e16382A76481f36860245DAc0f112fd3C4F8;
    constructor() CupExchange(cup, teamCup) public {}
}