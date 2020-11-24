 

pragma solidity ^0.4.13;

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

contract ERC23ContractInterface {
  function tokenFallback(address _from, uint256 _value, bytes _data) external;
}

contract ERC23Contract is ERC23ContractInterface {

  
  function tokenFallback(address  , uint256  , bytes  ) external {
    revert();
  }

}

contract EthMatch is Ownable, ERC23Contract {
  using SafeMath for uint256;

  uint256 public constant MASTERY_THRESHOLD = 10 finney;  
  uint256 public constant PAYOUT_PCT = 95;  

  uint256 public startTime;  
  address public master;  
  uint256 public gasReq;  

  event MatchmakerPrevails(address indexed matchmaster, address indexed matchmaker, uint256 sent, uint256 actual, uint256 winnings);
  event MatchmasterPrevails(address indexed matchmaster, address indexed matchmaker, uint256 sent, uint256 actual, uint256 winnings);
  event MatchmasterTakeover(address indexed matchmasterPrev, address indexed matchmasterNew, uint256 balanceNew);

  function EthMatch(uint256 _startTime) public {
    require(_startTime >= now);

    startTime = _startTime;
    master = msg.sender;  
    gasReq = 21000;
  }

   
   
  function () public payable {
    maker(msg.sender);
  }

   
  function maker(address _payoutAddr) public payable {
    require(this.balance > 0);  
    require(msg.gas >= gasReq);  

    require(now >= startTime);
    require(_payoutAddr != 0x0);

    uint256 weiPaid = msg.value;
    require(weiPaid > 0);

    uint256 balPrev = this.balance.sub(weiPaid);

    if (balPrev == weiPaid) {
       
      uint256 winnings = weiPaid.add(balPrev.div(2));
      pay(_payoutAddr, winnings);
      MatchmakerPrevails(master, _payoutAddr, weiPaid, balPrev, winnings);
    } else {
       
      pay(master, weiPaid);
      MatchmasterPrevails(master, _payoutAddr, weiPaid, balPrev, weiPaid);
    }
  }

   
  function pay(address _payoutAddr, uint256 _amount) internal {
    require(_amount > 0);

    uint256 payout = _amount.mul(PAYOUT_PCT).div(100);
    _payoutAddr.transfer(payout);

    uint256 remainder = _amount.sub(payout);
    owner.transfer(remainder);
  }

   
  function mastery() public payable {
    mastery(msg.sender);
  }

   
  function mastery(address _payoutAddr) public payable {
    require(this.balance > 0);  
    require(now >= startTime);
    require(_payoutAddr != 0x0);

    uint256 weiPaid = msg.value;
    require(weiPaid >= MASTERY_THRESHOLD);

    uint256 balPrev = this.balance.sub(weiPaid);
    require(balPrev < MASTERY_THRESHOLD);

    pay(master, balPrev);

    MatchmasterTakeover(master, _payoutAddr, weiPaid);  

    master = _payoutAddr;  
  }

   
  function setGasReq(uint256 _gasReq) onlyOwner external {
    gasReq = _gasReq;
  }

   
  function fund() onlyOwner external payable {
    require(this.balance == msg.value);  
    require(msg.value >= MASTERY_THRESHOLD);
  }

}