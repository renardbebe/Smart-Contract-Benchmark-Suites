 

pragma solidity ^0.4.17;

contract Ownable {
	address owner;
	address potentialOwner;
	
	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	function Ownable() public {
		owner = msg.sender;
	}

	 
	function amIOwner() public view returns (bool) {
		return msg.sender == owner;
	}

	 
	function transferOwnership(address _newOwner) public onlyOwner {
		potentialOwner = _newOwner;
	}

	 
	function acceptOwnership() public {
		require(msg.sender == potentialOwner);
		owner = msg.sender;
		potentialOwner = address(0);
	}
}

contract Linkable is Ownable {
	address[] linked;

	modifier onlyLinked() {
		require(checkPermissions() == true);
		_;
	}
	
	 
	function link(address _address) public onlyOwner {
		linked.push(_address);
	}

	 
	function checkPermissions() public view returns (bool) {
		for (uint i = 0; i < linked.length; i++)
			if (linked[i] == msg.sender) return true;
		return false;
	}
}

contract Activity is Ownable, Linkable {
  
  struct Event {
    uint id;
    uint gameId;
    address source;
    address[] winners;
    uint winningNumber;
    uint amount;
    uint timestamp;
  }

   
  Event[] public events;

   
  function newEvent(uint _gameId, address[] _winners, uint _winningNumber, uint _amount) public onlyLinked {
    require(_gameId > 0);
    events.push(Event(events.length, _gameId, msg.sender, _winners, _winningNumber, _amount, now));
  }

   
  function getFeed(uint _gameId, uint _page, uint _pageSize) public view
    returns (uint[], uint[], address[], uint[], uint[], uint[], uint[]) {
    
    return constructResponse(getFiltered(_gameId, _page - 1, _pageSize));
  }

   
   

  function constructResponse(Event[] _events) private view
    returns (uint[], uint[], address[], uint[], uint[], uint[], uint[]) {
    
    uint[] memory _ids = new uint[](_events.length);
    uint[] memory _gameIds = new uint[](_events.length);
    uint[] memory _amounts = new uint[](_events.length);
    uint[] memory _timestamps = new uint[](_events.length);

    for (uint i = 0; i < _events.length; i++) {
      _ids[i] = _events[i].id;
      _gameIds[i] = _events[i].gameId;
      _amounts[i] = _events[i].amount;
      _timestamps[i] = _events[i].timestamp;
    }

    WinData memory _win = contructWinData(_events);

    return (_ids, _gameIds, _win.winners, _win.numWinners, _win.winningNumbers, _amounts, _timestamps);
  }

  struct WinData {
    address[] winners;
    uint[] numWinners;
    uint[] winningNumbers;
  }

  function contructWinData(Event[] _events) private view returns (WinData) {
    address[] memory _winners = new address[](_events.length);
    uint[] memory _numWinners = new uint[](_events.length);
    uint[] memory _winningNumbers = new uint[](_events.length);

    for (uint i = 0; i < _events.length; i++) {
      _winners[i] = chooseWinnerToDisplay(_events[i].winners, msg.sender);
      _numWinners[i] = _events[i].winners.length;
      _winningNumbers[i] = _events[i].winningNumber;
    }

    return WinData(_winners, _numWinners, _winningNumbers);
  }

  function chooseWinnerToDisplay(address[] _winners, address _user) private pure returns (address) {
    if (_winners.length < 1) return address(0);
    address _picked = _winners[0];
    if (_winners.length == 1) return _picked;
    for (uint i = 1; i < _winners.length; i++)
      if (_winners[i] == _user) _picked = _user;
    return _picked;
  }

  function getFiltered(uint _gameId, uint _page, uint _pageSize) private view returns (Event[]) {
    Event[] memory _filtered = new Event[](_pageSize);
    uint _filteredIndex;
    uint _minIndex = _page * _pageSize;
    uint _maxIndex = _minIndex + _pageSize;
    uint _count;

    for (uint i = events.length; i > 0; i--) {
      if (_gameId == 0 || events[i - 1].gameId == _gameId) {
        if (_filteredIndex >= _minIndex && _filteredIndex < _maxIndex) {
          _filtered[_count] = events[i - 1];
          _count++;
        }
        _filteredIndex++;
      }
    }

    Event[] memory _events = new Event[](_count);
    for (uint b = 0; b < _count; b++)
      _events[b] = _filtered[b];

    return _events;
  }

}

contract Affiliates is Ownable, Linkable {
	bool open = true;
	bool promoted = true;

	 
	function setRegistrationOpen(bool _open) public onlyOwner {
		open = _open;
	}

	function isRegistrationOpen() public view returns (bool) {
		return open;
	}

	 
	function setPromoted(bool _promoted) public onlyOwner {
		promoted = _promoted;
	}

	function isPromoted() public view returns (bool) {
		return promoted;
	}

	 

	mapping(uint => uint) balances;  
	mapping(address => uint) links;  
	mapping(uint => bool) living;  
	
	 
	function getCode() public view returns (uint) {
		return code(msg.sender);
	}

	 
	function code(address _affiliate) private pure returns (uint) {
		uint num = uint(uint256(keccak256(_affiliate)));
		return num / 10000000000000000000000000000000000000000000000000000000000000000000000;
	}

	 
	function getAffiliation(address _user) public view onlyLinked returns (uint) {
		return links[_user];
	}

	 
	function setAffiliation(address _user, uint _code) public onlyLinked returns (uint) {
		uint _affiliateCode = links[_user];
		if (_affiliateCode != 0) return _affiliateCode;
		links[_user] = _code;
		return _code;
	}

	 
	function deposit(uint[] _affiliateCodes, uint[] _amounts) public payable onlyLinked {
		require(_affiliateCodes.length == _amounts.length && _affiliateCodes.length > 0);

		uint _total;
		for (uint i = 0; i < _affiliateCodes.length; i++) {
			balances[_affiliateCodes[i]] += _amounts[i];
			_total += _amounts[i];
		}

		require(_total == msg.value && _total > 0);
	}

	event Withdrawn(address affiliate, uint amount);

	 
	function withdraw() public returns (uint) {
		uint _code = code(msg.sender);
		uint _amount = balances[_code];
		require(_amount > 0);
		balances[_code] = 0;
		msg.sender.transfer(_amount);	
		Withdrawn(msg.sender, _amount);
		return _amount;	
	}

	 
	function getBalance() public view returns (uint) {
		return balances[code(msg.sender)];
	}
}

contract Lottery is Ownable {
	function Lottery() public {
		owner = msg.sender;
	}

	 
	 
	
	uint id;

	function setId(uint _id) public onlyOwner {
		require(_id > 0);
		id = _id;
	}

	 
	 

	 
	function link(uint _id, address _activity, address _affiliates) public onlyOwner {
		require(_id > 0);
		id = _id;
		linkActivity(_activity);
		linkAffiliates(_affiliates);
		initialized();
	}

	 
	function initialized() internal;

	 
	 

	address public activityAddress;
	Activity activity;

	function linkActivity(address _address) internal onlyOwner {
		activity = Activity(_address);
		require(activity.checkPermissions() == true);
		activityAddress = _address;
	}

	function postEvent(address[] _winners, uint _winningNumber, uint _jackpot) internal {
		activity.newEvent(id, _winners, _winningNumber, _jackpot);
	}

	function postEvent(address _winner, uint _winningNumber, uint _jackpot) internal {
		address[] memory _winners = new address[](1);
		_winners[0] = _winner;
		postEvent(_winners, _winningNumber, _jackpot);
	}

	 
	 

	address public affiliatesAddress;
	Affiliates affiliates;

	function linkAffiliates(address _address) internal onlyOwner {
		require(affiliatesAddress == address(0));
		affiliates = Affiliates(_address);
		require(affiliates.checkPermissions() == true);
		affiliatesAddress = _address;
	}

	function setUserAffiliate(uint _code) internal returns (uint) {
		return affiliates.setAffiliation(msg.sender, _code);
	}

	function userAffiliate() internal view returns (uint) {
		return affiliates.getAffiliation(msg.sender);
	}

	function payoutToAffiliates(uint[] _addresses, uint[] _amounts, uint _total) internal {
		affiliates.deposit.value(_total)(_addresses, _amounts);
	}

	 
	 

	function getRandomNumber(uint _max) internal returns (uint) {
		return uint(block.blockhash(block.number-1)) % _max + 1;
	}
}


contract SlotLottery is Lottery {
	
	function SlotLottery() Lottery() public {
		state = State.Uninitialized;
	}

	 
	 

	function initialized() internal {
		state = State.NotRunning;
	}

	 
	 

	State state;

	enum State { Uninitialized, Running, Pending, GameOver, NotRunning }

	modifier only(State _state) {
		require(state == _state);
		_;
	}

	modifier not(State _state) {
		require(state != _state);
		_;
	}

	modifier oneOf(State[2] memory _states) {
		bool _valid = false;
		for (uint i = 0; i < _states.length; i++)
			if (state == _states[i]) _valid = true;
		require(_valid);
		_;
	}

	 
	function getState() public view returns (State) {
		return state;
	}

	 
	 

	 
	function startGame(uint _jackpot, uint _slots, uint _price, uint _max) public only(State.NotRunning) onlyOwner {
		require(_price * _slots > _jackpot);
		nextGame(verifiedGameRules(_jackpot, _slots, _price, _max));
	}

	 
	function suspendGame() public onlyOwner {
		game.loop = false;
	}

	 
	function gameShouldRestart() public onlyOwner {
		game.loop = true;
	}

	 
	function triggerFindWinner() public only(State.Pending) payable onlyOwner {
		state = State.Running;
		findWinner();
	}

	 
	function setNextRules(uint _jackpot, uint _slots, uint _price, uint _max) public not(State.NotRunning) onlyOwner {
		require(game.loop == true);
		game.nextGameRules = verifiedGameRules(_jackpot, _slots, _price, _max);
	}

	 
	function getNextRules() public view onlyOwner returns (uint, uint, uint, uint, bool) {
		return (game.nextGameRules.jackpot, game.nextGameRules.slots, game.nextGameRules.ticketPrice, game.nextGameRules.maxTicketsPer, game.loop);
	}

	 
	 

	function nextGame(GameRules _rules) internal oneOf([State.GameOver, State.NotRunning]) {
		uint _newId = lastGame.id + 1;
		game = Game({
			id: _newId, rules: _rules, nextGameRules: _rules, loop: true, startedAt: block.timestamp, 
			ticketsSold: 0, winner: address(0), winningNumber: 0, finishedAt: 0
		});
		for(uint i = 1; i <= game.rules.slots; i++)
			game.tickets[i] = address(0);
		state = State.Running;
	}

	function findWinner() internal only(State.Running) {
		require(game.ticketsSold >= game.rules.slots);
		require(this.balance >= game.rules.jackpot);

		state = State.Pending;
		uint _winningNumber = getRandomNumber(game.rules.slots);
		winnerChosen(_winningNumber);
	}

	function winnerChosen(uint _winningNumber) internal only(State.Pending) {
		state = State.GameOver;

		address _winner = game.tickets[_winningNumber];
		bool _startNew = game.loop;
		GameRules memory _nextRules = game.nextGameRules;

		game.finishedAt = block.timestamp;
		game.winner = _winner;
		game.winningNumber = _winningNumber;
		lastGame = game;

		 
		_winner.transfer(game.rules.jackpot);
		payAffiliates();
		owner.transfer(this.balance);

		 
		postEvent(_winner, _winningNumber, game.rules.jackpot);

		if (!_startNew) {
			state = State.NotRunning;
			return;
		}

		nextGame(_nextRules);
	}

	 
	 

	Game game;
	Game lastGame;	

	enum PurchaseError { InvalidTicket, OutOfTickets, NotEnoughFunds, LotteryClosed, TooManyTickets, TicketUnavailable, Unknown }
	event TicketsPurchased(address buyer, uint[] tickets, uint[] failedTickets, PurchaseError[] errors);
	event PurchaseFailed(address buyer, PurchaseError error);

	 
	function purchaseTickets(uint[] _tickets) public payable {
		purchaseTicketsWithReferral(_tickets, 0);
	}

	 
	function purchaseTicketsWithReferral(uint[] _tickets, uint _affiliateCode) public payable {
		
		 
		if (state != State.Running) {
			if (state == State.NotRunning) return failPurchase(PurchaseError.LotteryClosed);
			return failPurchase(PurchaseError.OutOfTickets);
		}

		 
		if (msg.value < _tickets.length * game.rules.ticketPrice) 
			return failPurchase(PurchaseError.NotEnoughFunds);

		uint[] memory _userTickets = getMyTickets();

		 
		if (_userTickets.length >= game.rules.maxTicketsPer)
			return failPurchase(PurchaseError.TooManyTickets);

		 
		 
		uint[] memory _successful = new uint[](_tickets.length);
		uint[] memory _failed = new uint[](_tickets.length);
		PurchaseError[] memory _errors = new PurchaseError[](_tickets.length);
		uint _successCount;
		uint _errorCount;

		for(uint i = 0; i < _tickets.length; i++) {
			uint _ticket = _tickets[i];

			 
			if (_ticket <= 0 || _ticket > game.rules.slots) {
				_failed[_errorCount] = _ticket;
				_errors[_errorCount] = PurchaseError.InvalidTicket;
				_errorCount++;
				continue;
			}

			 
			if (game.tickets[_ticket] != address(0)) {
				_failed[_errorCount] = _ticket;
				_errors[_errorCount] = PurchaseError.TicketUnavailable;
				_errorCount++;
				continue;
			}

			 
			if (_userTickets.length + _successCount >= game.rules.maxTicketsPer) {
				_failed[_errorCount] = _ticket;
				_errors[_errorCount] = PurchaseError.TooManyTickets;
				_errorCount++;
				continue;
			}

			game.tickets[_ticket] = msg.sender;
			game.ticketsSold++;

			_successful[_successCount] = _ticket;
			_successCount++;
		}

		 
		 
		if (_errorCount > 0) refund(_errorCount * game.rules.ticketPrice);
		
		 
		uint _userAffiliateCode = userAffiliate();
		if (_affiliateCode != 0 && _userAffiliateCode == 0)
			_userAffiliateCode = setUserAffiliate(_affiliateCode);
		if (_userAffiliateCode != 0) addAffiliate(_userAffiliateCode, _successCount);

		 
		TicketsPurchased(msg.sender, _successful, _failed, _errors);

		 
		if (game.ticketsSold >= game.rules.slots) findWinner();
	}

	 
	function getMyTickets() public view returns (uint[]) {
		uint _userTicketCount;
		for(uint i = 0; i < game.rules.slots; i++)
			if (game.tickets[i + 1] == msg.sender) _userTicketCount += 1;

		uint[] memory _tickets = new uint[](_userTicketCount);
		uint _index;
		for(uint b = 0; b < game.rules.slots; b++) {
			if (game.tickets[b + 1] == msg.sender) {
				_tickets[_index] = b + 1;
				_index++;
			}
		}

		return _tickets;
	}

	 
	 

	struct GameRules {
		uint jackpot;
		uint slots;
		uint ticketPrice;
		uint maxTicketsPer;
	}

	function verifiedGameRules(uint _jackpot, uint _slots, uint _price, uint _max) internal pure returns (GameRules) {
		require((_price * _slots) - _jackpot > 100000000000000000);  
		require(_max <= _slots);
		return GameRules(_jackpot, _slots, _price, _max);
	}

	struct Game {
		uint id;
		GameRules rules;
		mapping(uint => address) tickets;  
		uint ticketsSold;
		GameRules nextGameRules;  
		address winner;
		uint winningNumber;
		bool loop;
		uint startedAt;
		uint finishedAt;
	}

	 
	function getCurrentGame() public view 
		returns (uint, uint, uint, uint, uint, uint, State, bool[], uint[]) {
		
		uint _remainingTickets = game.rules.slots - game.ticketsSold;
		bool[] memory _tickets = new bool[](game.rules.slots);
		uint[] memory _userTickets = getMyTickets();

		for (uint i = 0; i < game.rules.slots; i++)
			_tickets[i] = game.tickets[i + 1] == address(0);

		return (game.id, game.rules.jackpot, game.rules.slots, _remainingTickets, 
			game.rules.ticketPrice, game.rules.maxTicketsPer, state, _tickets, _userTickets);
	}

	 
	function getLastGame() public view returns(uint, uint, uint, uint, address, uint) {
		return (lastGame.id, lastGame.rules.jackpot, lastGame.rules.slots, 
			lastGame.rules.ticketPrice, lastGame.winner, lastGame.finishedAt);
	}

	 
	 

	uint[] currentGameAffiliates;
	uint numAffiliates;
	uint affiliateCut = 2;  

	function addAffiliate(uint _affiliate, uint _ticketCount) internal {
		for (uint i = 0; i < _ticketCount; i++) {
			if (numAffiliates >= currentGameAffiliates.length) currentGameAffiliates.length += 1;
			currentGameAffiliates[numAffiliates++] = _affiliate;
		}
	}

	function payAffiliates() internal {
		uint profit = (game.rules.slots * game.rules.ticketPrice) - game.rules.jackpot;
		if (profit > this.balance) profit = this.balance;

		uint _payment = (profit / game.rules.slots) / affiliateCut;
		uint _pool = _payment * numAffiliates;
		
		uint[] memory _affiliates = new uint[](numAffiliates);
		uint[] memory _amounts = new uint[](numAffiliates);

		for (uint i = 0; i < numAffiliates; i++) {
			_affiliates[i] = currentGameAffiliates[i];
			_amounts[i] = _payment;
		}

		 
		if (numAffiliates > 0)
			payoutToAffiliates(_affiliates, _amounts, _pool);

		 
		numAffiliates = 0;
	}

	 
	 

	function randomNumberFound(uint _number, uint _secret) internal {
		require(state == State.Pending);
		require(game.id == _secret);
		require(_number >= 1 && _number <= game.rules.slots);
		winnerChosen(_number);
	}

	function failPurchase(PurchaseError _error) internal {
		PurchaseFailed(msg.sender, _error);
		refund(msg.value);
	}

	function refund(uint _amount) internal {
		if (_amount > 0 && _amount <= msg.value) {
			msg.sender.transfer(_amount);
		} else if (_amount > msg.value) {
			msg.sender.transfer(msg.value);
		}
	}
}