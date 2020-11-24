 

pragma solidity ^0.4.20;


contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
	address public owner;

    constructor() public { owner = msg.sender; }

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {

    event Pause();
	
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() { require(!paused); _; }

    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract EtherDrop is Pausable {

     
    uint priceWei;

     
	uint qMax;
    
	 
	 uint dMax;

	 
    event NewSubscriber(address indexed addr, uint indexed round, uint place);
    
	 
	event NewDropOut(address indexed addr, uint indexed round, uint place, uint price);
	
	 
	uint _lock;
	
	 
	uint _block;
    
	 
	uint _round; 
	
     
    uint _collectibles;
	
	 
	address[] _queue;
	
     
	mapping(address => uint) _userRound;
	
	 
	constructor(uint order, uint price) public {
		
		 
		require(0 < order && order < 4 && price >= 1e16 && price <= 1e18);
		
		 
		dMax = order;
		qMax = 10**order;

         
	    priceWei = price;
		
		 
	    _round = 1;
	    _block = block.number;
	}
	
	 
    function stat() public view returns (uint round, uint position, uint max, 
        uint price, uint blok, uint lock) {
        return ( _round - (_queue.length == qMax ? 1 : 0), _queue.length, qMax, 
            priceWei, _block, _lock);
    }
	
	 
	function userRound(address user) public view returns (uint lastRound, uint currentRound) {
		return (_userRound[user], _round - (_queue.length == qMax ? 1 : 0));
	}

	 
    function() public payable whenNotPaused {

		 
        require(tx.origin == msg.sender && msg.value >= priceWei);
	
		 
		if (_lock > 0 && block.number >= _lock) {	
			 
			uint _r = dMax;
            uint _winpos = 0;
			bytes32 _a = blockhash(_lock);
			for (uint i = 31; i >= 1; i--) {
				if (uint8(_a[i]) >= 48 && uint8(_a[i]) <= 57) {
					_winpos = 10 * _winpos + (uint8(_a[i]) - 48);
					if (--_r == 0) break;
				}
			}
            
			 
			uint _reward = (qMax * priceWei * 90) / 100;
            _collectibles += address(this).balance - _reward;
			_queue[_winpos].transfer(_reward);
            
			 
			emit NewDropOut(_queue[_winpos], _round - 1, _winpos + 1, _reward);
			
			 
            _block = block.number;
            
             
            _lock = 0;
			
			 
			delete _queue;
        }
		 
		else if (block.number + 1 == _lock) {
			revert();
		}
        
		 
		require(_userRound[msg.sender] != _round);
		
		 
		_userRound[msg.sender] = _round;
		
		 
        _queue.push(msg.sender);

		 
        emit NewSubscriber(msg.sender, _round, _queue.length);
        
		 
        if (_queue.length == qMax) {
            _round++;
            _lock = block.number + 1;
        }
    }

     
    function support() public onlyOwner {
        owner.transfer(_collectibles);
		_collectibles = 0;
    }
}