 

pragma solidity 0.4.24;

interface IMintableToken {
    function mint(address _to, uint256 _amount) public returns (bool);
}

 
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

contract preICO is Ownable, Pausable {
    event Approved(address _address, uint _tokensAmount);
    event Declined(address _address, uint _tokensAmount);
    event weiReceived(address _address, uint _weiAmount);
    event RateChanged(uint _newRate);

    uint public constant startTime = 1529431200;  
    uint public endTime = 1532973600;  
    uint public rate;
    uint public tokensHardCap = 10000000 * 1 ether;  

    uint public tokensMintedDuringPreICO = 0;
    uint public tokensToMintInHold = 0;

    mapping(address=>uint) public tokensHoldMap;

    IMintableToken public DXC;

    function preICO(address _DXC) {
        DXC = IMintableToken(_DXC);
    }

     
    function () payable ongoingPreICO whenNotPaused {
        uint tokensToMint = msg.value * rate;
        tokensHoldMap[msg.sender] = SafeMath.add(tokensHoldMap[msg.sender], tokensToMint);
        tokensToMintInHold = SafeMath.add(tokensToMintInHold, tokensToMint);
        weiReceived(msg.sender, msg.value);
    }

     
    function approve(address _address) public onlyOwner capWasNotReached(_address) {
        uint tokensAmount = tokensHoldMap[_address];
        tokensHoldMap[_address] = 0;
        tokensMintedDuringPreICO = SafeMath.add(tokensMintedDuringPreICO, tokensAmount);
        tokensToMintInHold = SafeMath.sub(tokensToMintInHold, tokensAmount);
        Approved(_address, tokensAmount);

        DXC.mint(_address, tokensAmount);
    }

     
    function decline(address _address) public onlyOwner {
        tokensToMintInHold = SafeMath.sub(tokensToMintInHold, tokensHoldMap[_address]);
        Declined(_address, tokensHoldMap[_address]);

        tokensHoldMap[_address] = 0;
    }

     
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;

        RateChanged(_rate);
    }

     
    function withdraw(uint _weiToWithdraw) public onlyOwner {
        msg.sender.transfer(_weiToWithdraw);
    }

     
    function increaseDuration(uint _secondsToIncrease) public onlyOwner {
        endTime = SafeMath.add(endTime, _secondsToIncrease);
    }

     
    modifier ongoingPreICO {
        require(now >= startTime && now <= endTime);
        _;
    }

     
    modifier capWasNotReached(address _address) {
        require(SafeMath.add(tokensMintedDuringPreICO, tokensHoldMap[_address]) <= tokensHardCap);
        _;
    }
}