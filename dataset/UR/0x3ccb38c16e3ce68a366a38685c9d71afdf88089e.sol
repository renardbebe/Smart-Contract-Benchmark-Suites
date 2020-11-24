 

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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
 

contract DateTime {
        function getYear(uint timestamp) public constant returns (uint16);
        function getMonth(uint timestamp) public constant returns (uint8);
        function getDay(uint timestamp) public constant returns (uint8);
}

contract ERC20Distributor {

    using SafeMath for uint256;

    address public owner;   
    address public newOwnerCandidate;

    ERC20 public token;
    uint public neededAmountTotal;
    uint public releasedTokenTotal;

    address public approver;
    uint public distributedBountyTotal;


     
     
     
    DateTime public dateTime;
    
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferRequsted(address indexed previousOwner, address indexed newOwner);

    event BountyDistributed(uint listCount, uint amount);
   
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function ERC20Distributor(ERC20 _tokenAddr, address _dateTimeAddr, address _approver) public {
        owner = msg.sender;
        token = _tokenAddr;
        dateTime = DateTime(_dateTimeAddr); 
        approver = _approver;
    }

    function requestTransferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferRequsted(owner, newOwner);
        newOwnerCandidate = newOwner;
    }

    function receiveTransferOwnership() public {
        require(newOwnerCandidate == msg.sender);
        emit OwnershipTransferred(owner, newOwnerCandidate);
        owner = newOwnerCandidate;
    }
    
    function transfer(address _to, uint _amount) public onlyOwner {
        require(neededAmountTotal.add(_amount) <= token.balanceOf(this) && token.balanceOf(this) > 0);
        token.transfer(_to, _amount);
    }
    
     
    function setApprover(address _approver) public onlyOwner {
        approver = _approver;
    }
    
     
    function changeTokenAddress(ERC20 _tokenAddr) public onlyOwner {
        token = _tokenAddr;
    }
    
     
    function distributeBounty(address[] _receiver, uint[] _amount) public payable onlyOwner {
        require(_receiver.length == _amount.length);
        uint bountyAmount;
        
        for (uint i = 0; i < _amount.length; i++) {
            distributedBountyTotal += _amount[i];
            bountyAmount += _amount[i];
            token.transferFrom(approver, _receiver[i], _amount[i]);
        }
        emit BountyDistributed(_receiver.length, bountyAmount);
    }


    function viewContractHoldingToken() public view returns (uint _amount) {
        return (token.balanceOf(this));
    }

}