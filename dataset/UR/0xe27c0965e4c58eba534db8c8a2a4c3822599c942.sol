 

 

pragma solidity ^0.4.25;


 
library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

}

contract Ownable {
	address private owner;
	
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }	
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

	uint256 private _totalSupply;
	
	 
     
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function transfer(address from, address to, uint256 value) public onlyOwner returns (bool) {
        _transfer(from, to, value);
        return true;
    }

     
    function mint(address account, uint256 value) public onlyOwner returns (bool) {
        _mint(account, value);
        return true;
    }
	
     
    function burn(address account, uint256 value) public onlyOwner returns (bool) {
        _burn(account, value);
        return true;
    }	
	
     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
    }


}

contract KingdomStorage is ERC20 {
    using SafeMath for uint256;

    uint private _kingdomsCount;

    struct Kingdom {
        uint numberOfCitizens;
		uint numberOfWarriors;
		uint prosperity;
		uint defence;
		uint lostCoins;  
        uint tributeCheckpoint;
    }

	mapping (uint => address) private kingdomAddress;
    mapping (address => Kingdom) private kingdoms;
	
	event War(address indexed _attacked, address indexed _invader, uint _lostCoins, uint _slayedWarriors);

    function addCitizens(address _address, uint _number, bool _are_warriors) external onlyOwner {
		if (kingdoms[_address].prosperity == 0) {
			 
			kingdomAddress[_kingdomsCount] = _address;
			kingdoms[_address].prosperity = 50;
			kingdoms[_address].defence = 50;	
			_kingdomsCount++;
		}
		
        if (_are_warriors) {
			 
			kingdoms[_address].numberOfWarriors = kingdoms[_address].numberOfWarriors.add(_number);
		} else {
			 
			kingdoms[_address].numberOfCitizens = kingdoms[_address].numberOfCitizens.add(_number);
			kingdoms[_address].tributeCheckpoint = block.timestamp;
		}

    }
	
    function getTribute(address _address) external onlyOwner {
		uint tributeValue = getTributeValue(_address);
		if (tributeValue > 0) {
			mint(_address, tributeValue);
			kingdoms[_address].tributeCheckpoint = block.timestamp;
			kingdoms[_address].lostCoins = 0;
		}
    }
	
	function startWar(address _invader, address _attacked) external onlyOwner {
		uint invaderWarriorsNumber = getWarriorsNumber(_invader);
		require (invaderWarriorsNumber >0);
		
		uint attackedKingdomBalance = balanceOf(_attacked);		
		uint attackedKingdomWealth = getTributeValue(_attacked).add(attackedKingdomBalance);
		uint attackedKingdomDefence = getDefence(_attacked); 
		
		 
		uint attackPower = invaderWarriorsNumber.mul(100 - attackedKingdomDefence); 
		if (attackPower > attackedKingdomWealth)
			attackPower = attackedKingdomWealth;
		
		 
		uint slayedWarriors;
		 
		if (attackedKingdomWealth > 10000) {
			slayedWarriors = invaderWarriorsNumber.mul(attackedKingdomDefence).div(100);	
			kingdoms[_invader].numberOfWarriors -= slayedWarriors;
		}
		
		 
		uint lostCoins;
		
		if (attackedKingdomBalance >= attackPower) {
			transfer(_attacked, _invader, attackPower);
			lostCoins += attackPower;
			attackPower = 0;
		} else if (attackedKingdomBalance > 0) {
			transfer(_attacked, _invader, attackedKingdomBalance);
			lostCoins += attackedKingdomBalance;
			attackPower -= attackedKingdomBalance;
		} 

		if (attackPower > 0) {
			kingdoms[_attacked].lostCoins += attackPower;
			mint(_invader, attackPower);
			lostCoins += attackPower;
		}
		
		emit War(_attacked, _invader, lostCoins, slayedWarriors);
	}
	
	function warFailed(address _invader) external onlyOwner {
		emit War(address(0), _invader, 0, 0);
	}
	
    function increaseProsperity(address _address) external onlyOwner {
		 
		if (kingdoms[_address].prosperity <= 90) {
			kingdoms[_address].prosperity += 10;
			kingdoms[_address].defence -= 10;
		}
    }	
	
    function increaseDefence(address _address) external onlyOwner {
		 
		if (kingdoms[_address].defence <= 80) {
			kingdoms[_address].defence += 10;
			kingdoms[_address].prosperity -= 10;
		}
    }	

    function getTributeValue(address _address) public view returns(uint) {
		uint numberOfCitizens = getCitizensNumber(_address);
		if (numberOfCitizens > 0) {
			 
			return numberOfCitizens.mul(getProsperity(_address)).mul(block.timestamp.sub(getTributeCheckpoint(_address))).div(7 days).sub(getLostCoins(_address)); 
		}
		return 0;
    }	

    function getProsperity(address _address) public view returns(uint) {
		return kingdoms[_address].prosperity;
    }
	
    function getDefence(address _address) public view returns(uint) {
		return kingdoms[_address].defence;
    }	
    function getLostCoins(address _address) public view returns(uint) {
		return kingdoms[_address].lostCoins;
    }	

    function getCitizensNumber(address _address) public view returns(uint) {
        return kingdoms[_address].numberOfCitizens;
    }

    function getWarriorsNumber(address _address) public view returns(uint) {
        return kingdoms[_address].numberOfWarriors;
    }
	
    function getTributeCheckpoint(address _address) public view returns(uint) {
        return kingdoms[_address].tributeCheckpoint;
    }

    function getKingdomAddress(uint _kingdomId) external view returns(address) {
        return kingdomAddress[_kingdomId];
    }
	
	function kingdomsCount() external view returns(uint) {
        return _kingdomsCount;
    }
}

contract GreenRabbitKingdom is IERC20 {
    using SafeMath for uint;

    address admin;

    uint invested;
    uint payed;
    uint startTime;
	uint tokenStartPrice;
	
	string public name = 'GreenRabbitCoin';
	string public symbol = 'GRC';
	uint public decimals = 0;
	
    event LogNewGame(uint _startTime);
	
    KingdomStorage private kingdom;

    modifier notOnPause() {
        require(startTime <= block.timestamp, "Game paused");
        _;
    }

    constructor() public {
        admin = msg.sender;
        kingdom = new KingdomStorage();
        startTime = now;
		tokenStartPrice = 1 szabo;  
    }
 
    function() external payable {
        if (msg.value == 0 && msg.value <= 0.00001 ether) {
            sellTokens();
        } else if (msg.value == 0.000111 ether) {
			 
            addCitizens(false);
        } else if (msg.value == 0.000222 ether) {
			 
            addCitizens(true);
        } else if (msg.value == 0.000333 ether) {
            increaseProsperity();
        } else if (msg.value == 0.000444 ether) {
            increaseDefence();
		} else {            
			buyTokens();
        }
    }

     
    function totalSupply() external view returns (uint256) {
        return kingdom.totalSupply();
    }

     
    function transfer(address to, uint256 value) external returns (bool) {
		 
		kingdom.getTribute(msg.sender);
        return kingdom.transfer(msg.sender, to, value);
    }	

     
	function balanceOf(address owner) public view returns (uint256) {
        return kingdom.balanceOf(owner);
    }
	
    function buyTokens() notOnPause public payable {
		require (msg.value >= 0.001 ether);
		uint tokensValue = msg.value.div(getTokenSellPrice()).mul(90).div(100);
		kingdom.mint(msg.sender, tokensValue);
		admin.send(msg.value / 20);  
		emit Transfer(address(0), msg.sender, tokensValue);
    }

    function sellTokens() notOnPause public {
		 
		kingdom.getTribute(msg.sender);
		
        uint tokensValue = balanceOf(msg.sender); 
		uint payout = tokensValue.mul(getTokenSellPrice());

        if (payout > 0) {

            if (payout > address(this).balance) {
				msg.sender.transfer(address(this).balance);
                nextGame();
                return;
            }

            msg.sender.transfer(payout);
			
			kingdom.burn(msg.sender, tokensValue);
			emit Transfer(msg.sender, address(0), tokensValue);
        }		
    }
	
	function addCitizens(bool _are_warriors) notOnPause public {
		 
		kingdom.getTribute(msg.sender);
		
		uint CitizensNumber = balanceOf(msg.sender).div(100);
		if (CitizensNumber > 0) {
			kingdom.addCitizens(msg.sender,CitizensNumber,_are_warriors);
			kingdom.burn(msg.sender, CitizensNumber * 100);
		}
	}
	
    function attackKingdom(address _invader, uint _random) notOnPause public returns(bool) {
		 
		 
		require (msg.sender == 0x76d7aed5ab1c4a5e210d0ccac747d097f9d58966); 
		
		uint attackedKingdomId = _random % (kingdom.kingdomsCount());
		address attackedKingdomAddress = kingdom.getKingdomAddress(attackedKingdomId);
		
		if (_invader != attackedKingdomAddress) {
			kingdom.startWar(_invader, attackedKingdomAddress);
		} else {
			 
			kingdom.warFailed(_invader);
		}
			
        return true;
    }	
	
	function increaseProsperity() notOnPause public {
		 
		kingdom.getTribute(msg.sender);
		kingdom.increaseProsperity(msg.sender);
	}
	
	function increaseDefence() notOnPause public {
		 
		kingdom.getTribute(msg.sender);		
		kingdom.increaseDefence(msg.sender);
	}
	
	function synchronizeTokensBalance() notOnPause public {
		 
		 
		kingdom.getTribute(msg.sender);		
	}	
	
	function getTokenSellPrice() public view returns(uint) {
		 
		return tokenStartPrice.add( tokenStartPrice.div(100).mul(block.timestamp.sub(startTime).div(1 days)) );
	}

    function getGameAge() external view returns(uint) {
		if (block.timestamp > startTime)
			return block.timestamp.sub(startTime).div(1 days).add(1);
		else 
			return 0;
    }
	
    function getKingdomsCount() external view returns(uint) {
        return kingdom.kingdomsCount();
    }
	
    function getKingdomData(address _address) external view returns(uint numberOfCitizens, uint numberOfWarriors, uint prosperity, uint defence, uint balance) {
		numberOfCitizens = kingdom.getCitizensNumber(_address);
		numberOfWarriors = kingdom.getWarriorsNumber(_address);
		prosperity = kingdom.getProsperity(_address);
		defence = kingdom.getDefence(_address);
		balance = kingdom.getTributeValue(_address) + balanceOf(_address);
    }	

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function nextGame() private {
        kingdom = new KingdomStorage();
        startTime = block.timestamp + 3 days;
        emit LogNewGame(startTime);
    }
	
}