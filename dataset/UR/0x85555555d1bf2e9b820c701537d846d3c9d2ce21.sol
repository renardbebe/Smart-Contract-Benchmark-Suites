 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 

contract HotBlock {
  uint constant public MIN_COMMISSION = 0.0003 ether;
  uint constant public COMMISSION_MULTIPLIER = 1000;

  address public owner;
  address public nextOwner;
  address public revealer;

  uint public betMin;
  uint public betMax;

  uint public commission;
  uint public minCommission;
  uint public commissionFunds;

  uint public maxBetsPerBlock;

  struct Bet {
    address payable addr;
    uint amount;
    uint commission;
  }

  mapping(uint => Bet[]) public blockBets;
  mapping(uint => bytes) public blockSignatures;

  uint public lockedFunds;

  event PaymentSuccess(address indexed _addr, uint _amount);
  event PaymentFailure(address indexed _addr, uint _amount);
  event BetPlaced(address indexed _addr, uint[] _blocks, uint[] _commissions);
  event BlockRevealed(uint indexed _block, bool _lucky, uint _length, uint _remaining);

  modifier onlyOwner() {
    require(msg.sender == owner, "NOT_AN_OWNER");
    _;
  }

  modifier onlyRevealer() {
    require(msg.sender == revealer, "NOT_A_REVEALER");
    _;
  }

  constructor() public {
    owner = msg.sender;
    betMin = 0.05 ether;
    betMax = 2 ether;

    commission = 1;
    maxBetsPerBlock = 20;
  }

  function() external payable onlyOwner {}

  function placeBet(uint[] memory _blocks, uint[] memory _bets) public payable {
    require(betMin > 0 && betMax > 0, "STOPPED");
    require(msg.value > 0, "BET_NULL");
    require(_blocks.length > 0 && _blocks.length == _bets.length, "BLOCKS_BETS_NOT_EQUAL");

    uint betAmount = msg.value;
    uint[] memory _commissions = new uint[](_bets.length);

    for (uint i = 0; i < _blocks.length; i++) {
      uint blockNumber = _blocks[i];
      uint _bet = _bets[i];

      if (blockNumber > block.number && _bet <= betAmount && (betAmount >= betMin && betAmount <= betMax)) {
        Bet[] storage bets = blockBets[blockNumber];

        if (bets.length > maxBetsPerBlock) {
          continue;
        }

        bool betBefore = false;
        for (uint j = 0; j < bets.length; j++) {
          if (bets[j].addr == msg.sender) {
            betBefore = true;
            break;
          }
        }

        if (!betBefore) {
          uint winAmount = getWinAmount(_bet);
          uint betCommission = getCommissionAmount(winAmount);

          bets.push(Bet({ addr: msg.sender, amount: winAmount, commission: betCommission }));
          _commissions[i] = betCommission;
          betAmount -= _bet;
          continue;
        }
      }

      _blocks[i] = 0;
    }

    uint toBet = msg.value - betAmount;
    if (betAmount > 0) {
      msg.sender.transfer(betAmount);
    }

    lockedFunds += getWinAmount(toBet);

    emit BetPlaced(msg.sender, _blocks, _commissions);
  }

  function revealBlock(uint _blockNumber, bytes memory signature, uint limit) public onlyRevealer {
    require(_blockNumber < block.number && _blockNumber >= (block.number - 256), "INVALID_BLOCK_NUMBER");
    require(ecdsaRecover(toEthSignedMessageHash(blockhash(_blockNumber)), signature) == msg.sender, "INVALID_REVEAL_SIGNATURE");

    bool lucky = uint8(signature[signature.length - 1]) & 0x01 != 1;
    uint processed = 0;

    Bet[] storage bets = blockBets[_blockNumber];
    for (uint i = 0; i < bets.length; i++) {
      Bet storage bet = bets[i];

      if (processed == limit) {
          break;
      }
      processed++;

      if (bet.amount > 0) {
        uint winAmount = bet.amount - bet.commission;

        if (lucky) {
          if (bet.addr.send(winAmount)) {
            emit PaymentSuccess(bet.addr, winAmount);
          } else {
            emit PaymentFailure(bet.addr, winAmount);
            continue;
          }

          commissionFunds += bet.commission;
        }

        lockedFunds -= bet.amount;
        bet.amount = 0;
        bet.commission = 0;
      }
    }

    if (blockSignatures[_blockNumber].length == 0) {
      blockSignatures[_blockNumber] = signature;
    }

    emit BlockRevealed(_blockNumber, lucky, bets.length, bets.length - processed);
  }

  function refundBlock(uint _blockNumber, uint limit) public {
    require(_blockNumber < (block.number - 256), "INVALID_BLOCK_NUMBER");

    Bet[] storage bets = blockBets[_blockNumber];
    uint processed = 0;

    for (uint i = 0; i < bets.length; i++) {
      Bet storage bet = bets[i];

      if (processed == limit) {
          break;
      }
      processed++;

      if (bet.amount > 0) {
        uint winAmount = bet.amount - bet.commission;

        if (address(this).balance >= winAmount) {
          bet.addr.send(winAmount);

          lockedFunds -= bet.amount;
          commissionFunds += bet.commission;

          bet.amount = 0;
          bet.commission = 0;
        }
      }
    }
  }

  function getWinAmount(uint _betAmount) public pure returns (uint) {
    return _betAmount * 2;
  }

  function getCommissionAmount(uint winAmount) public view returns (uint) {
    uint betCommission = 0;
    if (commission > 0) {
      betCommission = max(winAmount / COMMISSION_MULTIPLIER * commission, MIN_COMMISSION);
    }

    return betCommission;
  }

  function transferOwnership(address _nextOwner) public onlyOwner {
    nextOwner = _nextOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == nextOwner, "NOT_A_NEXT_OWNER");

    owner = nextOwner;
    nextOwner = address(0);
  }

  function setRevealer(address _revealer) public onlyOwner {
    require(lockedFunds == 0, "NOT_ALL_BETS_PROCESSED");
    revealer = _revealer;
  }

  function setBetRange(uint _min, uint _max) public onlyOwner {
    betMin = _min;
    betMax = _max;
  }

  function setMaxBetsPerBlock(uint _max) public onlyOwner {
    maxBetsPerBlock = _max;
  }

  function setCommission(uint _commission) public onlyOwner {
    require(_commission >= 0 && _commission <= (10 * COMMISSION_MULTIPLIER), "COMMISSION_OUT_OF_RANGE");
    commission = _commission;
  }

  function withdrawCommission(uint amount) public onlyOwner {
    uint withdrawAmount = amount;
    if (amount == 0) {
      withdrawAmount = commissionFunds;
    }

    require(commissionFunds > 0 && withdrawAmount <= commissionFunds, "COMMISSION_NULL");
    msg.sender.transfer(withdrawAmount);
    commissionFunds -= withdrawAmount;
  }

  function close() public onlyOwner {
    require(lockedFunds == 0, "NOT_ALL_BETS_PROCESSED");
    selfdestruct(msg.sender);
  }

  function ecdsaRecover(bytes32 hash, bytes memory signature) internal pure returns (address) {
      if (signature.length != 64) {
          return (address(0));
      }

      bytes32 r;
      bytes32 s;
      uint8 v = 27;

      assembly {
          r := mload(add(signature, 0x20))
          s := mload(add(signature, 0x40))
      }

      return ecrecover(hash, v, r, s);
  }

  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
      return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function max(uint a, uint b) internal pure returns (uint) {
      return a > b ? a : b;
  }
}