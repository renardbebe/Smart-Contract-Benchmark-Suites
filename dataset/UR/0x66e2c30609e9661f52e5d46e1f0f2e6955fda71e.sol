 

pragma solidity
^0.4.21;

 

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
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

contract CryptoPhoenixesCivilWar is Ownable, Pausable {
  using SafeMath for uint256;

  address public subDevOne;
  address public subDevTwo;
  
  Phoenix[] public PHOENIXES;
   
  
  uint256 public DENOMINATOR = 10000;  
  
  uint256[2] public POOLS;  
  uint256[2] public SCORES;  
  
  bool public GAME_STARTED = false;
  uint public GAME_END = 0;
  
   
  mapping (address => uint256) public devFunds;

   
  mapping (address => uint256) public userFunds;

   
  uint256 constant public BASE_PRICE = 0.0025 ether;
  
   
  modifier onlyAuthorized() {
      require(msg.sender == owner || msg.sender == subDevOne);  
      _;
  }
  
   
  modifier gameHasEnded() {
      require(GAME_STARTED);  
      require(now >= GAME_END);  
      _;
  }
  
   
  modifier gameInProgress() {
      require(GAME_STARTED);
      require(now <= GAME_END);
      _;
  }
  
   
  modifier noGameInProgress() {
      require(!GAME_STARTED);
      _;
  }
  
   
  event GameStarted();
      
  event PhoenixPurchased(
      uint256 phoenixID,
      address newOwner,
      uint256 price,
      uint256 nextPrice,
      uint256 currentPower,
      uint abilityAvailTime
  );

  event CaptainAbilityUsed(
      uint256 captainID
  );
  
  event PhoenixAbilityUsed(
      uint256 phoenixID,
      uint256 payout,
      uint256 price,
      uint256 currentPower,
      uint abilityAvailTime,
      address previousOwner
  );
  
  event GameEnded();

  event WithdrewFunds(
    address owner
  );
  
   
  struct Phoenix {
    uint256 price;   
    uint256 payoutPercentage;  
    uint abilityAvailTime;  
    uint cooldown;  
    uint cooldownDecreaseAmt;  
    uint basePower;  
    uint currentPower;  
    uint powerIncreaseAmt;  
    uint powerDrop;  
    uint powerCap;  
    address previousOwner;   
    address currentOwner;  
  }
  
 
  function CryptoPhoenixesCivilWar(address _subDevOne, address _subDevTwo) {
    subDevOne = _subDevOne;
    subDevTwo = _subDevTwo;
    createPhoenixes();
  }

  function createPhoenixes() private {
       
      for (uint256 i = 0; i < 3; i++) {
          Phoenix memory phoenix = Phoenix({
              price: 0.005 ether,
              payoutPercentage: 2400,  
              cooldown: 20 hours,  
              abilityAvailTime: 0,  
               
              cooldownDecreaseAmt: 0,
              basePower: 0,
              currentPower: 0,
              powerIncreaseAmt: 0,
              powerDrop: 0,
              powerCap: 0,
              previousOwner: address(0),
              currentOwner: address(0)
          });
          
          PHOENIXES.push(phoenix);
      }
      
       
      PHOENIXES[0].price = 0.01 ether;
      
       
      uint16[4] memory PAYOUTS = [400,700,1100,1600];  
      uint16[4] memory COOLDOWN = [2 hours, 4 hours, 8 hours, 16 hours];
      uint16[4] memory COOLDOWN_DECREASE = [9 minutes, 15 minutes, 26 minutes, 45 minutes];
      uint8[4] memory POWER_INC_AMT = [25,50,100,175];  
      uint16[4] memory POWER_DROP = [150,300,600,1000];  
      uint16[4] memory CAPPED_POWER = [800,1500,3000,5000];  
      
      
      for (i = 0; i < 4; i++) {
          for (uint256 j = 0; j < 4; j++) {
              phoenix = Phoenix({
              price: BASE_PRICE,
              payoutPercentage: PAYOUTS[j],
              abilityAvailTime: 0,
              cooldown: COOLDOWN[j],
              cooldownDecreaseAmt: COOLDOWN_DECREASE[j],
              basePower: (j+1)*100,  
              currentPower: (j+1)*100,
              powerIncreaseAmt: POWER_INC_AMT[j],
              powerDrop: POWER_DROP[j],
              powerCap: CAPPED_POWER[j],
              previousOwner: address(0),
              currentOwner: address(0)
              });
              
              PHOENIXES.push(phoenix);
          }
      }
  }
  
  function startGame() public noGameInProgress onlyAuthorized {
       
      SCORES[0] = 0;
      SCORES[1] = 0;
      
       
      for (uint i = 1; i < 19; i++) {
          PHOENIXES[i].abilityAvailTime = now + PHOENIXES[i].cooldown;
      }
      
      GAME_STARTED = true;
       
      GAME_END = now + 1 days;
      emit GameStarted();
  }
  
   
  function setPhoenixOwners(address[19] _owners) onlyOwner public {
      require(PHOENIXES[0].previousOwner == address(0));  
      for (uint256 i = 0; i < 19; i++) {
          Phoenix storage phoenix = PHOENIXES[i];
          phoenix.previousOwner = _owners[i];
          phoenix.currentOwner = _owners[i];
      }
  }

function purchasePhoenix(uint256 _phoenixID) whenNotPaused gameInProgress public payable {
       
      require(_phoenixID < 19);
    
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
       
      uint256 price = phoenix.price;
      
       
      require(phoenix.currentOwner != address(0));  
      require(msg.value >= phoenix.price);
      require(phoenix.currentOwner != msg.sender);  
      
      uint256 outgoingOwnerCut;
      uint256 purchaseExcess;
      uint256 poolCut;
      uint256 rainbowCut;
      uint256 captainCut;
      
      (outgoingOwnerCut, 
      purchaseExcess, 
      poolCut,
      rainbowCut,
      captainCut) = calculateCuts(msg.value,price);
      
       
      userFunds[phoenix.previousOwner] = userFunds[phoenix.previousOwner].add(captainCut); 
      
       
      if (_phoenixID == 0) {
          outgoingOwnerCut = outgoingOwnerCut.add(rainbowCut).add(captainCut);
          rainbowCut = 0;  
          poolCut = poolCut.div(2);  
          POOLS[0] = POOLS[0].add(poolCut);  
          POOLS[1] = POOLS[1].add(poolCut);  
          
      } else if (_phoenixID < 3) {  
          outgoingOwnerCut = outgoingOwnerCut.add(captainCut);
          uint256 poolID = _phoenixID.sub(1);  
          POOLS[poolID] = POOLS[poolID].add(poolCut);
          
      } else if (_phoenixID < 11) {  
           
          userFunds[PHOENIXES[1].currentOwner] = userFunds[PHOENIXES[1].currentOwner].add(captainCut);
          upgradePhoenixStats(_phoenixID);
          POOLS[0] = POOLS[0].add(poolCut);  
      } else {
           
          userFunds[PHOENIXES[2].currentOwner] = userFunds[PHOENIXES[2].currentOwner].add(captainCut);
          upgradePhoenixStats(_phoenixID);
          POOLS[1] = POOLS[1].add(poolCut);  
      }
      
       
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(rainbowCut);

       
      phoenix.price = getNextPrice(price);
      
       
      sendFunds(phoenix.currentOwner, outgoingOwnerCut);
    
       
      phoenix.currentOwner = msg.sender;

       
      if (purchaseExcess > 0) {
        sendFunds(msg.sender,purchaseExcess);
      }
      
       
      emit PhoenixPurchased(_phoenixID, msg.sender, price, phoenix.price, phoenix.currentPower, phoenix.abilityAvailTime);
  }
  
  function calculateCuts(
      uint256 _amtPaid,
      uint256 _price
      )
      private
      returns (uint256 outgoingOwnerCut, uint256 purchaseExcess, uint256 poolCut, uint256 rainbowCut, uint256 captainCut)
      {
      outgoingOwnerCut = _price;
      purchaseExcess = _amtPaid.sub(_price);
      
       
      uint256 excessPoolCut = purchaseExcess.div(20);  
      purchaseExcess = purchaseExcess.sub(excessPoolCut);
      
       
      uint256 cut = _price.mul(3).div(100);  
      outgoingOwnerCut = outgoingOwnerCut.sub(cut);
      distributeDevCut(cut);
      
       
       
      captainCut = _price.div(100);  
      outgoingOwnerCut = outgoingOwnerCut.sub(captainCut).sub(captainCut);  
      
       
      rainbowCut = _price.mul(2).div(100);  
      outgoingOwnerCut = outgoingOwnerCut.sub(rainbowCut);
      
       
      poolCut = calculatePoolCut(_price);
      outgoingOwnerCut = outgoingOwnerCut.sub(poolCut);
       
      poolCut = poolCut.add(excessPoolCut);
  }
  
  function distributeDevCut(uint256 _cut) private {
      devFunds[owner] = devFunds[owner].add(_cut.div(2));  
      devFunds[subDevOne] = devFunds[subDevOne].add(_cut.div(4));  
      devFunds[subDevTwo] = devFunds[subDevTwo].add(_cut.div(4));  
  }
  
 
  function getNextPrice (uint256 _price) private pure returns (uint256 _nextPrice) {
    if (_price < 0.25 ether) {
      return _price.mul(3).div(2);  
    } else if (_price < 1 ether) {
      return _price.mul(14).div(10);  
    } else {
      return _price.mul(13).div(10);  
    }
  }
  
  function calculatePoolCut (uint256 _price) private pure returns (uint256 poolCut) {
      if (_price < 0.25 ether) {
          poolCut = _price.mul(13).div(100);  
      } else if (_price < 1 ether) {
          poolCut = _price.mul(12).div(100);  
      } else {
          poolCut = _price.mul(11).div(100);  
      }
  }
 
  function upgradePhoenixStats(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
       
      phoenix.currentPower = phoenix.currentPower.add(phoenix.powerIncreaseAmt);
       
      if (phoenix.currentPower > phoenix.powerCap) {
          phoenix.currentPower = phoenix.powerCap;
      }
       
       
      phoenix.abilityAvailTime = phoenix.abilityAvailTime.sub(phoenix.cooldownDecreaseAmt);
  }
  
  function useCaptainAbility(uint256 _captainID) whenNotPaused gameInProgress public {
      require(_captainID > 0 && _captainID < 3);  
      Phoenix storage captain = PHOENIXES[_captainID];
      require(msg.sender == captain.currentOwner);  
      require(now >= captain.abilityAvailTime);  
      
      if (_captainID == 1) {  
          uint groupIDStart = 3;  
          uint groupIDEnd = 11;  
      } else {
          groupIDStart = 11; 
          groupIDEnd = 19; 
      }
      
      for (uint i = groupIDStart; i < groupIDEnd; i++) {
           
          PHOENIXES[i].currentPower = PHOENIXES[i].currentPower.mul(3).div(2); 
           
          if (PHOENIXES[i].currentPower > PHOENIXES[i].powerCap) {
              PHOENIXES[i].currentPower = PHOENIXES[i].powerCap;
          }
      }
      
      captain.abilityAvailTime = GAME_END + 10 seconds;  
      
      emit CaptainAbilityUsed(_captainID);
  }
  
  function useAbility(uint256 _phoenixID) whenNotPaused gameInProgress public {
       
      require(_phoenixID > 2);
      require(_phoenixID < 19);
      
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      require(msg.sender == phoenix.currentOwner);  
      require(now >= phoenix.abilityAvailTime);  

       
       
       
      if (_phoenixID >=7 &&  _phoenixID <= 14) {
          require(POOLS[1] > 0);  
          uint256 payout = POOLS[1].mul(phoenix.currentPower).div(DENOMINATOR);  
          POOLS[1] = POOLS[1].sub(payout);  
      } else {
          require(POOLS[0] > 0);  
          payout = POOLS[0].mul(phoenix.currentPower).div(DENOMINATOR);
          POOLS[0] = POOLS[0].sub(payout);
      }
      
       
      if (_phoenixID < 11) {  
          bool isRed = true;  
          SCORES[0] = SCORES[0].add(payout);  
      } else {
           
          isRed = false;
          SCORES[1] = SCORES[1].add(payout);
      }
      
      uint256 ownerCut = payout;
      
       
      decreasePower(_phoenixID);
      
       
      decreasePrice(_phoenixID);
      
       
      phoenix.abilityAvailTime = now + phoenix.cooldown;

       
      phoenix.previousOwner = msg.sender;
      
       
       
      uint256 cut = payout.div(50);  
      ownerCut = ownerCut.sub(cut);
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(cut);
      
       
      cut = payout.div(100);  
      ownerCut = ownerCut.sub(cut);
      distributeDevCut(cut);
      
       
      cut = payout.mul(9).div(100);  
      ownerCut = ownerCut.sub(cut);
      distributeTeamCut(isRed,cut);
      
       
      sendFunds(msg.sender,ownerCut);
      
      emit PhoenixAbilityUsed(_phoenixID,ownerCut,phoenix.price,phoenix.currentPower,phoenix.abilityAvailTime,phoenix.previousOwner);
  }
  
  function decreasePrice(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      if (phoenix.price >= 0.75 ether) {
        phoenix.price = phoenix.price.mul(20).div(100);  
      } else {
        phoenix.price = phoenix.price.mul(10).div(100);  
        if (phoenix.price < BASE_PRICE) {
          phoenix.price = BASE_PRICE;
          }
      }
  }
  
  function decreasePower(uint256 _phoenixID) private {
      Phoenix storage phoenix = PHOENIXES[_phoenixID];
      phoenix.currentPower = phoenix.currentPower.sub(phoenix.powerDrop);
       
      if (phoenix.currentPower < phoenix.basePower) {
          phoenix.currentPower = phoenix.basePower; 
      }
  }
  
  function distributeTeamCut(bool _isRed, uint256 _cut) private {
       
      
      if (_isRed) {
          uint captainID = 1;
          uint groupIDStart = 3;
          uint groupIDEnd = 11;
      } else {
          captainID = 2;
          groupIDStart = 11;
          groupIDEnd = 19;
      }
      
       
      uint256 payout = PHOENIXES[captainID].payoutPercentage.mul(_cut).div(DENOMINATOR);
      userFunds[PHOENIXES[captainID].currentOwner] = userFunds[PHOENIXES[captainID].currentOwner].add(payout);
      
      for (uint i = groupIDStart; i < groupIDEnd; i++) {
           
          payout = PHOENIXES[i].payoutPercentage.mul(_cut).div(DENOMINATOR);
           
          userFunds[PHOENIXES[i].currentOwner] = userFunds[PHOENIXES[i].currentOwner].add(payout);
      }
  }
  
  function endGame() gameHasEnded public {
      GAME_STARTED = false;  
      uint256 remainingPoolAmt = POOLS[0].add(POOLS[1]);  
      
       
      uint256 rainbowCut = remainingPoolAmt.mul(15).div(100);  
      uint256 teamCut = remainingPoolAmt.mul(75).div(100);  
      remainingPoolAmt = remainingPoolAmt.sub(rainbowCut).sub(teamCut);
      
       
      userFunds[PHOENIXES[0].currentOwner] = userFunds[PHOENIXES[0].currentOwner].add(rainbowCut);
      
       
       
      if (SCORES[0] == SCORES[1]) {
          teamCut = teamCut.div(2);
          distributeTeamCut(true,teamCut);  
          distributeTeamCut(false,teamCut);  
      } else {
           
          uint256 losingTeamCut = teamCut.div(3);  
           
           
          distributeTeamCut((SCORES[0] > SCORES[1]),losingTeamCut);
          
           
          teamCut = teamCut.sub(losingTeamCut);  
           
          distributeTeamCut(!(SCORES[0] > SCORES[1]),teamCut); 
      }
      
       
      POOLS[0] = remainingPoolAmt.div(2);
      POOLS[1] = POOLS[0];
      
      resetPhoenixes();
      emit GameEnded();
  }
  
  function resetPhoenixes() private {
       
      PHOENIXES[0].price = 0.01 ether;
      PHOENIXES[1].price = 0.005 ether;
      PHOENIXES[2].price = 0.005 ether;
      
      for (uint i = 0; i < 3; i++) {
          PHOENIXES[i].previousOwner = PHOENIXES[i].currentOwner;
      }
      
      for (i = 3; i < 19; i++) {
           
           
          Phoenix storage phoenix = PHOENIXES[i];
          phoenix.price = BASE_PRICE;
          phoenix.currentPower = phoenix.basePower;
          phoenix.previousOwner = phoenix.currentOwner;
      }
  }
  
 
  function sendFunds(address _user, uint256 _payout) private {
    if (!_user.send(_payout)) {
      userFunds[_user] = userFunds[_user].add(_payout);
    }
  }

 
  function devWithdraw() public {
    uint256 funds = devFunds[msg.sender];
    require(funds > 0);
    devFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

 
  function withdrawFunds() public {
    uint256 funds = userFunds[msg.sender];
    require(funds > 0);
    userFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
    emit WithdrewFunds(msg.sender);
  }

  
 function upgradeContract(address _newContract) public onlyOwner whenPaused {
        _newContract.transfer(address(this).balance);
 }
}