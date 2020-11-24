 

pragma solidity ^0.4.18;

contract CoinStacks {

   
  address private admin;

   
  uint256 private constant BOTTOM_LAYER_BET = 0.005 ether;
  uint16 private constant INITIAL_UNLOCKED_COLUMNS = 10;
  uint256 private maintenanceFeePercent;
  uint private  NUM_COINS_TO_HIT_JACKPOT = 30;  
  uint private MIN_AVG_HEIGHT = 5;
  uint256 private constant JACKPOT_PRIZE = 2 * BOTTOM_LAYER_BET;

   
   
   
   
   
   
   
   
   
   
   

  mapping(uint32 => address) public coordinatesToAddresses;
  uint32[] public coinCoordinates;

   
  uint256 public reserveForJackpot;

   
  mapping(address => uint256) public balances;

   
  event coinPlacedEvent (
    uint32 _coord,
    address indexed _coinOwner
  );

  function CoinStacks() public {
    admin = msg.sender;
    maintenanceFeePercent = 1;  
    reserveForJackpot = 0;

     
    coordinatesToAddresses[uint32(0)] = admin;
    coinCoordinates.push(uint32(0));
    coinPlacedEvent(uint32(0),admin);
  }

  function isThereACoinAtCoordinates(uint16 _x, uint16 _y) public view returns (bool){
    return coordinatesToAddresses[(uint32(_x) << 16) | uint16(_y)] != 0;
  }

  function getNumCoins() external view returns (uint){
    return coinCoordinates.length;
  }

  function getAllCoins() external view returns (uint32[]){
    return coinCoordinates;
  }

  function placeCoin(uint16 _x, uint16 _y) external payable{
     
    require(!isThereACoinAtCoordinates(_x,_y));
     
    require(_y==0 || isThereACoinAtCoordinates(_x,_y-1));
     
    require(_x<INITIAL_UNLOCKED_COLUMNS || coinCoordinates.length >= MIN_AVG_HEIGHT * _x);

    uint256 betAmount = BOTTOM_LAYER_BET * (uint256(1) << _y);  

     
    require(balances[msg.sender] + msg.value >= betAmount);

     
     
    balances[msg.sender] += (msg.value - betAmount);

    uint32 coinCoord = (uint32(_x) << 16) | uint16(_y);

    coinCoordinates.push(coinCoord);
    coordinatesToAddresses[coinCoord] = msg.sender;

    if(_y==0) {  
      if(reserveForJackpot < JACKPOT_PRIZE) {  
        reserveForJackpot += BOTTOM_LAYER_BET;
      } else {  
        balances[admin]+= BOTTOM_LAYER_BET;
      }
    } else {  
      uint256 adminFee = betAmount * maintenanceFeePercent /100;
      balances[coordinatesToAddresses[(uint32(_x) << 16) | _y-1]] +=
        (betAmount - adminFee);
      balances[admin] += adminFee;
    }

     
    if(coinCoordinates.length % NUM_COINS_TO_HIT_JACKPOT == 0){
      balances[msg.sender] += reserveForJackpot;
      reserveForJackpot = 0;
    }

     
    coinPlacedEvent(coinCoord,msg.sender);
  }

   
  function withdrawBalance(uint256 _amountToWithdraw) external{
    require(_amountToWithdraw != 0);
    require(balances[msg.sender] >= _amountToWithdraw);
     
    balances[msg.sender] -= _amountToWithdraw;

    msg.sender.transfer(_amountToWithdraw);
  }

   
  function transferOwnership(address _newOwner) external {
    require (msg.sender == admin);
    admin = _newOwner;
  }

   
  function setFeePercent(uint256 _newPercent) external {
    require (msg.sender == admin);
    if(_newPercent<=2)  
      maintenanceFeePercent = _newPercent;
  }

   
  function() external payable{
     
    balances[admin] += msg.value;
  }
}