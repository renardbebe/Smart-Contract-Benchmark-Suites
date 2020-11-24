 

pragma solidity ^0.4.8;

 
contract Owned {
  address owner;

  modifier onlyOwner {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

   
  function Owned() {
    owner = msg.sender;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }

   
  function shutdown() onlyOwner {
    selfdestruct(owner);
  }

   
  function withdraw() onlyOwner {
    if (!owner.send(this.balance)) {
      throw;
    }
  }
}

contract LotteryRoundInterface {
  bool public winningNumbersPicked;
  uint256 public closingBlock;

  function pickTicket(bytes4 picks) payable;
  function randomTicket() payable;

  function proofOfSalt(bytes32 salt, uint8 N) constant returns(bool);
  function closeGame(bytes32 salt, uint8 N);
  function claimOwnerFee(address payout);
  function withdraw();
  function shutdown();
  function distributeWinnings();
  function claimPrize();

  function paidOut() constant returns(bool);
  function transferOwnership(address newOwner);
}

 
contract LotteryRound is LotteryRoundInterface, Owned {

   
   
  string constant VERSION = '0.1.2';

   
  uint256 constant ROUND_LENGTH = 43200;   

   
  uint256 constant PAYOUT_FRACTION = 950;

   
  uint constant TICKET_PRICE = 1 finney;

   
  bytes1 constant PICK_MASK = 0x3f;  

   
   
   
  bytes32 public saltHash;

   
   
   
  bytes32 public saltNHash;

   
  uint256 public closingBlock;

   
  bytes4 public winningNumbers;

   
  bool public winningNumbersPicked = false;

   
  address[] public winners;

   
  mapping(address => bool) public winningsClaimable;

   
  mapping(bytes4 => address[]) public tickets;
  uint256 public nTickets = 0;

   
  uint256 public prizePool;

   
   
  uint256 public prizeValue;

   
   
  uint256 public ownerFee;

   
  bytes32 private accumulatedEntropy;

  modifier beforeClose {
    if (block.number > closingBlock) {
      throw;
    }
    _;
  }

  modifier beforeDraw {
    if (block.number <= closingBlock || winningNumbersPicked) {
      throw;
    }
    _;
  }

  modifier afterDraw {
    if (winningNumbersPicked == false) {
      throw;
    }
    _;
  }

   
   
  event LotteryRoundStarted(
    bytes32 saltHash,
    bytes32 saltNHash,
    uint256 closingBlock,
    string version
  );

   
  event LotteryRoundDraw(
    address indexed ticketHolder,
    bytes4 indexed picks
  );

   
   
  event LotteryRoundCompleted(
    bytes32 salt,
    uint8 N,
    bytes4 indexed winningPicks,
    uint256 closingBalance
  );

   
  event LotteryRoundWinner(
    address indexed ticketHolder,
    bytes4 indexed picks
  );

   
  function LotteryRound(
    bytes32 _saltHash,
    bytes32 _saltNHash
  ) payable {
    saltHash = _saltHash;
    saltNHash = _saltNHash;
    closingBlock = block.number + ROUND_LENGTH;
    LotteryRoundStarted(
      saltHash,
      saltNHash,
      closingBlock,
      VERSION
    );
     
    accumulatedEntropy = block.blockhash(block.number - 1);
  }

   
  function generatePseudoRand(bytes32 seed) internal returns(bytes32) {
    uint8 pseudoRandomOffset = uint8(uint256(sha256(
      seed,
      block.difficulty,
      block.coinbase,
      block.timestamp,
      accumulatedEntropy
    )) & 0xff);
     
     
    uint256 pseudoRandomBlock = block.number - pseudoRandomOffset - 1;
    bytes32 pseudoRand = sha3(
      block.number,
      block.blockhash(pseudoRandomBlock),
      block.difficulty,
      block.timestamp,
      accumulatedEntropy
    );
    accumulatedEntropy = sha3(accumulatedEntropy, pseudoRand);
    return pseudoRand;
  }

   
  function pickTicket(bytes4 picks) payable beforeClose {
    if (msg.value != TICKET_PRICE) {
      throw;
    }
     
    for (uint8 i = 0; i < 4; i++) {
      if (picks[i] & PICK_MASK != picks[i]) {
        throw;
      }
    }
    tickets[picks].push(msg.sender);
    nTickets++;
    generatePseudoRand(bytes32(picks));  
    LotteryRoundDraw(msg.sender, picks);
  }

   
  function pickValues(bytes32 seed) internal returns (bytes4) {
    bytes4 picks;
    uint8 offset;
    for (uint8 i = 0; i < 4; i++) {
      offset = uint8(seed[0]) & 0x1f;
      seed = sha3(seed, msg.sender);
      picks = (picks >> 8) | bytes1(seed[offset] & PICK_MASK);
    }
    return picks;
  }

   
  function randomTicket() payable beforeClose {
    if (msg.value != TICKET_PRICE) {
      throw;
    }
    bytes32 pseudoRand = generatePseudoRand(bytes32(msg.sender));
    bytes4 picks = pickValues(pseudoRand);
    tickets[picks].push(msg.sender);
    nTickets++;
    LotteryRoundDraw(msg.sender, picks);
  }

   
  function proofOfSalt(bytes32 salt, uint8 N) constant returns(bool) {
     
    bytes32 _saltNHash = sha3(salt, N, salt);
    if (_saltNHash != saltNHash) {
      return false;
    }

     
    bytes32 _saltHash = sha3(salt);
    for (var i = 1; i < N; i++) {
      _saltHash = sha3(_saltHash);
    }
    if (_saltHash != saltHash) {
      return false;
    }
    return true;
  }

   
  function finalizeRound(bytes32 salt, uint8 N, bytes4 winningPicks) internal {
    winningNumbers = winningPicks;
    winningNumbersPicked = true;
    LotteryRoundCompleted(salt, N, winningNumbers, this.balance);

    var _winners = tickets[winningNumbers];
     
    if (_winners.length > 0) {
       
      for (uint i = 0; i < _winners.length; i++) {
        var winner = _winners[i];
        if (!winningsClaimable[winner]) {
          winners.push(winner);
          winningsClaimable[winner] = true;
          LotteryRoundWinner(winner, winningNumbers);
        }
      }
       
       
      prizePool = this.balance * PAYOUT_FRACTION / 1000;
      prizeValue = prizePool / winners.length;

       
      ownerFee = this.balance - prizePool;
    }
     
  }

   
  function closeGame(bytes32 salt, uint8 N) onlyOwner beforeDraw {
     
    if (winningNumbersPicked == true) {
      throw;
    }

     
    if (proofOfSalt(salt, N) != true) {
      throw;
    }

    bytes32 pseudoRand = sha3(
      salt,
      nTickets,
      accumulatedEntropy
    );
    finalizeRound(salt, N, pickValues(pseudoRand));
  }

   
  function claimOwnerFee(address payout) onlyOwner afterDraw {
    if (ownerFee > 0) {
      uint256 value = ownerFee;
      ownerFee = 0;
      if (!payout.send(value)) {
        throw;
      }
    }
  }

   
  function withdraw() onlyOwner afterDraw {
    if (paidOut() && ownerFee == 0) {
      if (!owner.send(this.balance)) {
        throw;
      }
    }
  }

   
  function shutdown() onlyOwner afterDraw {
    if (paidOut() && ownerFee == 0) {
      selfdestruct(owner);
    }
  }

   
  function distributeWinnings() onlyOwner afterDraw {
    if (winners.length > 0) {
      for (uint i = 0; i < winners.length; i++) {
        address winner = winners[i];
        bool unclaimed = winningsClaimable[winner];
        if (unclaimed) {
          winningsClaimable[winner] = false;
          if (!winner.send(prizeValue)) {
             
             
             
            winningsClaimable[winner] = true;
          }
        }
      }
    }
  }

   
  function paidOut() constant returns(bool) {
     
     
    if (winningNumbersPicked == false) {
      return false;
    }
    if (winners.length > 0) {
      bool claimed = true;
       
       
      for (uint i = 0; claimed && i < winners.length; i++) {
        claimed = claimed && !winningsClaimable[winners[i]];
      }
      return claimed;
    } else {
       
      return true;
    }
  }

   
  function claimPrize() afterDraw {
    if (winningsClaimable[msg.sender] == false) {
       
      throw;
    }
    winningsClaimable[msg.sender] = false;
    if (!msg.sender.send(prizeValue)) {
       
      throw;
    }
  }

   
   
   
  function () {
    throw;
  }
}