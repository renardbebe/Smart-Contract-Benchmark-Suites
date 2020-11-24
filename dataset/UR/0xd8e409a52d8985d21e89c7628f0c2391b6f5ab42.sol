 

pragma solidity ^0.4.18;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract PrivateBonTokenSale is Pausable {
    using SafeMath for uint;

    string public constant name = "Private Bon Token Sale";
    uint public fiatValueMultiplier = 10 ** 6;
    uint public tokenDecimals = 10 ** 18;
    uint public ethUsdRate;

    mapping(address => uint) investors;
    mapping(address => uint) public tokenHolders;

    address beneficiary;

    modifier allowedToPay(){
        require(investors[msg.sender] > 0);
        _;
    }

    function setRate(uint rate) external onlyOwner {
        require(rate > 0);
        ethUsdRate = rate;
    }

    function setInvestorStatus(address investor, uint bonus) external onlyOwner {
        require(investor != 0x0);
        investors[investor] = bonus;
    }

    function setBeneficiary(address investor) external onlyOwner {
        beneficiary = investor;
    }

    function() payable public whenNotPaused allowedToPay{
        uint tokens = msg.value.mul(ethUsdRate).div(fiatValueMultiplier);
        uint bonus = tokens.div(100).mul(investors[msg.sender]);
        tokenHolders[msg.sender] = tokens.add(bonus);
        beneficiary.transfer(msg.value);
    }
}