 

pragma solidity ^0.4.26;

 
 
 
 

contract FiatDex_protocol_v1 {

  address public owner;  
  uint256 public feeDelay = 7;  
  uint256 public dailyFeeIncrease = 1000;  
  uint256 public version = 1;  

  constructor() public {
    owner = msg.sender;  
  }

  enum States {
    NOTOPEN,
    INITIALIZED,
    ACTIVE,
    CLOSED
  }

  struct Swap {
    States swapState;
    uint256 sendAmount;
    address fiatTrader;
    address ethTrader;
    uint256 openTime;
    uint256 ethTraderCollateral;
    uint256 fiatTraderCollateral;
    uint256 feeAmount;
  }

  mapping (bytes32 => Swap) private swaps;  

  event Open(bytes32 _tradeID, address _fiatTrader, uint256 _sendAmount);  
  event Close(bytes32 _tradeID, uint256 _fee);
  event ChangedOwnership(address _newOwner);

   
  modifier onlyNotOpenSwaps(bytes32 _tradeID) {
    require (swaps[_tradeID].swapState == States.NOTOPEN);
    _;
  }

   
  modifier onlyInitializedSwaps(bytes32 _tradeID) {
    require (swaps[_tradeID].swapState == States.INITIALIZED);
    _;
  }

   
  modifier onlyActiveSwaps(bytes32 _tradeID) {
    require (swaps[_tradeID].swapState == States.ACTIVE);
    _;
  }

   
  function viewSwap(bytes32 _tradeID) public view returns (
    States swapState, 
    uint256 sendAmount,
    address ethTrader, 
    address fiatTrader, 
    uint256 openTime, 
    uint256 ethTraderCollateral, 
    uint256 fiatTraderCollateral,
    uint256 feeAmount
  ) {
    Swap memory swap = swaps[_tradeID];
    return (swap.swapState, swap.sendAmount, swap.ethTrader, swap.fiatTrader, swap.openTime, swap.ethTraderCollateral, swap.fiatTraderCollateral, swap.feeAmount);
  }

  function viewFiatDexSpecs() public view returns (
    uint256 _version, 
    address _owner, 
    uint256 _feeDelay, 
    uint256 _dailyFeeIncrease
  ) {
    return (version, owner, feeDelay, dailyFeeIncrease);
  }

   
  function changeContractOwner(address _newOwner) public {
    require (msg.sender == owner);  
    
    owner = _newOwner;  

      
    emit ChangedOwnership(_newOwner);
  }

   
  function openSwap(bytes32 _tradeID, address _fiatTrader) public onlyNotOpenSwaps(_tradeID) payable {
    require (msg.value > 0);  
     
    uint256 _sendAmount = (msg.value * 2) / 5;  
    require (_sendAmount > 0);  
    uint256 _ethTraderCollateral = msg.value - _sendAmount;  

     
    Swap memory swap = Swap({
      swapState: States.INITIALIZED,
      sendAmount: _sendAmount,
      ethTrader: msg.sender,
      fiatTrader: _fiatTrader,
      openTime: now,
      ethTraderCollateral: _ethTraderCollateral,
      fiatTraderCollateral: 0,
      feeAmount: 0
    });
    swaps[_tradeID] = swap;

     
    emit Open(_tradeID, _fiatTrader, _sendAmount);
  }

   
  function addFiatTraderCollateral(bytes32 _tradeID) public onlyInitializedSwaps(_tradeID) payable {
    Swap storage swap = swaps[_tradeID];  
    require (msg.value >= swap.ethTraderCollateral);  
    require (msg.sender == swap.fiatTrader);  
    swap.fiatTraderCollateral = msg.value;   
    swap.swapState = States.ACTIVE;  
  }

   
  function refundSwap(bytes32 _tradeID) public onlyInitializedSwaps(_tradeID) {
     
    Swap storage swap = swaps[_tradeID];
    require (msg.sender == swap.ethTrader);  
    swap.swapState = States.CLOSED;  

     
    swap.ethTrader.transfer(swap.sendAmount + swap.ethTraderCollateral);

      
    emit Close(_tradeID, 0);
  }

   
  function closeSwap(bytes32 _tradeID) public onlyActiveSwaps(_tradeID) {
     
    Swap storage swap = swaps[_tradeID];
    require (msg.sender == swap.ethTrader);  
    swap.swapState = States.CLOSED;  

     
    uint256 feeAmount = 0;  
    uint256 currentTime = now;
    if(swap.openTime + 86400 * feeDelay < currentTime){
       
      uint256 seconds_over = currentTime - (swap.openTime + 86400 * feeDelay);  
      uint256 feePercent = (dailyFeeIncrease * seconds_over) / 86400;  
       
      if(feePercent > 0){
        if(feePercent > 99000) {feePercent = 99000;}  
         
         
        feeAmount = (swap.ethTraderCollateral * feePercent) / 100000;
      }
    }

     
    if(feeAmount > 0){
      swap.feeAmount = feeAmount;
      owner.transfer(feeAmount * 2);
    }

     
    swap.ethTrader.transfer(swap.ethTraderCollateral - feeAmount);

     
    swap.fiatTrader.transfer(swap.sendAmount + swap.fiatTraderCollateral - feeAmount);

      
    emit Close(_tradeID, feeAmount);
  }
}