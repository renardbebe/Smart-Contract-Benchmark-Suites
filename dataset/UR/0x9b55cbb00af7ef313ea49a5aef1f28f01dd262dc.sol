 

pragma solidity ^0.4.17;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
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

contract BonumPreICO is Pausable{
    using SafeMath for uint;

    string public constant name = "Bonum PreICO";

    uint public fiatValueMultiplier = 10**6;
    uint public tokenDecimals = 10**18;

    address public beneficiary;

    uint public ethUsdRate;
    uint public collected = 0;
    uint public tokensSold = 0;
    uint public tokensSoldWithBonus = 0;


    event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);

    function BonumPreICO(
        address _beneficiary,
        uint _baseEthUsdRate
    ) public {
        beneficiary = _beneficiary;

        ethUsdRate = _baseEthUsdRate;
    }


    function setNewBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != 0x0);
        beneficiary = newBeneficiary;
    }

    function setEthUsdRate(uint rate) external onlyOwner {
        require(rate > 0);
        ethUsdRate = rate;
    }

    modifier underCap(){
        require(tokensSold < uint(750000).mul(tokenDecimals));
        _;
    }

    modifier minimumAmount(){
        require(msg.value.mul(ethUsdRate).div(fiatValueMultiplier.mul(1 ether)) >= 100);
        _;
    }

    mapping (address => uint) public investors;

    function() payable public whenNotPaused minimumAmount underCap{
        uint tokens = msg.value.mul(ethUsdRate).div(fiatValueMultiplier);
        tokensSold = tokensSold.add(tokens);
        
        tokens = tokens.add(tokens.mul(25).div(100));
        tokensSoldWithBonus =  tokensSoldWithBonus.add(tokens);
        
        investors[msg.sender] = investors[msg.sender].add(tokens);
        NewContribution(msg.sender, tokens, msg.value);

        collected = collected.add(msg.value);

        beneficiary.transfer(msg.value);
    }
}