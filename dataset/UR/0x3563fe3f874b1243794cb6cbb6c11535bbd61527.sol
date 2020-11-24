 

pragma solidity ^0.4.15;

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

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



contract PreIco is Ownable {
    using SafeMath for uint;

    uint public decimals = 18;

    uint256 public initialSupply;

    uint256 public remainingSupply;

    uint256 public tokenValue;   

    address public updater;   

    uint256 public startBlock;   

    uint256 public endTime;   

    function PreIco(uint256 _initialSupply, uint256 initialValue, address initialUpdater, uint256 end) {
        initialSupply = _initialSupply;
        remainingSupply = initialSupply;
        tokenValue = initialValue;
        updater = initialUpdater;
        startBlock = block.number;
        endTime = end;
    }

    event UpdateValue(uint256 newValue);

    function updateValue(uint256 newValue) {
        require(msg.sender == updater || msg.sender == owner);
        tokenValue = newValue;
        UpdateValue(newValue);
    }

    function updateUpdater(address newUpdater) onlyOwner {
        updater = newUpdater;
    }

    function updateEndTime(uint256 newEnd) onlyOwner {
        endTime = newEnd;
    }

    event Withdraw(address indexed to, uint value);

    function withdraw(address to, uint256 value) onlyOwner {
        to.transfer(value);
        Withdraw(to, value);
    }

    modifier beforeEndTime() {
        require(now < endTime);
        _;
    }

    event AssignToken(address indexed to, uint value);

    function () payable beforeEndTime {
        require(remainingSupply > 0);
        address sender = msg.sender;
        uint256 value = msg.value.mul(10 ** decimals).div(tokenValue);
        if (remainingSupply >= value) {
            AssignToken(sender, value);
            remainingSupply = remainingSupply.sub(value);
        } else {
            AssignToken(sender, remainingSupply);
            remainingSupply = 0;
        }
    }
}