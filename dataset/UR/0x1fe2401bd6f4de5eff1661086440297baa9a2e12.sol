 

pragma solidity ^0.4.24;

 
contract ZethrTokenBankroll{
     
    function gameRequestTokens(address target, uint tokens) public;
}

 
contract ZethrMainBankroll{
    function gameGetTokenBankrollList() public view returns (address[7]);
}

 
contract ZethrInterface{
    function withdraw() public;
}

 
library ZethrTierLibrary{
    uint constant internal magnitude = 2**64;
    function getTier(uint divRate) internal pure returns (uint){
         
         
        
         
         
        uint actualDiv = divRate; 
        if (actualDiv >= 30){
            return 6;
        } else if (actualDiv >= 25){
            return 5;
        } else if (actualDiv >= 20){
            return 4;
        } else if (actualDiv >= 15){
            return 3;
        } else if (actualDiv >= 10){
            return 2; 
        } else if (actualDiv >= 5){
            return 1;
        } else if (actualDiv >= 2){
            return 0;
        } else{
             
            revert(); 
        }
    }
}
 
 
contract ZethrBankrollBridge{
     
    ZethrInterface Zethr;
   
     
     
     
     
    address[7] UsedBankrollAddresses; 

     
    mapping(address => bool) ValidBankrollAddress;
    
     
    function setupBankrollInterface(address ZethrMainBankrollAddress) internal {
         
        Zethr = ZethrInterface(0xb9ab8eed48852de901c13543042204c6c569b811);
         
        UsedBankrollAddresses = ZethrMainBankroll(ZethrMainBankrollAddress).gameGetTokenBankrollList();
        for(uint i=0; i<7; i++){
            ValidBankrollAddress[UsedBankrollAddresses[i]] = true;
        }
    }
    
     
    modifier fromBankroll(){
        require(ValidBankrollAddress[msg.sender], "msg.sender should be a valid bankroll");
        _;
    }
    
     
     
    function RequestBankrollPayment(address to, uint tokens, uint userDivRate) internal {
        uint tier = ZethrTierLibrary.getTier(userDivRate);
        address tokenBankrollAddress = UsedBankrollAddresses[tier];
        ZethrTokenBankroll(tokenBankrollAddress).gameRequestTokens(to, tokens);
    }
}

 
contract ZethrShell is ZethrBankrollBridge{
    
     
    function WithdrawToBankroll() public {
        address(UsedBankrollAddresses[0]).transfer(address(this).balance);
    }
    
     
    function WithdrawAndTransferToBankroll() public {
        Zethr.withdraw();
        WithdrawToBankroll();
    }
}

 
 
contract Zethroll is ZethrShell {
  using SafeMath for uint;

   
   
  modifier betIsValid(uint _betSize, uint _playerNumber, uint divRate) {
     require(  calculateProfit(_betSize, _playerNumber) < getMaxProfit(divRate)
             && _betSize >= minBet
             && _playerNumber >= minNumber
             && _playerNumber <= maxNumber);
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
  uint public maxNumber = 90;
  uint public minNumber = 10;
  uint constant public houseEdgeDivisor = 1000;

   
  bool public gamePaused;
  bool public canMining = true;
  uint public miningProfit = 100;
  uint public minBetMining = 1e18;
  address public owner;

  mapping (uint => uint) public contractBalance;
  mapping (uint => uint) public maxProfit;
  uint public houseEdge;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet = 0;

   
  uint public totalBets;
  uint public totalZTHWagered;

   

   
  event LogBet(address sender, uint value, uint rollUnder);

   
   
  event LogResult(address player, uint result, uint rollUnder, uint profit, uint tokensBetted, bool won);

   
  event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

   
  event MaxProfitChanged(uint _oldMaxProfit, uint _newMaxProfit);

   
  event CurrentContractBalance(uint _tokens);
  
  constructor (address ZethrMainBankrollAddress) public {
    setupBankrollInterface(ZethrMainBankrollAddress);

     
    owner = msg.sender;

     
    houseEdge = 990;

     
    ownerSetMaxProfitAsPercentOfHouse(200000);

     
    ownerSetMinBet(1e18);
    
    canMining = false;
    miningProfit = 100;
    minBetMining = 1e18;
  }

   
   
  function maxRandom(uint blockn, address entropy) public view returns (uint256 randomNumber) {
    return uint256(keccak256(
        abi.encodePacked(
        blockhash(blockn),
        entropy)
      ));
  }

   
  function random(uint256 upper, uint256 blockn, address entropy) public view returns (uint256 randomNumber) {
    return maxRandom(blockn, entropy) % upper;
  }

   
  function calculateProfit(uint _initBet, uint _roll)
    private
    view
    returns (uint)
  {
    return ((((_initBet * (100 - (_roll.sub(1)))) / (_roll.sub(1)) + _initBet)) * houseEdge / houseEdgeDivisor) - _initBet;
  }

   
  struct playerRoll{
    uint192 tokenValue;  
    uint48 blockn;       
    uint8 rollUnder;     
    uint8 divRate;       
  }

   
  mapping(address => playerRoll) public playerRolls;

   
  function _playerRollDice(uint _rollUnder, TKN _tkn, uint userDivRate) private
    gameIsActive
    betIsValid(_tkn.value, _rollUnder, userDivRate)
  {
    require(_tkn.value < ((2 ** 192) - 1));    
    require(block.number < ((2 ** 48) - 1));   
    require(userDivRate < (2 ** 8 - 1));  
     
     

    playerRoll memory roll = playerRolls[_tkn.sender];

     
    require(block.number != roll.blockn);

     
    if (roll.blockn != 0) {
      _finishBet(_tkn.sender);
    }

     
    roll.blockn = uint48(block.number);
    roll.tokenValue = uint192(_tkn.value);
    roll.rollUnder = uint8(_rollUnder);
    roll.divRate = uint8(userDivRate);

     
    playerRolls[_tkn.sender] = roll;

     
    emit LogBet(_tkn.sender, _tkn.value, _rollUnder);
                 
     
    totalBets += 1;

     
    totalZTHWagered += _tkn.value;
    
     
    if(canMining && roll.tokenValue >= minBetMining){
        uint miningAmout = SafeMath.div(SafeMath.mul(roll.tokenValue, miningProfit) , 10000);
        RequestBankrollPayment(_tkn.sender, miningAmout, roll.divRate);
    }
  }

   
  function finishBet() public
    gameIsActive
    returns (uint)
  {
    return _finishBet(msg.sender);
  }

   
  function _finishBet(address target) private returns (uint){
    playerRoll memory roll = playerRolls[target];
    require(roll.tokenValue > 0);  
    require(roll.blockn != block.number);
     
     
    uint result;
    if (block.number - roll.blockn > 255) {
      result = 1000;  
    } else {
       
      result = random(100, roll.blockn, target) + 1;
    }

    uint rollUnder = roll.rollUnder;

    if (result < rollUnder) {
       

       
      uint profit = calculateProfit(roll.tokenValue, rollUnder);
      uint mProfit = getMaxProfit(roll.divRate);
        if (profit > mProfit){
            profit = mProfit;
        }

       
      subContractBalance(roll.divRate, profit);

      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, true);

       
      setMaxProfit(roll.divRate);

       
      playerRolls[target] = playerRoll(uint192(0), uint48(0), uint8(0), uint8(0));

       
      RequestBankrollPayment(target, profit + roll.tokenValue, roll.divRate);
      return result;

    } else {
       
      emit LogResult(target, result, rollUnder, profit, roll.tokenValue, false);

       
      addContractBalance(roll.divRate, roll.tokenValue);
     
      playerRolls[target] = playerRoll(uint192(0), uint48(0), uint8(0), uint8(0));
       
       

       
      setMaxProfit(roll.divRate);
      
      return result;
    }
  }

   
  struct TKN {address sender; uint value;}

   
  function execute(address _from, uint _value, uint userDivRate, bytes _data) public fromBankroll gameIsActive returns (bool) {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      uint8 chosenNumber = uint8(_data[0]);
      _playerRollDice(chosenNumber, _tkn, userDivRate);

    return true;
  }

   
  function setMaxProfit(uint divRate) internal {
     
    maxProfit[divRate] = (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }
 
   
  function getMaxProfit(uint divRate) public view returns (uint){
      return (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }
 
   
  function subContractBalance(uint divRate, uint sub) internal {
      contractBalance[divRate] = contractBalance[divRate].sub(sub);
  }
 
   
  function addContractBalance(uint divRate, uint add) internal {
      contractBalance[divRate] = contractBalance[divRate].add(add);
  }

   
  function ownerUpdateContractBalance(uint newContractBalance, uint divRate) public
  onlyOwner
  {
    contractBalance[divRate] = newContractBalance;
  }
  function ownerUpdateMinMaxNumber(uint newMinNumber, uint newMaxNumber) public
  onlyOwner
  {
    minNumber = newMinNumber;
    maxNumber = newMaxNumber;
  }
   
  function updateContractBalance(uint newContractBalance) public
  onlyOwner
  {
    contractBalance[2] = newContractBalance;
    setMaxProfit(2);
    contractBalance[5] = newContractBalance;
    setMaxProfit(5);
    contractBalance[10] = newContractBalance;
    setMaxProfit(10);
    contractBalance[15] = newContractBalance;
    setMaxProfit(15);
    contractBalance[20] = newContractBalance;
    setMaxProfit(20);
    contractBalance[25] = newContractBalance;
    setMaxProfit(25);
    contractBalance[33] = newContractBalance;
    setMaxProfit(33);
  }  
   
   
   
  function bankrollExternalUpdateTokens(uint divRate, uint newBalance) public fromBankroll {
      contractBalance[divRate] = newBalance;
      setMaxProfit(divRate);
  }

   
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
  onlyOwner
  {
     
    require(newMaxProfitAsPercent <= 200000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit(2);
    setMaxProfit(5);
    setMaxProfit(10);
    setMaxProfit(15);
    setMaxProfit(20);
    setMaxProfit(25);
    setMaxProfit(33);
  }

   
  function ownerSetMinBet(uint newMinimumBet) public
  onlyOwner
  {
    minBet = newMinimumBet;
  }

   
  function ownerSetupBankrollInterface(address ZethrMainBankrollAddress) public
  onlyOwner
  {
    setupBankrollInterface(ZethrMainBankrollAddress);
  }
  function ownerPauseGame(bool newStatus) public
  onlyOwner
  {
    gamePaused = newStatus;
  }
  function ownerSetCanMining(bool newStatus) public
  onlyOwner
  {
    canMining = newStatus;
  }
  function ownerSetMiningProfit(uint newProfit) public
  onlyOwner
  {
    miningProfit = newProfit;
  }
  function ownerSetMinBetMining(uint newMinBetMining) public
  onlyOwner
  {
    minBetMining = newMinBetMining;
  }  
   
  function ownerChangeOwner(address newOwner) public 
  onlyOwner
  {
    owner = newOwner;
  }

   
  function ownerkill() public
  onlyOwner
  {

    selfdestruct(owner);
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