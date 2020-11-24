 

pragma solidity ^0.4.23;

 

contract ZTHReceivingContract {
   
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}


contract ZTHInterface {
  function getFrontEndTokenBalanceOf(address who) public view returns (uint);
  function transfer(address _to, uint _value) public returns (bool);
  function approve(address spender, uint tokens) public returns (bool);
}

contract Zethroll is ZTHReceivingContract {
  using SafeMath for uint;

   
   
  modifier betIsValid(uint _betSize, uint _playerNumber) {
     require( calculateProfit(_betSize, _playerNumber) < maxProfit
             && _betSize >= minBet
             && _playerNumber > minNumber
             && _playerNumber < maxNumber);
    _;
  }

   
  modifier gameIsActive {
    require(gamePaused == false);
    _;
  }

   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  uint constant private MAX_INT = 2 ** 256 - 1;
  uint constant public maxProfitDivisor = 1000000;
  uint constant public maxNumber = 100;
  uint constant public minNumber = 2;
  uint constant public houseEdgeDivisor = 1000;

   
  bool public gamePaused;

  address public owner;
  address public ZethrBankroll;
  address public ZTHTKNADDR;

  ZTHInterface public ZTHTKN;

  uint public contractBalance;
  uint public houseEdge;
  uint public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet = 0;

   
  uint public totalBets;
  uint public totalZTHWagered;

   

   
  event LogBet(address sender, uint value, uint rollUnder);

   
   
  event LogResult(address player, uint result, uint rollUnder, uint profit, uint tokensBetted, bool won);

   
  event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

   
  event MaxProfitChanged(uint _oldMaxProfit, uint _newMaxProfit);

   
  event CurrentContractBalance(uint _tokens);
  
  constructor (address zthtknaddr, address zthbankrolladdr) public {
     
    owner = msg.sender;

     
    ZTHTKN = ZTHInterface(zthtknaddr);
    ZTHTKNADDR = zthtknaddr;

     
    ZethrBankroll = zthbankrolladdr;

     
    houseEdge = 990;

     
    ownerSetMaxProfitAsPercentOfHouse(10000);

     
    ownerSetMinBet(1e18);

     
    ZTHTKN.approve(zthbankrolladdr, MAX_INT);
  }

  function() public payable {}  

   
   
  function maxRandom(uint blockn, address entropy) public view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        blockhash(blockn),
        entropy)
      ));
  }

   
  function random(uint256 upper, uint256 blockn, address entropy) internal view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
  }

   
  function calculateProfit(uint _initBet, uint _roll)
    private
    view
    returns (uint)
  {
    return ((((_initBet * (101 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

   
  struct playerRoll{
    uint200 tokenValue;  
    uint48 blockn;       
    uint8 rollUnder;     
  }

   
  mapping(address => playerRoll) public playerRolls;

  function _playerRollDice(uint _rollUnder, TKN _tkn) private
    gameIsActive
    betIsValid(_tkn.value, _rollUnder)
  {
    require(_tkn.value < ((2 ** 200) - 1));    
    require(block.number < ((2 ** 48) - 1));   

     
     

     
    require(_zthToken(msg.sender));

    playerRoll memory roll = playerRolls[_tkn.sender];

     
    require(block.number != roll.blockn);

     
    if (roll.blockn != 0) {
      _finishBet(false, _tkn.sender);
    }

     
    roll.blockn = uint40(block.number);
    roll.tokenValue = uint200(_tkn.value);
    roll.rollUnder = uint8(_rollUnder);

     
    playerRolls[_tkn.sender] = roll;

     
    emit LogBet(_tkn.sender, _tkn.value, _rollUnder);
                 
     
    totalBets += 1;

     
    totalZTHWagered += _tkn.value;
  }

   
  function finishBet() public
    gameIsActive
  {
    _finishBet(true, msg.sender);
  }

   
  function _finishBet(bool delete_it, address target) private {
    playerRoll memory roll = playerRolls[target];
    require(roll.tokenValue > 0);  

     
     
    uint result;
    if (block.number - roll.blockn > 255) {
      result = 1000;  
    } else {
       
      result = random(100, roll.blockn, target) + 1;
    }

    uint rollUnder = roll.rollUnder;

    if (result < rollUnder) {
       

       
      uint profit = calculateProfit(roll.tokenValue, rollUnder);

       
      contractBalance = contractBalance.sub(profit);

      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, true);

       
      setMaxProfit();

      if (delete_it){
         
        delete playerRolls[target];
      }

       
      ZTHTKN.transfer(target, profit + roll.tokenValue);

    } else {
       
      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, false);

       
      contractBalance = contractBalance.add(roll.tokenValue);

       
       

       
      setMaxProfit();
    }
  }

   
  struct TKN {address sender; uint value;}

   
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool) {
    if (_from == ZethrBankroll) {
       
      contractBalance = contractBalance.add(_value);

       
      uint oldMaxProfit = maxProfit;
      setMaxProfit();

      emit MaxProfitChanged(oldMaxProfit, maxProfit);
      return true;

    } else {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      uint8 chosenNumber = uint8(_data[0]);
      _playerRollDice(chosenNumber, _tkn);
    }

    return true;
  }

   
  function setMaxProfit() internal {
    emit CurrentContractBalance(contractBalance);
    maxProfit = (contractBalance * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

   
  function ownerUpdateContractBalance(uint newContractBalance) public
  onlyOwner
  {
    contractBalance = newContractBalance;
  }

   
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
  onlyOwner
  {
     
    require(newMaxProfitAsPercent <= 200000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit();
  }

   
  function ownerSetMinBet(uint newMinimumBet) public
  onlyOwner
  {
    minBet = newMinimumBet;
  }

   
  function ownerTransferZTH(address sendTo, uint amount) public
  onlyOwner
  {
     
    contractBalance = contractBalance.sub(amount);

     
    setMaxProfit();
    require(ZTHTKN.transfer(sendTo, amount));
    emit LogOwnerTransfer(sendTo, amount);
  }

   
  function ownerPauseGame(bool newStatus) public
  onlyOwner
  {
    gamePaused = newStatus;
  }

   
  function ownerSetBankroll(address newBankroll) public
  onlyOwner
  {
    ZTHTKN.approve(ZethrBankroll, 0);
    ZethrBankroll = newBankroll;
    ZTHTKN.approve(newBankroll, MAX_INT);
  }

   
  function ownerChangeOwner(address newOwner) public
  onlyOwner
  {
    owner = newOwner;
  }

   
  function ownerkill() public
  onlyOwner
  {
    ZTHTKN.transfer(owner, contractBalance);
    selfdestruct(owner);
  }
  
  function dumpdivs() public{
      ZethrBankroll.transfer(address(this).balance);
  }

  function _zthToken(address _tokenContract) private view returns (bool) {
    return _tokenContract == ZTHTKNADDR;
     
  }
}

 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

   
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}