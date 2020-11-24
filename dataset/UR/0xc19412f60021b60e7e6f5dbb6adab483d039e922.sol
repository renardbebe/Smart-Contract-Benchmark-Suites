 

pragma solidity ^ 0.4.24; 

 
 
contract IGame {
     
    address public owner; 
    address public creator;
    address public manager;
	uint256 public poolValue = 0;
	uint256 public round = 0;
	uint256 public totalBets = 0;
	uint256 public startTime = now;
    bytes32 public name;
    string public title;
	uint256 public price;
	uint256 public timespan;
	uint32 public gameType;

     
	uint256 public profitOfSociety = 5;  
	uint256 public profitOfManager = 1; 
	uint256 public profitOfFirstPlayer = 15;
	uint256 public profitOfWinner = 40;
	
	function getGame() view public returns(
        address, uint256, address, uint256, 
        uint256, uint256, uint256, 
        uint256, uint256, uint256, uint256);
} 
 
contract Owned {
    modifier isActivated {
        require(activated == true, "its not ready yet."); 
        _;
    }
    
    modifier isHuman {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
 
    modifier limits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
 
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    address public owner;
	bool public activated = true;

    constructor() public{
        owner = msg.sender;
    }

	function terminate() public onlyOwner {
		selfdestruct(owner);
	}

	function setIsActivated(bool _activated) public onlyOwner {
		activated = _activated;
	}
} 
library List {
   
  function removeIndex(uint[] storage values, uint i) internal {      
    if(i<values.length){ 
        while (i<values.length-1) {
            values[i] = values[i+1];
            i++;
        }
        values.length--;
    }
  }
} 
 
 
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
 
library NameFilter {
     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
         
        bool _hasNonNumber;
        
         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 || 
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

 


contract A21 is IGame, Owned {
  	using SafeMath for uint256;
	using List for uint[];
    using NameFilter for string;
  
	struct Bet {
		address addr;
		uint8 value;
		uint8 c1;
		uint8 c2;
		uint256 round;
		uint256 date;
		uint256 eth;
		uint256 award;
		uint8 awardType; 
	}

	struct Player { 
		mapping(uint256 => Bet) bets;
		uint256 numberOfBets;
	}	

	struct Result {
		uint256 round;
		address addr;
		uint256 award;
		uint8 awardType; 
		Bet bet;
	}

	uint256 private constant MINIMUM_PRICE = 0.01 ether;
	uint256 private constant MAXIMUM_PRICE = 100 ether;
	uint8 private constant NUMBER_OF_CARDS_VALUE = 13;
	uint8 private constant NUMBER_OF_CARDS = NUMBER_OF_CARDS_VALUE * 4;
	uint8 private constant MAXIMUM_NUMBER_OF_BETS = 26;
	uint8 private constant BLACKJACK = 21;
	uint8 private constant ENDGAME = 128;
	uint256 private constant MINIMUM_TIMESPAN = 1 minutes;  
	uint256 private constant MAXIMUM_TIMESPAN = 24 hours;  

	uint256[] private _cards;
    mapping(uint8 => Bet) private _bets;
	mapping(address => Player) private _players;  
	Result[] private _results;

	mapping(address => uint256) public balances;
    address public creator;
    address public manager;
	uint256 public poolValue = 0;
	uint256 public round = 0;
	uint256 public totalBets = 0;
	uint8 public numberOfBets = 0;
	uint256 public startTime = now;
    bytes32 public name;
    string public title;
	uint256 public price;
	uint256 public timespan;
	uint32 public gameType = BLACKJACK;
	uint8 public ace = 0;

     
	uint256 public profitOfSociety = 5;  
	uint256 public profitOfManager = 1; 
	uint256 public profitOfFirstPlayer = 15;
	uint256 public profitOfWinner = 40;
	
	 
	event OnBuy(uint256 indexed round, address indexed playerAddress, uint256 price, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnWin(uint256 indexed round, address indexed playerAddress, uint256 award, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnReward(uint256 indexed round, address indexed playerAddress, uint256 award, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnWithdraw(address indexed sender, uint256 value, uint256 timestamp); 
	event OnNewRound(uint256 indexed round, uint256 timestamp); 

	constructor(address _manager, string _name, string _title, uint256 _price, uint256 _timespan,
		uint256 _profitOfManager, uint256 _profitOfFirstPlayer, uint256 _profitOfWinner
		) public {
		require(address(_manager)!=0x0, "invaild address");
		require(_price >= MINIMUM_PRICE && _price <= MAXIMUM_PRICE, "price not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		require(_timespan >= MINIMUM_TIMESPAN && _timespan <= MAXIMUM_TIMESPAN, "timespan not in range(MINIMUM_TIMESPAN, MAXIMUM_TIMESPAN)");
		name = _name.nameFilter(); 
		require(name[0] != 0, "invaild name"); 
        require(_profitOfManager <=20, "[profitOfManager] don't take too much commission :)");
        require(_profitOfFirstPlayer <=50, "[profitOfFirstPlayer] don't take too much commission :)");
        require(_profitOfWinner <=100 && (_profitOfManager + _profitOfWinner + _profitOfFirstPlayer) <=100, "[profitOfWinner] don't take too much commission :)");
        
        creator = msg.sender;
		owner = 0x56C4ECf7fBB1B828319d8ba6033f8F3836772FA9; 
		manager = _manager;
		 
		title = _title;
		price = _price;
		timespan = _timespan;
		profitOfManager = _profitOfManager;
		profitOfFirstPlayer = _profitOfFirstPlayer;
		profitOfWinner = _profitOfWinner;

		newRound();  
	}

	function() public payable isActivated isHuman limits(msg.value){
		 
		goodluck();
	}

	function goodluck() public payable isActivated isHuman limits(msg.value) {
		require(msg.value >= price, "value < price");
		require(msg.value >= MINIMUM_PRICE && msg.value <= MAXIMUM_PRICE, "value not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		
		if(getTimeLeft()<=0){
			 
			endRound();
		}

		 
		uint256 awardOfSociety = msg.value.mul(profitOfSociety).div(100);
		poolValue = poolValue.add(msg.value).sub(awardOfSociety);
		balances[owner] = balances[owner].add(awardOfSociety);

		uint256 v = buyCore(); 

		if(v == BLACKJACK || v == ENDGAME || _cards.length<=1){
			 
			endRound();
		}		
	}

	function withdraw(uint256 amount) public isActivated isHuman returns(bool) {
		uint256 bal = balances[msg.sender];
		require(bal> 0);
		require(bal>= amount);
		require(address(this).balance>= amount);
		balances[msg.sender] = balances[msg.sender].sub(amount); 
		msg.sender.transfer(amount);

		emit OnWithdraw(msg.sender, amount, now);
		return true;
	}
    
	 
	function addAward() public payable isActivated isHuman limits(msg.value) {
		require(msg.sender == manager, "only manager can add award into pool");  
		 
		poolValue =  poolValue.add(msg.value);
	}
	
	function isPlayer(address addr) public view returns(bool){
	    return _players[addr].numberOfBets > 0 ;
	}

    function getTimeLeft() public view returns(uint256) { 
         
        uint256 _now = now;
		uint256 _endTime = startTime.add(timespan);
        
        if (_now >= _endTime){
			return 0;
		}
         
		return (_endTime - _now);
    }
    
	function getBets() public view returns (address[], uint8[], uint8[], uint8[]){
		uint len = numberOfBets;
		address[] memory ps = new address[](len);
		uint8[] memory vs = new uint8[](len);
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		uint8 i = 0; 
		while (i< len) {
			ps[i] = _bets[i].addr;
			vs[i] = _bets[i].value;
			c1s[i] = _bets[i].c1;
			c2s[i] = _bets[i].c2;
			i++;
		}

		return (ps, vs, c1s, c2s);
	} 

	function getBetHistory(address player, uint32 v) public view returns (uint256[], uint256[], uint8[], uint8[]){
		Player storage p = _players[player];
		uint256 len = v;
		if(len == 0 || len > p.numberOfBets){
		    len = p.numberOfBets;
		}
		
		uint256[] memory rounds = new uint256[](len);
		uint256[] memory awards = new uint256[](len);  
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		if(len == 0 ){
			return (rounds, awards, c1s, c2s);
		}
			
		uint256 i = 0; 
		while (i< len) { 
			Bet memory r = p.bets[p.numberOfBets-1-i];
			rounds[i] = r.round;
			awards[i] = r.award; 
			c1s[i] = r.c1;
			c2s[i] = r.c2;
			i++;
		}

		return (rounds, awards, c1s, c2s);
	}
	
    function getBetHistory2(address player, uint32 v) public view returns (uint256[], uint256[], uint8[], uint8[]){
		Player storage p = _players[player];
		uint256 len = v;
		if(len == 0 || len > p.numberOfBets){
		    len = p.numberOfBets;
		}
		
		uint256[] memory rounds = new uint256[](len);
		uint256[] memory awards = new uint256[](len);  
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		if(len == 0 ){
			return (rounds, awards, c1s, c2s);
		}
		
		uint256 i = 0; 
		while (i< len) { 
			Bet memory r = p.bets[i];
			rounds[i] = r.round;
			awards[i] = r.award; 
			c1s[i] = r.c1;
			c2s[i] = r.c2;
			i++;
		}

		return (rounds, awards, c1s, c2s);
	}
	
	function getResults(uint32 v) public view returns (uint256[], address[], uint256[], uint8[], uint8[], uint8[]){
		uint256 len = v;
		if(len == 0 || len >_results.length){
		    len = _results.length;
		}
		
		uint256[] memory rounds = new uint256[](len);
		address[] memory addrs = new address[](len);
		uint256[] memory awards = new uint256[](len); 
		uint8[] memory awardTypes = new uint8[](len);
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		
		if(len == 0 ){
			return (rounds, addrs, awards, awardTypes, c1s, c2s);
		}
		
		uint256 i = 0; 
		while (i<_results.length) { 
			Result storage r = _results[_results.length-1-i];
			rounds[i] = r.round;
			addrs[i] = r.addr;
			awards[i] = r.award;
			awardTypes[i] = r.awardType;
			c1s[i] = r.bet.c1;
			c2s[i] = r.bet.c2;
			i++;
		}

		return (rounds, addrs, awards, awardTypes, c1s, c2s);
	}
	
	
    function getGame() view public returns(
        address, uint256, address, uint256, 
        uint256, uint256, uint256, 
        uint256, uint256, uint256, uint256) {
        return (address(this), price, manager, timespan, 
            profitOfManager, profitOfFirstPlayer, profitOfWinner, 
            round, address(this).balance, poolValue, totalBets);
    }

 

	function buyCore() private returns (uint256){
		totalBets++;
		 
		(uint c1, uint c2) =  draw(); 

		uint256 v = eval(c1, c2);

		Bet storage bet =  _bets[numberOfBets++];
		bet.addr = msg.sender;
		bet.value =  uint8(v);
		bet.c1 = uint8(c1);
		bet.c2 = uint8(c2);		
		bet.round = round;
		bet.date = now;
		bet.eth = msg.value; 
		
		 
		Player storage player = _players[msg.sender];
		player.bets[player.numberOfBets++] = bet;

		emit OnBuy(round, msg.sender, msg.value, bet.value, bet.c1, bet.c2, now);

		if(c1%13==0){
		    ace++;
		}
		if(c2%13==0){
		    ace++;
		} 
		
		return ace>=4? ENDGAME: v;
	}

	function newRound() private {
		numberOfBets = 0;
		ace = 0;
		for(uint8 i =0; i < MAXIMUM_NUMBER_OF_BETS; i++){
			Bet storage bet = _bets[i];
			bet.addr = address(0);
		}

		_cards = new uint[](NUMBER_OF_CARDS);
		for(i=0; i< NUMBER_OF_CARDS; i++){
			_cards[i] = i;
		}
		_cards.length = NUMBER_OF_CARDS;
		round++; 
		startTime = now;

		emit OnNewRound(round, now);
	}

	function endRound() private {
		uint256 awardOfManager = poolValue.mul(profitOfManager).div(100);
		uint256 awardOfFirstPlayer = poolValue.mul(profitOfFirstPlayer).div(100);
		uint256 awardOfWinner = poolValue.mul(profitOfWinner).div(100);

		if(numberOfBets>0 ){
			 
			uint8 i = 0;
			int winner = -1;
			while (i< numberOfBets) {
				if(_bets[i].value == BLACKJACK){				
					winner = int(i);
					break;
				}
				i++;
			}

			address firstPlayerAddr = _bets[0].addr;
			balances[firstPlayerAddr] = balances[firstPlayerAddr].add(awardOfFirstPlayer); 
			
            _results.push(Result(round, firstPlayerAddr, awardOfFirstPlayer, 1, _bets[0]));  

            Player storage player = _players[firstPlayerAddr];
	        Bet storage _bet = player.bets[player.numberOfBets-1];
	        _bet.award = _bet.award.add(awardOfFirstPlayer);
	        _bet.awardType = 1;
		        
			emit OnReward(round, firstPlayerAddr, awardOfFirstPlayer, _bets[0].value, _bets[0].c1, _bets[0].c2, now);
			
			if(winner>=0){	
				Bet memory bet = _bets[uint8(winner)];			
				address winAddr = bet.addr; 
				balances[winAddr] = balances[winAddr].add(awardOfWinner); 
                _results.push(Result(round,winAddr, awardOfWinner, BLACKJACK, bet));
                
                player = _players[winAddr];
		        _bet = player.bets[player.numberOfBets-1];
		        _bet.award = _bet.award.add(awardOfWinner);
		        _bet.awardType = BLACKJACK;
		        
				emit OnWin(round, winAddr, awardOfWinner, bet.value, bet.c1, bet.c2, now);
			}else{
			    awardOfWinner = 0;
			}

		}else{
		     
			awardOfWinner = 0;
			awardOfFirstPlayer = 0;
			awardOfManager = 0;
		} 

		balances[manager] = balances[manager].add(awardOfManager); 
		
		poolValue =  poolValue.sub(awardOfManager).sub(awardOfFirstPlayer).sub(awardOfWinner);
		
		releaseCommission();

		newRound();
	}

	function releaseCommission() private {
		 
		 
		uint256 commission = balances[owner];
		if(commission > 0){
			owner.transfer(commission);
			balances[owner] = 0;
		}

		 
	}

	function eval(uint256 c1, uint256 c2)  private pure returns (uint256){
		c1 = cut((c1 % 13) + 1);
		c2 = cut((c2 % 13) + 1);
		if ((c1 == 1 && c2 == 10) || ((c2 == 1 && c1 == 10))) {
			return BLACKJACK;
		}

		if (c1 + c2 > BLACKJACK) {
			return 0;
		}
 
		return c1 + c2;
	}

	function cut(uint256 v) private pure returns (uint256){
		return (v > 10 ? 10 : v);
	}

	function draw() private returns (uint, uint) {
	    uint256 max = _cards.length * (_cards.length - 1) /2;
		uint256 ind = rand(max);
		(uint256 i1, uint256 i2) = index2pair(ind);
		uint256 c1 = _cards[i1];
		_cards.removeIndex(i1); 
		uint256 c2 = _cards[i2];
		_cards.removeIndex(i2);
		return (c1, c2);
	}

	function rand(uint256 max) private view returns (uint256){
		uint256 _seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp) +
                (block.difficulty) +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                (block.gaslimit) +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                (block.number)
        ))); 
		
		return _seed % max; 
	}

	function index2pair(uint x) private pure returns (uint, uint) { 
		uint c1 = ((sqrt(8*x+1) - 1)/2 +1);
		uint c2 = (x - c1*(c1-1)/2);
		return (c1, c2);
	}

	function sqrt(uint x) private pure returns (uint) {
		uint z = (x + 1) / 2;
		uint y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}

		return y;
	}
 
}

contract A21Builder{
    function buildGame (address _manager, string _name, string _title, uint256 _price, uint256 _timespan,
        uint8 _profitOfManager, uint8 _profitOfFirstPlayer, uint8 _profitOfWinner) payable external returns(address){
       
        address game = new A21(_manager, _name, _title, _price, _timespan, _profitOfManager, _profitOfFirstPlayer, _profitOfWinner);
        return game;   
    }
}