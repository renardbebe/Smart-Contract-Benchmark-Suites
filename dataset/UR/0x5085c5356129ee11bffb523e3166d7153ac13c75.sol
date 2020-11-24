 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
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


 
contract HouseAdmin is Ownable {
  address public signer;
  address public croupier;

  event SignerTransferred(address indexed previousSigner, address indexed newSigner);
  event CroupierTransferred(address indexed previousCroupier, address indexed newCroupier);

   
  modifier onlySigner() {
    require(msg.sender == signer || msg.sender == owner);
    _;
  }

   
  modifier onlyCroupier() {
    require(msg.sender == croupier || msg.sender == owner);
    _;
  }

   
  constructor() public {
    signer = msg.sender;
    croupier = msg.sender;
  }

   
  function transferSigner(address _newSigner) public onlySigner {
    _transferSigner(_newSigner);
  }

   
  function transferCroupier(address _newCroupier) public onlyCroupier {
    _transferCroupier(_newCroupier);
  }

   
  function _transferSigner(address _newSigner) internal {
    require(_newSigner != address(0));
    emit SignerTransferred(signer, _newSigner);
    signer = _newSigner;
  }

   
  function _transferCroupier(address _newCroupier) internal {
    require(_newCroupier != address(0));
    emit CroupierTransferred(croupier, _newCroupier);
    croupier = _newCroupier;
  }
}


contract Casino is Ownable, HouseAdmin {
  using SafeMath for uint;

  uint constant HOUSE_EDGE_PERCENT = 1;
  uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

  uint constant BET_AMOUNT_MIN = 0.01 ether;
  uint constant BET_AMOUNT_MAX = 1000 ether;

  uint constant BET_EXPIRATION_BLOCKS = 250;

  uint constant MAX_MASKABLE_MODULO = 40;
  uint constant MAX_BET_MASK = 2 ** MAX_MASKABLE_MODULO;

   
  uint constant POPCOUNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
  uint constant POPCOUNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
  uint constant POPCOUNT_MODULO = 0x3F;

  uint public bankFund;

  struct Bet {
    uint8 modulo;
    uint64 choice;
    uint amount;
    uint winAmount;
    uint placeBlockNumber;
    bool isActive;
    address player;
  }

  mapping (uint => Bet) public bets;

  event LogParticipant(address indexed player, uint indexed modulo, uint choice, uint amount, uint commit);
  event LogClosedBet(address indexed player, uint indexed modulo, uint choice, uint reveal, uint result, uint amount, uint winAmount);
  event LogDistributeReward(address indexed addr, uint reward);
  event LogRecharge(address indexed addr, uint amount);
  event LogRefund(address indexed addr, uint amount);
  event LogDealerWithdraw(address indexed addr, uint amount);

  constructor() payable public {
    owner = msg.sender;
  }

  function placeBet(uint _choice, uint _modulo, uint _expiredBlockNumber, uint _commit, uint8 _v, bytes32 _r, bytes32 _s) payable external {
    Bet storage bet = bets[_commit];

    uint amount = msg.value;

    require(bet.player == address(0), "this bet is already exist");
    require(block.number <= _expiredBlockNumber, 'this bet has expired');
    require(amount >= BET_AMOUNT_MIN && amount <= BET_AMOUNT_MAX, 'bet amount out of range');

     
    bytes32 msgHash = keccak256(abi.encodePacked(_expiredBlockNumber, _commit));
    require(ecrecover(msgHash, _v, _r, _s) == signer, "incorrect signer");

    uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
    if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
      houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
    }

    uint populationCount;
    if (_modulo < MAX_MASKABLE_MODULO) {
      require(_choice < MAX_BET_MASK, "choice too large");
      populationCount = (_choice * POPCOUNT_MULT & POPCOUNT_MASK) % POPCOUNT_MODULO;
      require(populationCount < _modulo, "winning rate out of range");
    } else {
      require(_choice < _modulo, "choice large than modulo");
      populationCount = _choice;
    }

    uint winAmount = (amount - houseEdge).mul(_modulo) / populationCount;
    require(bankFund.add(winAmount) <= address(this).balance, 'contract balance is not enough');
     
    bankFund = bankFund.add(winAmount);

    bet.choice = uint64(_choice);
    bet.player = msg.sender;
    bet.placeBlockNumber = block.number;
    bet.amount = amount;
    bet.winAmount = winAmount;
    bet.isActive = true;
    bet.modulo = uint8(_modulo);

    emit LogParticipant(msg.sender, _modulo, _choice, amount, _commit);
  }

  function closeBet(uint _reveal) external onlyCroupier {
    uint commit = uint(keccak256(abi.encodePacked(_reveal)));
    Bet storage bet = bets[commit];

    require(bet.isActive, 'this bet is not active');

    uint amount = bet.amount;
    uint placeBlockNumber = bet.placeBlockNumber;
    uint modulo = bet.modulo;
    uint winAmount = 0;
    uint choice = bet.choice;
    address player = bet.player;

    require(block.number > placeBlockNumber, 'close bet block number is too low');
    require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, 'the block number is too low to query');

    uint result = uint(keccak256(abi.encodePacked(_reveal, blockhash(placeBlockNumber)))) % modulo;

    if (modulo <= MAX_MASKABLE_MODULO) {
      if (2 ** result & choice != 0) {
        winAmount = bet.winAmount;
        player.transfer(winAmount);
        emit LogDistributeReward(player, winAmount);
      }
    } else {
      if (result < choice) {
        winAmount = bet.winAmount;
        player.transfer(winAmount);
        emit LogDistributeReward(player, winAmount);
      }
    }

     
    bankFund = bankFund.sub(bet.winAmount);
    bet.isActive = false;

    emit LogClosedBet(player, modulo, choice, _reveal, result, amount, winAmount);
  }

  function refundBet(uint _commit) external onlyCroupier {
    Bet storage bet = bets[_commit];

    uint amount = bet.amount;
    uint placeBlockNumber = bet.placeBlockNumber;
    address player = bet.player;

    require(bet.isActive, 'this bet is not active');
    require(block.number > placeBlockNumber + BET_EXPIRATION_BLOCKS, 'this bet has not expired');

    player.transfer(amount);
     
    bankFund = bankFund.sub(bet.winAmount);
    bet.isActive = false;

    emit LogRefund(player, amount);
  }

   
  function recharge() public payable {
    emit LogRecharge(msg.sender, msg.value);
  }

   
  function withdraw(uint _amount) external onlyOwner {
    require(_amount <= address(this).balance - bankFund, 'cannot withdraw amount greater than (balance - bankFund)');
    owner.transfer(_amount);
    emit LogDealerWithdraw(owner, _amount);
  }

   
  function getAvailableBalance() view public returns (uint) {
    return address(this).balance - bankFund;
  }
}