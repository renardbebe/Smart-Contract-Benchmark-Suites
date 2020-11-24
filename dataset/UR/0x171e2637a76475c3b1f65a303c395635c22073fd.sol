 

pragma solidity ^0.4.24;

 

 
contract ZethrTokenBankroll{
   
  function gameRequestTokens(address target, uint tokens) public;
  function gameTokenAmount(address what) public returns (uint);
}

 
contract ZethrMainBankroll{
  function gameGetTokenBankrollList() public view returns (address[7]);
}

 
contract ZethrInterface{
  function withdraw() public;
}

 
library ZethrTierLibrary{

  function getTier(uint divRate) 
    internal 
    pure 
    returns (uint)
  {
     
     
        
     
     
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

 
contract ZlotsJackpotHoldingContract {
  function payOutWinner(address winner) public; 
  function getJackpot() public view returns (uint);
}
 
 
contract ZethrBankrollBridge {
   
  ZethrInterface Zethr;
   
   
   
   
  address[7] UsedBankrollAddresses; 

   
  mapping(address => bool) ValidBankrollAddress;
    
   
  function setupBankrollInterface(address ZethrMainBankrollAddress) 
    internal 
  {
     
    Zethr = ZethrInterface(0xb9ab8eed48852de901c13543042204c6c569b811);

     
    UsedBankrollAddresses = ZethrMainBankroll(ZethrMainBankrollAddress).gameGetTokenBankrollList();
    for(uint i=0; i<7; i++){
      ValidBankrollAddress[UsedBankrollAddresses[i]] = true;
    }
  }
    
   
  modifier fromBankroll() {
    require(ValidBankrollAddress[msg.sender], "msg.sender should be a valid bankroll");
    _;
  }
    
   
   
  function RequestBankrollPayment(address to, uint tokens, uint tier) 
    internal 
  {
    address tokenBankrollAddress = UsedBankrollAddresses[tier];
    ZethrTokenBankroll(tokenBankrollAddress).gameRequestTokens(to, tokens);
  }
    
  function getZethrTokenBankroll(uint divRate) 
    public 
    view 
    returns (ZethrTokenBankroll)
  {
    return ZethrTokenBankroll(UsedBankrollAddresses[ZethrTierLibrary.getTier(divRate)]);
  }
}

 
contract ZethrShell is ZethrBankrollBridge {

   
  function WithdrawToBankroll() 
    public 
  {
    address(UsedBankrollAddresses[0]).transfer(address(this).balance);
  }

   
  function WithdrawAndTransferToBankroll() 
    public 
  {
    Zethr.withdraw();
    WithdrawToBankroll();
  }
}

 
 
contract ZlotsMulti is ZethrShell {
  using SafeMath for uint;

   

   
  event HouseRetrievedTake(
    uint timeTaken,
    uint tokensWithdrawn
  );

   
  event TokensWagered(
    address _wagerer,
    uint _wagered
  );

  event LogResult(
    address _wagerer,
    uint _result,
    uint _profit,
    uint _wagered,
    uint _category,
    bool _win
  );

   
  event Loss(address _wagerer, uint _block);                   
  event ThreeMoonJackpot(address _wagerer, uint _block);       
  event TwoMoonPrize(address _wagerer, uint _block);           
  event ZTHPrize(address _wagerer, uint _block);               
  event ThreeZSymbols(address _wagerer, uint _block);          
  event ThreeTSymbols(address _wagerer, uint _block);          
  event ThreeHSymbols(address _wagerer, uint _block);          
  event ThreeEtherIcons(address _wagerer, uint _block);        
  event ThreePurplePyramids(address _wagerer, uint _block);    
  event ThreeGoldPyramids(address _wagerer, uint _block);      
  event ThreeRockets(address _wagerer, uint _block);           
  event OneMoonPrize(address _wagerer, uint _block);           
  event OneOfEachPyramidPrize(address _wagerer, uint _block);  
  event TwoZSymbols(address _wagerer, uint _block);            
  event TwoTSymbols(address _wagerer, uint _block);            
  event TwoHSymbols(address _wagerer, uint _block);            
  event TwoEtherIcons(address _wagerer, uint _block);          
  event TwoPurplePyramids(address _wagerer, uint _block);      
  event TwoGoldPyramids(address _wagerer, uint _block);        
  event TwoRockets(address _wagerer, uint _block);             
  event SpinConcluded(address _wagerer, uint _block);          

   

   
   
  modifier betIsValid(uint _betSize, uint divRate, uint8 spins) {
    require(_betSize.div(spins).mul(50) <= getMaxProfit(divRate));
    require(_betSize.div(spins) >= minBet);
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

   
  modifier onlyBankroll {
    require(msg.sender == bankroll);
    _;
  }

   
  modifier onlyOwnerOrBankroll {
    require(msg.sender == owner || msg.sender == bankroll);
    _;
  }

   

   
  uint constant public maxProfitDivisor = 1000000;
  uint constant public houseEdgeDivisor = 1000;
  mapping (uint => uint) public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet = 1e18;
  address public zlotsJackpot;
  address private owner;
  address private bankroll;
  bool public gamePaused;
  bool public canMining = true;
  uint public miningProfit = 100;
  uint public minBetMining = 1e18;
   
  uint  public totalSpins;
  uint  public totalZTHWagered;
  mapping (uint => uint) public contractBalance;
    
   
   

   
  address private ZTHTKNADDR;
  address private ZTHBANKROLL;

   

   
  constructor(address BankrollAddress) 
    public 
  {
     
    setupBankrollInterface(BankrollAddress); 

     
    owner = msg.sender;

     
    ownerSetMaxProfitAsPercentOfHouse(500000);

     
    bankroll      = ZTHBANKROLL;
     

     
    ownerSetMinBet(1e18);
    
    canMining = true;
    miningProfit = 100;
    minBetMining = 1e18;
  }

   
  function() public payable {  }

   
  struct TKN { address sender; uint value; }
  function execute(address _from, uint _value, uint divRate, bytes _data) 
    public 
    fromBankroll gameIsActive
    returns (bool)
  {
      TKN memory _tkn;
      _tkn.sender = _from;
      _tkn.value = _value;
      _spinTokens(_tkn, divRate, uint8(_data[0]));
      return true;
  }

  struct playerSpin {
    uint192 tokenValue;  
    uint48 blockn;       
    uint8 tier;
    uint8 spins;
    uint divRate;
  }

   
  mapping(address => playerSpin) public playerSpins;

   
  function _spinTokens(TKN _tkn, uint divRate, uint8 spins) 
    private gameIsActive
    betIsValid(_tkn.value, divRate, spins)
  {
     
    require(block.number <= ((2 ** 48) - 1));   
    require(_tkn.value <= ((2 ** 192) - 1));
    require(divRate < (2 ** 8 - 1));  
    address _customerAddress = _tkn.sender;
    uint    _wagered         = _tkn.value;

    playerSpin memory spin = playerSpins[_tkn.sender];
 
     
     
     
    addContractBalance(divRate, _wagered);

     
    require(block.number != spin.blockn);

     
    if (spin.blockn != 0) {
      _finishSpin(_tkn.sender);
    }

     
    spin.blockn = uint48(block.number);
    spin.tokenValue = uint192(_wagered.div(spins));
    spin.tier = uint8(ZethrTierLibrary.getTier(divRate));
    spin.divRate = divRate;
    spin.spins = spins;

     
    playerSpins[_tkn.sender] = spin;

     
    totalSpins += spins;

     
    totalZTHWagered += _wagered;

     
    if(canMining && spin.tokenValue >= minBetMining){
        uint miningAmout = SafeMath.div(SafeMath.mul(spin.tokenValue, miningProfit) , 10000);
        RequestBankrollPayment(_tkn.sender, miningAmout, spin.divRate);
    }

    emit TokensWagered(_customerAddress, _wagered);
  }

   
  function finishSpin() 
    public
    gameIsActive
    returns (uint[])
  {
    return _finishSpin(msg.sender);
  }

   
  struct rollData {
    uint win;
    uint loss; 
    uint jp;
  }

   
  function _finishSpin(address target)
    private 
    returns (uint[])
  {
    playerSpin memory spin = playerSpins[target];

    require(spin.tokenValue > 0);  
    require(spin.blockn != block.number);
        
    uint[] memory output = new uint[](spin.spins);
    rollData memory outcomeTrack = rollData(0,0,0);
    uint category = 0;
    uint profit;
    uint playerDivrate = spin.divRate;
        
    for(uint i=0; i<spin.spins; i++) {
        
       
       
      uint result;
      if (block.number - spin.blockn > 255) {
        result = 1000000;  
        output[i] = 1000000;
      } else {
         
         
        result = random(1000000, spin.blockn, target, i) + 1;
        output[i] = result;
      }

      if (result > 506856) {
         

         
         
        outcomeTrack.loss += spin.tokenValue/100;

        emit Loss(target, spin.blockn);
        emit LogResult(target, result, profit, spin.tokenValue, category, false);
      } else if (result < 2) {
         
      
         
        profit = ZlotsJackpotHoldingContract(zlotsJackpot).getJackpot();
        category = 1;
    
         
        emit ThreeMoonJackpot(target, spin.blockn);
        emit LogResult(target, result, profit, spin.tokenValue, category, true);

        outcomeTrack.jp += 1;

      } else {
        if (result < 299) {
           
          profit = SafeMath.mul(spin.tokenValue, 50);
          category = 2;
          emit TwoMoonPrize(target, spin.blockn);
        } else if (result < 3128) {
           
          profit = SafeMath.mul(spin.tokenValue, 20);
          category = 3;
          emit ZTHPrize(target, spin.blockn);
        } else if (result < 16961) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 4;
          emit ThreeZSymbols(target, spin.blockn);
        } else if (result < 30794) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 5;
          emit ThreeTSymbols(target, spin.blockn);
        } else if (result < 44627) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 30), 10);
          category = 6;
          emit ThreeHSymbols(target, spin.blockn);
        } else if (result < 46627) {
           
          profit = SafeMath.mul(spin.tokenValue, 11);
          category = 7;
          emit ThreeEtherIcons(target, spin.blockn);
        } else if (result < 49127) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 75), 10);
          category = 8;
          emit ThreePurplePyramids(target, spin.blockn);
        } else if (result < 51627) {
           
          profit = SafeMath.mul(spin.tokenValue, 9);
          category = 9;
          emit ThreeGoldPyramids(target, spin.blockn);
        } else if (result < 53127) {
           
          profit = SafeMath.mul(spin.tokenValue, 13);
          category = 10;
          emit ThreeRockets(target, spin.blockn);
        } else if (result < 82530) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 25),10);
          category = 11;
          emit OneMoonPrize(target, spin.blockn);
        } else if (result < 150423) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 15),10);
          category = 12;
          emit OneOfEachPyramidPrize(target, spin.blockn);
        } else if (result < 203888) {
           
          profit = spin.tokenValue;
          category = 13;
          emit TwoZSymbols(target, spin.blockn);
        } else if (result < 257353) {
           
          profit = spin.tokenValue;
          category = 14;
          emit TwoTSymbols(target, spin.blockn);
        } else if (result < 310818) {
           
          profit = spin.tokenValue;
          category = 15;
          emit TwoHSymbols(target, spin.blockn);
        } else if (result < 364283) {
           
          profit = SafeMath.mul(spin.tokenValue, 2);
          category = 16;
          emit TwoEtherIcons(target, spin.blockn);
        } else if (result < 417748) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 125), 100);
          category = 17;
          emit TwoPurplePyramids(target, spin.blockn);
        } else if (result < 471213) {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 133), 100);
          category = 18;
          emit TwoGoldPyramids(target, spin.blockn);
        } else {
           
          profit = SafeMath.div(SafeMath.mul(spin.tokenValue, 25), 10);
          category = 19;
          emit TwoRockets(target, spin.blockn);
        }

        uint newMaxProfit = getNewMaxProfit(playerDivrate, outcomeTrack.win);
        if (profit > newMaxProfit){
          profit = newMaxProfit;
        }

        emit LogResult(target, result, profit, spin.tokenValue, category, true);
        outcomeTrack.win += profit;
      }
    }

    playerSpins[target] = playerSpin(uint192(0), uint48(0), uint8(0), uint8(0),  uint(0));
    if (outcomeTrack.jp > 0) {
      for (i = 0; i < outcomeTrack.jp; i++) {
         
        ZlotsJackpotHoldingContract(zlotsJackpot).payOutWinner(target);
      }
    }

    if (outcomeTrack.win > 0) {
      RequestBankrollPayment(target, outcomeTrack.win, spin.tier);
    }

    if (outcomeTrack.loss > 0) {
       
       
      RequestBankrollPayment(zlotsJackpot, outcomeTrack.loss, spin.tier);
    }
            
    emit SpinConcluded(target, spin.blockn);
    return output;
  }   

   
   
  function maxRandom(uint blockn, address entropy, uint index) 
    private 
    view
    returns (uint256 randomNumber) 
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(blockn),
          entropy,
          index
    )));
  }

   
  function random(uint256 upper, uint256 blockn, address entropy, uint index)
    internal 
    view 
    returns (uint256 randomNumber)
  {
    return maxRandom(blockn, entropy, index) % upper;
  }

   
  function setMaxProfit(uint divRate) 
    internal 
  {
    maxProfit[divRate] = (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor; 
  } 

   
  function getMaxProfit(uint divRate) 
    public 
    view 
    returns (uint) 
  {
    return (contractBalance[divRate] * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

  function getNewMaxProfit(uint divRate, uint currentWin) 
    public 
    view 
    returns (uint) 
  {
    return ((contractBalance[divRate] - currentWin) * maxProfitAsPercentOfHouse) / maxProfitDivisor;
  }

   
  function subContractBalance(uint divRate, uint sub) 
    internal 
  {
    contractBalance[divRate] = contractBalance[divRate].sub(sub);
  }

   
  function addContractBalance(uint divRate, uint add) 
    internal 
  {
    contractBalance[divRate] = contractBalance[divRate].add(add);
  }
   
  function ownerUpdateContractBalance(uint newContractBalance, uint divRate) public
  onlyOwner
  {
    contractBalance[divRate] = newContractBalance;
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
   
   
   
  function bankrollExternalUpdateTokens(uint divRate, uint newBalance) 
    public 
    fromBankroll 
  {
    contractBalance[divRate] = newBalance;
    setMaxProfit(divRate);
  }

   
   
  function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) 
    public
    onlyOwner
  {
     
    require(newMaxProfitAsPercent <= 500000);
    maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
    setMaxProfit(2);
    setMaxProfit(5);
    setMaxProfit(10);
    setMaxProfit(15); 
    setMaxProfit(20);
    setMaxProfit(25);
    setMaxProfit(33);
  }

   
  function ownerSetMinBet(uint newMinimumBet) 
    public
    onlyOwner
  {
    minBet = newMinimumBet;
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
   
  function ownerSetZlotsAddress(address zlotsAddress) 
    public
    onlyOwner
  {
    zlotsJackpot = zlotsAddress;
  }

   
   

   
  function changeOwner(address _newOwner) 
    public 
    onlyOwnerOrBankroll 
  {
    owner = _newOwner;
  }

   
  function changeBankroll(address _newBankroll) 
    public 
    onlyOwnerOrBankroll 
  {
    bankroll = _newBankroll;
  }

   
  function _zthToken(address _tokenContract) 
    private 
    view 
    returns (bool) 
  {
    return _tokenContract == ZTHTKNADDR;
  }
}

 
library SafeMath {

   
  function mul(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    uint c = a / b;
    return c;
  }

   
  function sub(uint a, uint b) 
    internal 
    pure 
    returns (uint) 
  {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) 
    internal 
    pure returns (uint) 
  {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}