 

pragma solidity ^0.4.0;

interface Hash {
   
    function get() public returns (bytes32); 

}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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


contract StandardToken {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
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


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Lotery is Ownable {

   
  event TicketSelling(uint periodNumber, address indexed from, bytes32 hash, uint when);

   
  event PeriodFinished(uint periodNumber, address indexed winnerAddr, uint reward, bytes32 winnerHash, uint when);

   
  event TransferBenefit(address indexed to, uint value);

  event JackPot(uint periodNumber, address winnerAddr, bytes32 winnerHash, uint value, uint when);


 
  uint public currentPeriod;

   
  uint public maxPeriodDuration;

  uint public maxTicketAmount;

   
  uint public ticketPrice;

   
  uint public benefitPercents;

   
  uint public benefitFunds;

   
  uint public jackPotPercents;

  uint public jackPotFunds;

  bytes32 public jackPotBestHash;


   
  bytes32 private baseHash;

  Hash private hashGenerator;

   
  struct period {
  uint number;
  uint startDate;
  bytes32 winnerHash;
  address winnerAddress;
  uint raised;
  uint ticketAmount;
  bool finished;
  uint reward;
  }

   
  struct ticket {
  uint number;
  address addr;
  bytes32 hash;
  }


   
  mapping (uint => mapping (uint => ticket)) public tickets;

   
  mapping (uint => period) public periods;


  function Lotery(uint _maxPeriodDuration, uint _ticketPrice, uint _benefitPercents, uint _maxTicketAmount, address _hashAddr, uint _jackPotPercents) public {

    require(_maxPeriodDuration > 0 && _ticketPrice > 0 && _benefitPercents > 0 && _benefitPercents < 50 && _maxTicketAmount > 0 && _jackPotPercents > 0 && _jackPotPercents < 50);
     
    maxPeriodDuration = _maxPeriodDuration;
    ticketPrice = _ticketPrice;
    benefitPercents = _benefitPercents;
    maxTicketAmount = _maxTicketAmount;
    jackPotPercents = _jackPotPercents;

     
    hashGenerator = Hash(_hashAddr);
    baseHash = hashGenerator.get();

     
    periods[currentPeriod].number = currentPeriod;
    periods[currentPeriod].startDate = now;


  }



   
  function startNewPeriod() private {
     
    require(periods[currentPeriod].finished);
     
    currentPeriod++;
    periods[currentPeriod].number = currentPeriod;
    periods[currentPeriod].startDate = now;

  }





   
  function buyTicket(uint periodNumber, string data) payable public {

     
    require(msg.value == ticketPrice);
     
    require(periods[periodNumber].ticketAmount < maxTicketAmount);
     
    require(periodNumber == currentPeriod);

    processTicketBuying(data, msg.value, msg.sender);

  }


   
  function() payable public {

     
    require(msg.value == ticketPrice);
     
    require(periods[currentPeriod].ticketAmount < maxTicketAmount);


    processTicketBuying(string(msg.data), msg.value, msg.sender);


  }

  function processTicketBuying(string data, uint value, address sender) private {


     
     
     
    bytes32 hash = sha256(data, baseHash);

     
    baseHash = sha256(hash, baseHash);

     
    if (periods[currentPeriod].ticketAmount == 0 || (hash < periods[currentPeriod].winnerHash)) {
      periods[currentPeriod].winnerHash = hash;
      periods[currentPeriod].winnerAddress = sender;
    }

     
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].number = periods[currentPeriod].ticketAmount;
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].addr = sender;
    tickets[currentPeriod][periods[currentPeriod].ticketAmount].hash = hash;


     
    periods[currentPeriod].ticketAmount++;
    periods[currentPeriod].raised += value;

     
    TicketSelling(currentPeriod, sender, hash, now);

     
    if (periods[currentPeriod].ticketAmount >= maxTicketAmount) {
      finishRound();
    }

  }


   
  function finishRound() private {

     
    require(!periods[currentPeriod].finished);
     
    require(periods[currentPeriod].ticketAmount >= maxTicketAmount);


     

    uint fee = ((periods[currentPeriod].raised * benefitPercents) / 100);
    uint jack = ((periods[currentPeriod].raised * jackPotPercents) / 100);


    uint winnerReward = periods[currentPeriod].raised - fee - jack;

     
    benefitFunds += periods[currentPeriod].raised - winnerReward;


     
    if (jackPotBestHash == 0x0) {
      jackPotBestHash = periods[currentPeriod].winnerHash;
    }
     
    if (periods[currentPeriod].winnerHash < jackPotBestHash) {

      jackPotBestHash = periods[currentPeriod].winnerHash;


      if (jackPotFunds > 0) {
        winnerReward += jackPotFunds;
        JackPot(currentPeriod, periods[currentPeriod].winnerAddress, periods[currentPeriod].winnerHash, jackPotFunds, now);

      }

      jackPotFunds = 0;

    }

     
    jackPotFunds += jack;

     
    uint plannedBalance = this.balance - winnerReward;

     
    periods[currentPeriod].winnerAddress.transfer(winnerReward);

     
    periods[currentPeriod].reward = winnerReward;
    periods[currentPeriod].finished = true;

     
    PeriodFinished(currentPeriod, periods[currentPeriod].winnerAddress, winnerReward, periods[currentPeriod].winnerHash, now);

     
    startNewPeriod();

     
    assert(this.balance == plannedBalance);
  }

   
  function benefit() public onlyOwner {
    require(benefitFunds > 0);

    uint plannedBalance = this.balance - benefitFunds;
    owner.transfer(benefitFunds);
    benefitFunds = 0;

    TransferBenefit(owner, benefitFunds);
    assert(this.balance == plannedBalance);
  }

   
  function finishRoundAndStartNew() public {
     
    require(periods[currentPeriod].ticketAmount > 0);
     
    require(periods[currentPeriod].startDate + maxPeriodDuration < now);
     
    finishRound();
  }


}