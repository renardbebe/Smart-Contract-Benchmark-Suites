 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
contract iPlpPointsRedeemer {
  function reserveTokens() public view returns (uint remaining);
  function transferFromReserve(address _to, uint _value) public;
}


contract PirateLottery {

   
   
   
  event WinnerEvent(uint256 round, uint256 ticket, uint256 prize);
  event PayoutEvent(uint256 round, address payee, uint256 prize, uint256 payout);


   
   
   
  uint constant MIN_TICKETS = 10;
  uint constant MAX_TICKETS = 50000000;
  uint constant LONG_DURATION = 5 days;
  uint constant SHORT_DURATION = 12 hours;
  uint constant MAX_CLAIM_DURATION = 5 days;
  uint constant TOKEN_HOLDOVER_THRESHOLD = 20 finney;


   
   
   
   
  struct Round {
    uint256 maxTickets;
    uint256 ticketPrice;
    uint256 ticketCount;
    bytes32 playersHash;
    uint256 begDate;
    uint256 endDate;
    uint256 winner;
    uint256 prize;
    bool isOpen;
    mapping (uint256 => address) ticketOwners;
    mapping (address => uint256) playerTicketCounts;
    mapping (address => mapping (uint256 => uint256)) playerTickets;
  }

   
   
   
   
  struct Claim {
    uint256 ticket;
    uint256 playerHash;
  }
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private constant CLAIM_TYPEHASH = keccak256("Claim(string lottery,uint256 round,uint256 ticket,uint256 playerHash)");
  bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");


   
   
   
  bool    public isLocked;
  string  public name;
  address payable public owner;
  bytes32 nameHash;
  uint256 public min_ticket_price;
  uint256 public max_ticket_price;
  uint256 public roundCount;
  mapping (uint256 => Round) public rounds;
  mapping (address => uint256) public balances;
  mapping (address => uint256) public plpPoints;
  iPlpPointsRedeemer plpToken;
  uint256 public tokenHoldoverBalance;

   
   
   
  modifier ownerOnly {
    require(msg.sender == owner, "owner only");
    _;
  }
  modifier unlockedOnly {
    require(!isLocked, "unlocked only");
    _;
  }


   
   
   
  constructor(address _plpToken, uint256 _chainId, string memory _name, uint256 _min_ticket_price, uint256 _max_ticket_price) public {
    owner = msg.sender;
    name = _name;
    min_ticket_price = _min_ticket_price;
    max_ticket_price = _max_ticket_price;
    plpToken = iPlpPointsRedeemer(_plpToken);
    Round storage _currentRound = rounds[1];
    Round storage _previousRound = rounds[0];
    _previousRound.maxTickets = 1;
     
    _previousRound.ticketCount = 1;
    _previousRound.playersHash = keccak256(abi.encodePacked(bytes32(0), owner));
    _previousRound.begDate = now;
    _previousRound.endDate = now;
    _previousRound.winner = 1;
    _previousRound.ticketOwners[1] = msg.sender;
    _previousRound.playerTickets[msg.sender][0] = 1;
    _previousRound.playerTicketCounts[msg.sender]++;
     
    _currentRound.maxTickets = 2;
    _currentRound.ticketPrice = (min_ticket_price + max_ticket_price) / 2;
     
     
     
     
     
     
    _currentRound.isOpen = true;
    roundCount = 1;
     
    DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAIN_TYPEHASH,
                                            keccak256("Pirate Lottery"),
                                            keccak256("1.0"),
                                            _chainId,
                                            address(this)));
    nameHash = keccak256(abi.encodePacked(name));
  }
   
  function setToken(address _plpToken) public unlockedOnly ownerOnly {
    plpToken = iPlpPointsRedeemer(_plpToken);
  }
  function lock() public ownerOnly {
    isLocked = true;
  }


   
   
   
  function buyTicket() public payable {
    Round storage _currentRound = rounds[roundCount];
    require(_currentRound.isOpen == true, "current round is closed");
    require(msg.value == _currentRound.ticketPrice, "incorrect ticket price");
    if (_currentRound.ticketCount == 0)
      _currentRound.begDate = now;
    _currentRound.ticketCount++;
    _currentRound.prize += msg.value;
    plpPoints[msg.sender]++;
    uint256 _ticket = _currentRound.ticketCount;
    _currentRound.ticketOwners[_ticket] = msg.sender;
    uint256 _playerTicketCount = _currentRound.playerTicketCounts[msg.sender];
    _currentRound.playerTickets[msg.sender][_playerTicketCount] = _ticket;
    _currentRound.playerTicketCounts[msg.sender]++;
    _currentRound.playersHash = keccak256(abi.encodePacked(_currentRound.playersHash, msg.sender));
    uint256 _currentDuration = now - _currentRound.begDate;
    if (_currentRound.ticketCount == _currentRound.maxTickets || _currentDuration > LONG_DURATION) {
      _currentRound.playersHash = keccak256(abi.encodePacked(_currentRound.playersHash, block.coinbase));
      _currentRound.isOpen = false;
      _currentRound.endDate = now;
    }
  }


   
   
   
   
  function getCurrentInfo(address _addr) public view returns(uint256 _round, uint256 _playerTicketCount, uint256 _ticketPrice,
                                                             uint256 _ticketCount, uint256 _begDate, uint256 _endDate, uint256 _prize,
                                                             bool _isOpen, uint256 _maxTickets) {
    Round storage _currentRound = rounds[roundCount];
    _round = roundCount;
    _playerTicketCount = _currentRound.playerTicketCounts[_addr];
    _ticketPrice = _currentRound.ticketPrice;
    _ticketCount = _currentRound.ticketCount;
    _begDate = _currentRound.begDate;
    _endDate = _currentRound.isOpen ? (_currentRound.begDate + LONG_DURATION) : _currentRound.endDate;
    _prize = _currentRound.prize;
    _isOpen = _currentRound.isOpen;
    _maxTickets = _currentRound.maxTickets;
  }


   
   
   
  function getPreviousInfo(address _addr) public view returns(uint256 _round, uint256 _playerTicketCount, uint256 _ticketPrice, uint256 _ticketCount,
                                                              uint256 _begDate, uint256 _endDate, uint256 _prize,
                                                              uint256 _winningTicket, address _winner, uint256 _claimDeadline, bytes32 _playersHash) {
    Round storage _currentRound = rounds[roundCount];
    Round storage _previousRound = rounds[roundCount - 1];
    _round = roundCount - 1;
    _playerTicketCount = _previousRound.playerTicketCounts[_addr];
    _ticketPrice = _previousRound.ticketPrice;
    _ticketCount = _previousRound.ticketCount;
    _begDate = _previousRound.begDate;
    _endDate = _previousRound.endDate;
    _prize = _previousRound.prize;
    _winningTicket = _previousRound.winner;
    _winner = _previousRound.ticketOwners[_previousRound.winner];
    if (_currentRound.isOpen == true) {
      _playersHash = bytes32(0);
      _claimDeadline = 0;
    } else {
      _playersHash = _currentRound.playersHash;
      _claimDeadline = _currentRound.endDate + MAX_CLAIM_DURATION;
    }
  }


   
   
   
   
  function getTickets(address _addr, uint256 _round, uint256 _startIdx, uint256 _maxResults) public view returns(uint256 _idx, uint256[] memory _tickets) {
    uint _count = 0;
    Round storage _subjectRound = rounds[_round];
    _tickets = new uint256[](_maxResults);
    uint256 _playerTicketCount = _subjectRound.playerTicketCounts[_addr];
    mapping(uint256 => uint256) storage _playerTickets = _subjectRound.playerTickets[_addr];
    for (_idx = _startIdx; _idx < _playerTicketCount; ++_idx) {
      _tickets[_count] = _playerTickets[_idx];
      if (++_count >= _maxResults)
        break;
    }
  }

   
   
  function getTicketOwner(uint256 _round, uint256 _ticket) public view returns(address _owner) {
    Round storage _subjectRound = rounds[_round];
    _owner = _subjectRound.ticketOwners[_ticket];
  }


   
   
   
   
   
   
  function claimPrize(uint8 _sigV, bytes32 _sigR, bytes32 _sigS, uint256 _ticket) public {
    Round storage _currentRound = rounds[roundCount];
    Round storage _previousRound = rounds[roundCount - 1];
    require(_currentRound.isOpen == false, "wait until current round is closed");
    require(_previousRound.winner == _ticket, "not the winning ticket");
    claimPrizeForTicket(_sigV, _sigR, _sigS, _ticket, 2);
    newRound();
  }


   
   
   
   
  function claimAbondonedPrize(uint8 _sigV, bytes32 _sigR, bytes32 _sigS, uint256 _ticket) public {
    Round storage _currentRound = rounds[roundCount];
    require(_currentRound.isOpen == false, "wait until current round is closed");
    require(now >= _currentRound.endDate + MAX_CLAIM_DURATION, "prize is not abondoned yet");
    claimPrizeForTicket(_sigV, _sigR, _sigS, _ticket, 50);
    newRound();
  }


   
   
   
   
  function claimPrizeForTicket(uint8 _sigV, bytes32 _sigR, bytes32 _sigS, uint256 _ticket, uint256 _ownerCutPct) internal {
    Round storage _currentRound = rounds[roundCount];
    Round storage _previousRound = rounds[roundCount - 1];
    bytes32 _claimHash = keccak256(abi.encode(CLAIM_TYPEHASH, nameHash, roundCount - 1, _ticket, _currentRound.playersHash));
    bytes32 _domainClaimHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _claimHash));
    address _recovered = ecrecover(_domainClaimHash, _sigV, _sigR, _sigS);
    require(_previousRound.ticketOwners[_ticket] == _recovered, "claim is not valid");
    uint256 _tokenCut = _ownerCutPct * _previousRound.prize / 100;
    tokenHoldoverBalance += _tokenCut;
    uint256 _payout = _previousRound.prize - _tokenCut;
    balances[msg.sender] += _payout;
    bytes32 _winningHash = keccak256(abi.encodePacked(_currentRound.playersHash, _sigV, _sigR, _sigS));
    _currentRound.winner = uint256(_winningHash) % _currentRound.ticketCount + 1;
    emit PayoutEvent(roundCount - 1, msg.sender, _previousRound.prize, _payout);
    emit WinnerEvent(roundCount, _currentRound.winner, _currentRound.prize);
     
    if (tokenHoldoverBalance > TOKEN_HOLDOVER_THRESHOLD) {
      uint _amount = tokenHoldoverBalance;
      tokenHoldoverBalance = 0;
      (bool paySuccess, ) = address(plpToken).call.value(_amount)("");
      if (!paySuccess)
        revert();
    }
  }


   
   
   
   
   
  function newRound() internal {
    ++roundCount;
    Round storage _nextRound = rounds[roundCount];
    Round storage _currentRound = rounds[roundCount - 1];
    uint256 _currentDuration = _currentRound.endDate - _currentRound.begDate;
     
    if (_currentDuration < SHORT_DURATION) {
      if (_currentRound.ticketPrice < max_ticket_price && _currentRound.maxTickets > MIN_TICKETS * 10) {
         _nextRound.ticketPrice = max_ticket_price;
         _nextRound.maxTickets = _currentRound.maxTickets;
       } else {
         _nextRound.ticketPrice = _currentRound.ticketPrice;
         _nextRound.maxTickets = 2 * _currentRound.maxTickets;
         if (_nextRound.maxTickets > MAX_TICKETS)
           _nextRound.maxTickets = MAX_TICKETS;
       }
    } else if (_currentDuration > LONG_DURATION) {
       if (_currentRound.ticketPrice > min_ticket_price) {
         _nextRound.ticketPrice = min_ticket_price;
         _nextRound.maxTickets = _currentRound.maxTickets;
       } else {
         _nextRound.ticketPrice = min_ticket_price;
         _nextRound.maxTickets = _currentRound.maxTickets / 2;
         if (_nextRound.maxTickets < MIN_TICKETS)
           _nextRound.maxTickets = MIN_TICKETS;
       }
    } else {
      _nextRound.maxTickets = _currentRound.maxTickets;
      _nextRound.ticketPrice = (min_ticket_price + max_ticket_price) / 2;
    }
     
     
     
    _nextRound.isOpen = true;
  }


   
   
   
   
  function redeemPlpPoints() public {
    uint256 noTokens = plpPoints[msg.sender];
    plpPoints[msg.sender] = 0;
    plpToken.transferFromReserve(msg.sender, noTokens);
  }


   
   
   
  function withdraw() public {
    uint256 _amount = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(_amount);
  }


   
   
   
   
  function killContract() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}