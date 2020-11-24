 

pragma solidity ^0.4.21;


 
 
contract OwnerBase {

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;
    
     
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCOO whenPaused {
         
        paused = false;
    }
	
	
	 
    function isNormalUser(address addr) internal view returns (bool) {
		if (addr == address(0)) {
			return false;
		}
        uint size = 0;
        assembly { 
		    size := extcodesize(addr) 
		} 
        return size == 0;
    }
}


 
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
 
}



 
 
contract PartnerHolder {
     
    function isHolder() public pure returns (bool);
    
     
    function bonusAll() payable public ;
	
	
	function bonusOne(uint id) payable public ;
    
}

 
 
contract Partners is OwnerBase, SafeMath, PartnerHolder {

    event Bought(uint16 id, address newOwner, uint price, address oldOwner);
    
	 
    struct Casino {
		uint16 id;
		uint16 star;
		address owner;
		uint price;
		string name;
		string desc;
    }
	
	 
	mapping(address => uint) public balances;
	
	
	mapping(uint => Casino) public allCasinos;  
	
	 
	uint[] public ids;
	
	
	uint public masterCut = 200;
	
	 
	uint public masterHas = 0;
	
	
	function Partners() public {
		ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
		
	}
	
	function initCasino() public onlyCOO {
		addCasino(5, 100000000000000000, 'Las Vegas Bellagio Casino', 'Five star Casino');
		addCasino(4, 70000000000000000, 'London Ritz Club Casino', 'Four star Casino');
		addCasino(4, 70000000000000000, 'Las Vegas Metropolitan Casino', 'Four star Casino');
		addCasino(4, 70000000000000000, 'Argentina Park Hyatt Mendoza Casino', 'Four star Casino');
		addCasino(3, 30000000000000000, 'Canada Golf Thalasso & Casino Resort', 'Three star Casino');
		addCasino(3, 30000000000000000, 'Monaco Monte-Carlo Casino', 'Three star Casino');
		addCasino(3, 30000000000000000, 'Las Vegas Flamingo Casino', 'Three star Casino');
		addCasino(3, 30000000000000000, 'New Jersey Bogota Casino', 'Three star Casino');
		addCasino(3, 30000000000000000, 'Atlantic City Taj Mahal Casino', 'Three star Casino');
		addCasino(2, 20000000000000000, 'Dubai Atlantis Casino', 'Two star Casino');
		addCasino(2, 20000000000000000, 'Germany Baden-Baden Casino', 'Two star Casino');
		addCasino(2, 20000000000000000, 'South Korea Paradise Walker Hill Casino', 'Two star Casino');
		addCasino(2, 20000000000000000, 'Las Vegas Paris Casino', 'Two star Casino');
		addCasino(2, 20000000000000000, 'Las Vegas Caesars Palace Casino', 'Two star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas Riviera Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas Mandalay Bay Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas MGM Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas New York Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas  Renaissance Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Las Vegas Venetian Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Melbourne Crown Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Macao Grand Lisb Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Singapore Marina Bay Sands Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Malaysia Cloud Top Mountain Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'South Africa Sun City Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Vietnam Smear Peninsula Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Macao Sands Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Bahamas Paradise Island Casino', 'One star Casino');
		addCasino(1, 10000000000000000, 'Philippines Manila Casinos', 'One star Casino');
	}
	 
	function () payable public {
		 
		masterHas = safeAdd(masterHas, msg.value);
	}
	
	 
	function addCasino(uint16 _star, uint _price, string _name, string _desc) internal 
	{
		uint newID = ids.length + 1;
		Casino memory item = Casino({
			id:uint16(newID),
			star:_star,
			owner:cooAddress,
			price:_price,
			name:_name,
			desc:_desc
		});
		allCasinos[newID] = item;
		ids.push(newID);
	}
	
	 
	function setCasinoName(uint16 id, string _name, string _desc) public onlyCOO 
	{
		Casino storage item = allCasinos[id];
		require(item.id > 0);
		item.name = _name;
		item.desc = _desc;
	}
	
	 
	function isOwner( address addr) public view returns (uint16) 
	{
		for(uint16 id = 1; id <= 29; id++) {
			Casino storage item = allCasinos[id];
			if ( item.owner == addr) {
				return id;
			}
		}
		return 0;
	}
	
	 
	function isHolder() public pure returns (bool) {
		return true;
	}
	
	
	 
	function bonusAll() payable public {
		uint total = msg.value;
		uint remain = total;
		if (total > 0) {
			for (uint i = 0; i < ids.length; i++) {
				uint id = ids[i];
				Casino storage item = allCasinos[id];
				uint fund = 0;
				if (item.star == 5) {
					fund = safeDiv(safeMul(total, 2000), 10000);
				} else if (item.star == 4) {
					fund = safeDiv(safeMul(total, 1000), 10000);
				} else if (item.star == 3) {
					fund = safeDiv(safeMul(total, 500), 10000);
				} else if (item.star == 2) {
					fund = safeDiv(safeMul(total, 200), 10000);
				} else {
					fund = safeDiv(safeMul(total, 100), 10000);
				}
				
				if (remain >= fund) {
					remain -= fund;
					address owner = item.owner;
					if (owner != address(0)) {
						uint oldVal = balances[owner];
						balances[owner] = safeAdd(oldVal, fund);
					}
				}
			}
		}
		
	}
	
	
	 
	function bonusOne(uint id) payable public {
		Casino storage item = allCasinos[id];
		address owner = item.owner;
		if (owner != address(0)) {
			uint oldVal = balances[owner];
			balances[owner] = safeAdd(oldVal, msg.value);
		} else {
			masterHas = safeAdd(masterHas, msg.value);
		}
	}
	
	
	 
	function userWithdraw() public {
		uint fund = balances[msg.sender];
		require (fund > 0);
		delete balances[msg.sender];
		msg.sender.transfer(fund);
	}
	
	
    
     
    function buy(uint16 _id) payable public returns (bool) {
		Casino storage item = allCasinos[_id];
		uint oldPrice = item.price;
		require(oldPrice > 0);
		require(msg.value >= oldPrice);
		
		address oldOwner = item.owner;
		address newOwner = msg.sender;
		require(oldOwner != address(0));
		require(oldOwner != newOwner);
		require(isNormalUser(newOwner));
		
		item.price = calcNextPrice(oldPrice);
		item.owner = newOwner;
		emit Bought(_id, newOwner, oldPrice, oldOwner);
		
		 
		uint256 devCut = safeDiv(safeMul(oldPrice, masterCut), 10000);
		oldOwner.transfer(safeSub(oldPrice, devCut));
		masterHas = safeAdd(masterHas, devCut);
		
		uint256 excess = msg.value - oldPrice;
		if (excess > 0) {
			newOwner.transfer(excess);
		}
    }
	
	
	
	 
	function calcNextPrice (uint _price) public pure returns (uint nextPrice) {
		if (_price >= 5 ether ) {
			return safeDiv(safeMul(_price, 110), 100);
		} else if (_price >= 2 ether ) {
			return safeDiv(safeMul(_price, 120), 100);
		} else if (_price >= 500 finney ) {
			return safeDiv(safeMul(_price, 130), 100);
		} else if (_price >= 20 finney ) {
			return safeDiv(safeMul(_price, 140), 100);
		} else {
			return safeDiv(safeMul(_price, 200), 100);
		}
	}
	
	
	 
    function cfoWithdraw() external onlyCFO {
		cfoAddress.transfer(masterHas);
		masterHas = 0;
    }
	
	
	
	 
    function withdrawDeadFund( address addr) external onlyCFO {
        uint fund = balances[addr];
        require (fund > 0);
        delete balances[addr];
        cfoAddress.transfer(fund);
    }
	
	
}