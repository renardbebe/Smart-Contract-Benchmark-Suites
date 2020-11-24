 
contract EtheleToken is ERC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;

    address private _creator;
     
     
     
     
    address private _transmuteSource1;
    address private _transmuteSource2;
    address private _transmuteSource3;
    address private _transmuteSource4;
    mapping (address => bool) private _allowBurnsFrom;  

    uint256 private _totalLocked;
    mapping (address => uint256) private _lockedBalance;
    mapping (address => uint256) private _harvestStartPeriod;
    mapping (address => uint256) private _unlockTime;

    uint256 private constant PERIOD_LENGTH = 1 days; 
    uint256 private constant MINT_AMOUNT = 100000 ether;  
    uint256 private _currentPeriod;
    uint256 private _contractStartTime;
    uint256[] private _cumulTokenPerEth;  

    constructor(
        string memory name,
        string memory symbol
    ) public {
          
          
        _creator = msg.sender;

        _name = name;
        _symbol = symbol;

        _currentPeriod = 1;
        _cumulTokenPerEth.push(0);
        _contractStartTime = block.timestamp;
    }


    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    function getCreator() public view returns (address) {
    	return _creator;
    }

    function getTransmuteSource1() public view returns (address) {
		return _transmuteSource1;
    }
    function getTransmuteSource2() public view returns (address) {
    	return _transmuteSource2;
    }
    function getTransmuteSource3() public view returns (address) {
    	return _transmuteSource3;
    }
    function getTransmuteSource4() public view returns (address) {
    	return _transmuteSource4;
    }
    function getAllowBurnsFrom(address addr) public view returns (bool) {
    	return _allowBurnsFrom[addr];
    }

    function getTotalLocked() public view returns (uint256) {
    	return _totalLocked;
    }
    function getLockedBalance(address addr) public view returns (uint256) {
    	return _lockedBalance[addr];
    }    
    function getHarvestStartPeriod(address addr) public view returns (uint256) {
    	return _harvestStartPeriod[addr];
    }    
    function getUnlockTime(address addr) public view returns (uint256) {
    	return _unlockTime[addr];
    }
     
     
    function getHarvestableAmount(address addr) public view returns (uint256) {
        uint256 intendedPeriod = (block.timestamp).sub(_contractStartTime).div(PERIOD_LENGTH).add(1);
        uint256 harvestStartPeriod = _harvestStartPeriod[addr];
        uint256 lockedBalance = _lockedBalance[addr];

        if (harvestStartPeriod >= intendedPeriod.sub(1) ||
            lockedBalance == 0) {
            return 0;
        }
        else {
            uint256 harvestableTokenPerEth = MINT_AMOUNT.mul(1 ether).div(_totalLocked);
            uint256 harvestableAmount;
              
            if (harvestStartPeriod == _currentPeriod) {
                 
                uint256 periodDiff = intendedPeriod.sub(1).sub(harvestStartPeriod);
                harvestableAmount = periodDiff
                                          .mul(harvestableTokenPerEth)
                                          .mul(lockedBalance)
                                          .div(1 ether);
            } else {
                 
                uint256 periodDiff = intendedPeriod.sub(_currentPeriod);
                uint256 tokenPerEthInPeriodDiff = harvestableTokenPerEth.mul(periodDiff);

                 
                harvestableAmount = tokenPerEthInPeriodDiff
                                            .add(_cumulTokenPerEth[_currentPeriod.sub(1)])
                                            .sub(_cumulTokenPerEth[harvestStartPeriod])
                                            .mul(lockedBalance)
                                            .div(1 ether);
            }

            return harvestableAmount;
        }
    }

    function getPeriodLength() public pure returns (uint256) {
        return PERIOD_LENGTH; 
    }
    function getMintAmount() public pure returns (uint256) {
        return MINT_AMOUNT; 
    }
    function getCurrentPeriod() public view returns (uint256) {
        return _currentPeriod; 
    }
    function getContractStartTime() public view returns (uint256) {
        return _contractStartTime; 
    }
    function getCumulTokenPerEth(uint256 period) public view returns (uint256) {
    	return _cumulTokenPerEth[period];
    }

     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    function burnFrom(address account, uint256 amount) public {
    	 
         
    	if (_allowBurnsFrom[msg.sender]) {
    		_burn(account, amount);
    	} else {
        	_burnFrom(account, amount);
    	}
    }

    function setTransmuteSources12(address transmuteSource1, address transmuteSource2) public {
        require(msg.sender == _creator);
        _transmuteSource1 = transmuteSource1;
        _transmuteSource2 = transmuteSource2;
    } 

    function setTransmuteSources34(address transmuteSource3, address transmuteSource4) public {
        require(msg.sender == _creator);
        _transmuteSource3 = transmuteSource3;
        _transmuteSource4 = transmuteSource4;
    } 

    function allowBurnsFrom(address burner) public {
    	require(msg.sender == _creator);
    	_allowBurnsFrom[burner] = true;
    }


     
    function transmute(uint256 amount, uint256 transmuteType) public {
    	require(transmuteType == 0 || transmuteType == 1, "EtheleToken: Transmute type should be 0 or 1.");
    	if (transmuteType == 0) {
			require(_transmuteSource1 != address(0) && _transmuteSource2 != address(0), "EtheleToken: Cannot transmute this.");
    		EtheleToken(_transmuteSource1).burnFrom(msg.sender, amount);
    		EtheleToken(_transmuteSource2).burnFrom(msg.sender, amount);
    		_mint(msg.sender, amount);
		} else if (transmuteType == 1) {
			require(_transmuteSource3 != address(0) && _transmuteSource4 != address(0), "EtheleToken: Cannot transmute this.");
    		EtheleToken(_transmuteSource3).burnFrom(msg.sender, amount);
    		EtheleToken(_transmuteSource4).burnFrom(msg.sender, amount);
    		_mint(msg.sender, amount);
		}
    }

     
     
    function updatePeriod(int256 steps) public {
    	uint256 intendedPeriod = (block.timestamp).sub(_contractStartTime).div(PERIOD_LENGTH).add(1);
    	if (_currentPeriod < intendedPeriod) {
			uint256 harvestableTokenPerEth;
    		if (_totalLocked == 0) {
    			harvestableTokenPerEth = 0;
    		} else {
    			harvestableTokenPerEth = MINT_AMOUNT.mul(1 ether).div(_totalLocked);
    		}

    		 
    		while (_currentPeriod < intendedPeriod && steps != 0) {
    			_cumulTokenPerEth.push(_cumulTokenPerEth[_currentPeriod-1].add(harvestableTokenPerEth));
    			_currentPeriod += 1;
    			steps -= 1;
    		}
    	}
    }

     
     
     
     
    function lock() public payable {
    	require(_lockedBalance[msg.sender] == 0, "EtheleToken: To lock, you must not have any existing locked ETH.");
    	updatePeriod(-1);

    	_totalLocked = _totalLocked.add(msg.value);
    	_lockedBalance[msg.sender] = msg.value;
    	_harvestStartPeriod[msg.sender] = _currentPeriod;
    	_unlockTime[msg.sender] = block.timestamp.add(PERIOD_LENGTH);
    }

    function harvest() public {
    	require(_lockedBalance[msg.sender] > 0, "EtheleToken: Require locked balance to harvest.");
    	updatePeriod(-1);

    	require(_harvestStartPeriod[msg.sender] < _currentPeriod-1, "EtheleToken: Nothing to harvest - Lock start period should be before previous currentPeriod.");
    	uint256 amountHarvested = _cumulTokenPerEth[_currentPeriod-1]
    							.sub(_cumulTokenPerEth[_harvestStartPeriod[msg.sender]])
    							.mul(_lockedBalance[msg.sender])
    							.div(1 ether);
    	_harvestStartPeriod[msg.sender] = _currentPeriod-1;
    	_mint(msg.sender, amountHarvested);	
    }

    function unlock() public {
    	require(_lockedBalance[msg.sender] > 0, "EtheleToken: Require locked balance to unlock.");
    	updatePeriod(-1);

    	require(_unlockTime[msg.sender] < block.timestamp, "EtheleToken: Minimum lock time not yet reached.");
    	uint256 amount = _lockedBalance[msg.sender];
    	_lockedBalance[msg.sender] = 0;
    	_totalLocked = _totalLocked.sub(amount);
    	msg.sender.transfer(amount);
    }
}
