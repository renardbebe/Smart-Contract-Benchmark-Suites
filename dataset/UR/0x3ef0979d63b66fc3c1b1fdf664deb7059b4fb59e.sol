 

pragma solidity ^0.4.24;

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 

 
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
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

contract LuckySeven is Ownable {

  using SafeMath for uint256;

  uint256 public minBet;
  uint256 public maxBet;
  bool public paused;
  address public signer;
  address public house;

  mapping (address => uint256) public balances;
  mapping (address => bool) public diceRolled;
  mapping (address => bytes) public betSignature;
  mapping (address => uint256) public betAmount;
  mapping (address => uint256) public betValue;
  mapping (bytes => bool) usedSignatures;

  mapping (address => uint256) public totalDiceRollsByAddress;
  mapping (address => uint256) public totalBetsByAddress;
  mapping (address => uint256) public totalBetsWonByAddress;
  mapping (address => uint256) public totalBetsLostByAddress;

  uint256 public pendingBetsBalance;
  uint256 public belowSevenBets;
  uint256 public aboveSevenBets;
  uint256 public luckySevenBets;

  uint256 public betsWon;
  uint256 public betsLost;

  event Event (
      string name,
      address indexed _better,
      uint256 num1,
      uint256 num2
  );

  constructor(uint256 _minBet, uint256 _maxBet, address _signer, address _house) public {
    minBet = _minBet;
    maxBet = _maxBet;
    signer = _signer;
    house = _house;
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setHouse(address _house) public onlyOwner {
     
    uint256 existingHouseBalance = balances[house];

     
    balances[house] = 0;

     
    house = _house;

     
    balances[house] = balances[house].add(existingHouseBalance);
  }

  function setMinBet(uint256 _minBet) public onlyOwner {
    minBet = _minBet;
  }

  function setMaxBet(uint256 _maxBet) public onlyOwner {
    maxBet = _maxBet;
  }

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  function () external payable {
    topup();
  }

  function topup() payable public {
    require(msg.value > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
  }

  function withdraw(uint256 amount) public {
    require(amount > 0);
    require(balances[msg.sender] >= amount);

    balances[msg.sender] = balances[msg.sender].sub(amount);
    msg.sender.transfer(amount);
  }

  function rollDice(bytes signature) public {
    require(!paused);

     
    require(!usedSignatures[signature]);

     
    usedSignatures[signature] = true;

     
    require(betAmount[msg.sender] == 0);

     
    diceRolled[msg.sender] = true;
    betSignature[msg.sender] = signature;

    totalDiceRollsByAddress[msg.sender] = totalDiceRollsByAddress[msg.sender].add(1);
    emit Event('dice-rolled', msg.sender, 0, 0);
  }

  function placeBet(uint256 amount, uint256 value) public {
    require(!paused);

     
    require(amount >= minBet && amount <= maxBet);
    require(value >= 1 && value <= 3);

     
    require(diceRolled[msg.sender]);

     
    require(betAmount[msg.sender] == 0);

     
    require(balances[msg.sender] >= amount);

     
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[house] = balances[house].add(amount);
    pendingBetsBalance = pendingBetsBalance.add(amount);

     
    betValue[msg.sender] = value;
    betAmount[msg.sender] = amount;

    totalBetsByAddress[msg.sender] = totalBetsByAddress[msg.sender].add(1);
    emit Event('bet-placed', msg.sender, amount, 0);
  }

  function completeBet(bytes32 hash) public returns (uint256, uint256){
     
    require(betAmount[msg.sender] > 0);

     
    require(ECRecovery.recover(hash, betSignature[msg.sender]) == signer);

     
    uint256 num1 = (
      uint256(
        ECRecovery.toEthSignedMessageHash(
          keccak256(
            abi.encodePacked(hash)
          )
        )
      ) % 6
    ) + 1;

    uint256 num2 = (
      uint256(
        ECRecovery.toEthSignedMessageHash(
          sha256(
            abi.encodePacked(hash)
          )
        )
      ) % 6
    ) + 1;
    uint256 num = num1 + num2;
    uint256 value = betValue[msg.sender];
    uint256 winRate = 0;
    if (num <= 6) {
      belowSevenBets = belowSevenBets.add(1);
      if (value == 1) {
        winRate = 2;
      }
    } else if (num == 7) {
      luckySevenBets = luckySevenBets.add(1);
      if (value == 2) {
        winRate = 3;
      }
    } else {
      aboveSevenBets = aboveSevenBets.add(1);
      if (value == 3) {
        winRate = 2;
      }
    }

    uint256 amountWon = betAmount[msg.sender] * winRate;

     
    if (amountWon > 0) {
      balances[house] = balances[house].sub(amountWon);
      balances[msg.sender] = balances[msg.sender].add(amountWon);
      totalBetsWonByAddress[msg.sender] = totalBetsWonByAddress[msg.sender].add(1);
      betsWon = betsWon.add(1);
      emit Event('bet-won', msg.sender, amountWon, num);
    } else {
      totalBetsLostByAddress[msg.sender] = totalBetsLostByAddress[msg.sender].add(1);
      betsLost = betsLost.add(1);
      emit Event('bet-lost', msg.sender, betAmount[msg.sender], num);
    }
    pendingBetsBalance = pendingBetsBalance.sub(betAmount[msg.sender]);

     
    diceRolled[msg.sender] = false;
    betAmount[msg.sender] = 0;
    betValue[msg.sender] = 0;
    betSignature[msg.sender] = '0x';

    return (amountWon, num);
  }
}