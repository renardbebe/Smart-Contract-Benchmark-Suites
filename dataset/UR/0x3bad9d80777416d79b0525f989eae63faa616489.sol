 

pragma solidity ^0.4.23;

contract ERC223Interface {
    uint public totalSupply;
    uint8 public decimals;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract ERC223ReceivingContract {
    
     
    function tokenFallback(address _from, uint _value, bytes _data);
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
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


 
contract AirDrop is Ownable {
    using SafeMath for uint256;

     
    uint public airDropAmount;

     
    mapping ( address => bool ) public invalidAirDrop;

     
    address[] public arrayAirDropReceivers;

     
    bool public stop = false;

    ERC223Interface public erc20;

    uint256 public startTime;
    uint256 public endTime;

     
    event LogAirDrop(address indexed receiver, uint amount);
    event LogStop();
    event LogStart();
    event LogWithdrawal(address indexed receiver, uint amount);

     
    constructor(uint256 _startTime, uint256 _endTime, uint _airDropAmount, address _tokenAddress) public {
        require(_startTime >= now &&
            _endTime >= _startTime &&
            _airDropAmount > 0 &&
            _tokenAddress != address(0)
        );
        startTime = _startTime;
        endTime = _endTime;
        erc20 = ERC223Interface(_tokenAddress);
        uint tokenDecimals = erc20.decimals();
        airDropAmount = _airDropAmount.mul(10 ** tokenDecimals);
    }

     
    function tokenFallback(address _from, uint _value, bytes _data) {}

     
    function isValidAirDropForAll() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = getRemainingToken() >= airDropAmount;
        bool validPeriod = now >= startTime && now <= endTime;
        return validNotStop && validAmount && validPeriod;
    }

     
    function isValidAirDropForIndividual() public view returns (bool) {
        bool validNotStop = !stop;
        bool validAmount = getRemainingToken() >= airDropAmount;
        bool validPeriod = now >= startTime && now <= endTime;
        bool validReceiveAirDropForIndividual = !invalidAirDrop[msg.sender];
        return validNotStop && validAmount && validPeriod && validReceiveAirDropForIndividual;
    }

     
    function receiveAirDrop() public {
        require(isValidAirDropForIndividual());

         
        invalidAirDrop[msg.sender] = true;

         
        arrayAirDropReceivers.push(msg.sender);

         
        erc20.transfer(msg.sender, airDropAmount);

        emit LogAirDrop(msg.sender, airDropAmount);
    }

     
    function toggle() public onlyOwner {
        stop = !stop;

        if (stop) {
            emit LogStop();
        } else {
            emit LogStart();
        }
    }

     
    function withdraw(address _address) public onlyOwner {
        require(stop || now > endTime);
        require(_address != address(0));
        uint tokenBalanceOfContract = getRemainingToken();
        erc20.transfer(_address, tokenBalanceOfContract);
        emit LogWithdrawal(_address, tokenBalanceOfContract);
    }

     
    function getTotalNumberOfAddressesReceivedAirDrop() public view returns (uint256) {
        return arrayAirDropReceivers.length;
    }

     
    function getRemainingToken() public view returns (uint256) {
        return erc20.balanceOf(this);
    }

     
    function getTotalAirDroppedAmount() public view returns (uint256) {
        return airDropAmount.mul(arrayAirDropReceivers.length);
    }
}