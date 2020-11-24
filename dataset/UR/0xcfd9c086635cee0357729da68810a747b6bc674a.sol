 

pragma solidity ^0.4.26;

 
 
 

 

contract NebliDex_AtomicSwap {
  struct Swap {
    uint256 timelock;
    uint256 value;
    address ethTrader;
    address withdrawTrader;
    bytes32 secretLock;
    bytes secretKey;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    EXPIRED
  }

  mapping (bytes32 => Swap) private swaps;
  mapping (bytes32 => States) private swapStates;

  event Open(bytes32 _swapID, address _withdrawTrader);
  event Expire(bytes32 _swapID);
  event Close(bytes32 _swapID, bytes _secretKey);

  modifier onlyInvalidSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.INVALID);
    _;
  }

  modifier onlyOpenSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.OPEN);
    _;
  }

  modifier onlyClosedSwaps(bytes32 _swapID) {
    require (swapStates[_swapID] == States.CLOSED);
    _;
  }

  modifier onlyExpiredSwaps(bytes32 _swapID) {
    require (now >= swaps[_swapID].timelock);
    _;
  }

   
  modifier onlyNotExpiredSwaps(bytes32 _swapID) {
    require (now < swaps[_swapID].timelock);
    _;
  }

  modifier onlyWithSecretKey(bytes32 _swapID, bytes _secretKey) {
    require (_secretKey.length == 33);  
    require (swaps[_swapID].secretLock == sha256(_secretKey));
    _;
  }

  function open(bytes32 _swapID, address _withdrawTrader, uint256 _timelock) public onlyInvalidSwaps(_swapID) payable {
     
     
    Swap memory swap = Swap({
      timelock: _timelock,
      value: msg.value,
      ethTrader: msg.sender,
      withdrawTrader: _withdrawTrader,
      secretLock: _swapID,
      secretKey: new bytes(0)
    });
    swaps[_swapID] = swap;
    swapStates[_swapID] = States.OPEN;

     
    emit Open(_swapID, _withdrawTrader);
  }

  function redeem(bytes32 _swapID, bytes _secretKey) public onlyOpenSwaps(_swapID) onlyNotExpiredSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) {
     
    Swap memory swap = swaps[_swapID];
    swaps[_swapID].secretKey = _secretKey;
    swapStates[_swapID] = States.CLOSED;

     
    swap.withdrawTrader.transfer(swap.value);

     
    emit Close(_swapID, _secretKey);
  }

  function refund(bytes32 _swapID) public onlyOpenSwaps(_swapID) onlyExpiredSwaps(_swapID) {
     
    Swap memory swap = swaps[_swapID];
    swapStates[_swapID] = States.EXPIRED;

     
   swap.ethTrader.transfer(swap.value);

      
    emit Expire(_swapID);
  }

  function check(bytes32 _swapID) public view returns (uint256 timelock, uint256 value, address withdrawTrader, bytes32 secretLock) {
    Swap memory swap = swaps[_swapID];
    return (swap.timelock, swap.value, swap.withdrawTrader, swap.secretLock);
  }

  function checkSecretKey(bytes32 _swapID) public view onlyClosedSwaps(_swapID) returns (bytes secretKey) {
    Swap memory swap = swaps[_swapID];
    return swap.secretKey;
  }
}