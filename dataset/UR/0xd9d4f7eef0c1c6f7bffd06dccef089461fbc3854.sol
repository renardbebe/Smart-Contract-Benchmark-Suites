 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

contract Lava {

  using SafeMath for uint;

  struct Rand {
      address submitter;
      uint value;
  }

  struct PredUnit {
      address submitter;
      uint value;
  }

  event receivedRand(address indexed _from, uint _value);
  event receivedPred(address indexed _from, uint[] _window);
  event requestedRand(address indexed _from, uint _value);  

  uint MAXRAND = 100;  
  uint RANDPRICE = 857 wei;
  uint RANDDEPOSIT = 1 wei;
  uint PREDWAGER = 1 wei;
  uint CURRIDX = 1;  
  uint nWinners = 0;
  bool predPeat = false;  

  mapping(uint => Rand) private rands;  
  mapping(uint => bool) public randExists;  
  mapping(uint => PredUnit) public winners;  
  mapping(uint => PredUnit[]) public arrIdx2predUnitArr;  
  mapping(uint => bool) public arrIdx2lost;  

  constructor () public payable {
    for (uint i=0; i<MAXRAND; i++) {
      randExists[i] = false;
      arrIdx2lost[i] = false;
    }
    rands[0] = Rand({submitter: address(this), value: 0});
    arrIdx2lost[0] = true;
  }

  function submitRand(uint _value) public payable {
     
     
     
    require(msg.value >= RANDDEPOSIT);
    require(_value >= 1);  
    require(_value <= 65536);  
    Rand memory newRand = Rand({
      submitter: msg.sender,
      value: _value
    });
    if (!arrIdx2lost[CURRIDX]) { rands[CURRIDX].submitter.transfer(RANDDEPOSIT); }  
    rands[CURRIDX] = newRand;
    arrIdx2lost[CURRIDX] = false;
    randExists[CURRIDX] = true;
    if (predPeat) { delete arrIdx2predUnitArr[CURRIDX]; }  
    predPeat = false;
    CURRIDX = (CURRIDX.add(1)).mod(MAXRAND);
    emit receivedRand(msg.sender, _value);
  }

  function submitPredWindow(uint[] _guess) public payable {
     
     
     
     
    require(msg.value >= PREDWAGER.mul(_guess.length));  
    require(_guess.length <= MAXRAND);
    uint outputIdx = wrapSub(CURRIDX, 1, MAXRAND);
    for (uint i=0; i<_guess.length; i++) {
      PredUnit memory newUnit = PredUnit({
        submitter: msg.sender,
        value: _guess[i]
      });
      arrIdx2predUnitArr[(i+outputIdx) % MAXRAND].push(newUnit);
    }
    emit receivedPred(msg.sender, _guess);
  }

  function requestRand() public payable returns (uint) {
     
     
     
     
    require(msg.value >= RANDPRICE);
    uint outputIdx = wrapSub(CURRIDX, 1, MAXRAND);
    uint idx;
    uint val;
    uint i;
    uint reward;
    if (predPeat) {
        reward = RANDPRICE.div(nWinners);
        for (i=0; i<nWinners; i++) { winners[i].submitter.transfer(reward); }  
    } else {
        nWinners = 0;
        for (i=0; i<arrIdx2predUnitArr[outputIdx].length; i++) {
          if (arrIdx2predUnitArr[outputIdx][i].value == rands[outputIdx].value) {
            winners[i] = arrIdx2predUnitArr[outputIdx][i];  
            nWinners++;
          }
        }
        if (nWinners > 0) {  
          if (arrIdx2lost[outputIdx]) { reward = RANDPRICE.div(nWinners); }  
          else { reward = PREDWAGER.add(RANDPRICE.div(nWinners)); }  
          for (i=0; i<nWinners; i++) { winners[i].submitter.transfer(reward); }  
          winners[0].submitter.transfer(address(this).balance);  
          for (i=0; i<MAXRAND; i++) { arrIdx2lost[i] = true; }  
          predPeat = true;
        } else {  
          idx = wrapSub(outputIdx, 0, MAXRAND);
          rands[idx].submitter.transfer(RANDPRICE.div(4));  
          for (i=0; i<MAXRAND; i++) {
            idx = wrapSub(outputIdx, i, MAXRAND);
            val = i.add(2);
            if (randExists[idx]) { rands[idx].submitter.transfer(RANDPRICE.div(val.mul(val))); }
          }
        }
    }
    emit requestedRand(msg.sender, rands[outputIdx].value);
    return rands[outputIdx].value;
  }

  function wrapSub(uint a, uint b, uint c) public pure returns(uint) { return uint(int(a) - int(b)).mod(c); }  

  function () public payable {}
}