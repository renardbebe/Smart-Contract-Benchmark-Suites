 

pragma solidity ^0.4.21;

 
contract Ownable {
	address public owner;

	 
	function Ownable() public {
		owner = tx.origin;
	}


	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


     
	function transferOwnership(address _newOwner) onlyOwner public {
		require(_newOwner != address(0));
		owner = _newOwner;
	}
}








 
contract BasicERC20Token is Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);


     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


     
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }


     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     
    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        require (_from != 0x0);                                
        require (_to != 0x0);                                
        require (balances[_from] >= _amount);           
        require (balances[_to] + _amount > balances[_to]);   

        uint256 length;
        assembly {
            length := extcodesize(_to)
        }
        require (length == 0);

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        
        return true;
    }


     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);

        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require (allowed[_from][msg.sender] >= _amount);           

        _transfer(_from, _to, _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return true;
    }


     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require (_spender != 0x0);                        
        require (_amount >= 0);
        require (balances[msg.sender] >= _amount);        

        if (_amount == 0) allowed[msg.sender][_spender] = _amount;
        else allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}

 
contract PULSToken is BasicERC20Token {
	 
	string public constant name = 'PULS Token';
	string public constant symbol = 'PULS';
	uint256 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	address public crowdsaleAddress;

	 
	struct Reserve {
        uint256 pulsAmount;
        uint256 collectedEther;
    }

	mapping (address => Reserve) reserved;

	 
	struct Lock {
		uint256 amount;
		uint256 startTime;	 
		uint256 timeToLock;  
		bytes32 pulseLockHash;
	}
	
	 
	struct lockList{
		Lock[] lockedTokens;
	}
	
	 
	mapping (address => lockList) addressLocks;

	 
	modifier onlyCrowdsaleAddress() {
		require(msg.sender == crowdsaleAddress);
		_;
	}

	event TokenReservation(address indexed beneficiary, uint256 sendEther, uint256 indexed pulsAmount, uint256 reserveTypeId);
	event RevertingReservation(address indexed addressToRevert);
	event TokenLocking(address indexed addressToLock, uint256 indexed amount, uint256 timeToLock);
	event TokenUnlocking(address indexed addressToUnlock, uint256 indexed amount);


	 
	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		
		crowdsaleAddress = msg.sender;

		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}


	 
	function () external payable {
	}


	 
	function reserveOf(address _owner) public view returns (uint256) {
		return reserved[_owner].pulsAmount;
	}


	 
	function collectedEtherFrom(address _buyer) public view returns (uint256) {
		return reserved[_buyer].collectedEther;
	}


	 
	function getAddressLockedLength(address _address) public view returns(uint256 length) {
	    return addressLocks[_address].lockedTokens.length;
	}


	 
	function getLockedStructAmount(address _address, uint256 _index) public view returns(uint256 amount) {
	    return addressLocks[_address].lockedTokens[_index].amount;
	}


	 
	function getLockedStructStartTime(address _address, uint256 _index) public view returns(uint256 startTime) {
	    return addressLocks[_address].lockedTokens[_index].startTime;
	}


	 
	function getLockedStructTimeToLock(address _address, uint256 _index) public view returns(uint256 timeToLock) {
	    return addressLocks[_address].lockedTokens[_index].timeToLock;
	}

	
	 
	function getLockedStructPulseLockHash(address _address, uint256 _index) public view returns(bytes32 pulseLockHash) {
	    return addressLocks[_address].lockedTokens[_index].pulseLockHash;
	}


	 
	function sendTokens(address _beneficiary) onlyOwner public returns (bool) {
		require (reserved[_beneficiary].pulsAmount > 0);		  

		_transfer(crowdsaleAddress, _beneficiary, reserved[_beneficiary].pulsAmount);

		reserved[_beneficiary].pulsAmount = 0;

		return true;
	}


	 
	function reserveTokens(address _beneficiary, uint256 _pulsAmount, uint256 _eth, uint256 _reserveTypeId) onlyCrowdsaleAddress public returns (bool) {
		require (_beneficiary != 0x0);					 
		require (totalSupply >= _pulsAmount);            

		totalSupply = totalSupply.sub(_pulsAmount);
		reserved[_beneficiary].pulsAmount = reserved[_beneficiary].pulsAmount.add(_pulsAmount);
		reserved[_beneficiary].collectedEther = reserved[_beneficiary].collectedEther.add(_eth);

		emit TokenReservation(_beneficiary, _eth, _pulsAmount, _reserveTypeId);
		return true;
	}


	 
	function revertReservation(address _addressToRevert) onlyOwner public returns (bool) {
		require (reserved[_addressToRevert].pulsAmount > 0);	

		totalSupply = totalSupply.add(reserved[_addressToRevert].pulsAmount);
		reserved[_addressToRevert].pulsAmount = 0;

		_addressToRevert.transfer(reserved[_addressToRevert].collectedEther - (20000000000 * 21000));
		reserved[_addressToRevert].collectedEther = 0;

		emit RevertingReservation(_addressToRevert);
		return true;
	}


	 
	function lockTokens(uint256 _amount, uint256 _minutesToLock, bytes32 _pulseLockHash) public returns (bool){
		require(balances[msg.sender] >= _amount);

		Lock memory lockStruct;
        lockStruct.amount = _amount;
        lockStruct.startTime = now;
        lockStruct.timeToLock = _minutesToLock * 1 minutes;
        lockStruct.pulseLockHash = _pulseLockHash;

        addressLocks[msg.sender].lockedTokens.push(lockStruct);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit TokenLocking(msg.sender, _amount, _minutesToLock);
        return true;
	}


	 
	function unlockTokens(address _addressToUnlock) public returns (bool){
		uint256 i = 0;
		while(i < addressLocks[_addressToUnlock].lockedTokens.length) {
			if (now > addressLocks[_addressToUnlock].lockedTokens[i].startTime + addressLocks[_addressToUnlock].lockedTokens[i].timeToLock) {

				balances[_addressToUnlock] = balances[_addressToUnlock].add(addressLocks[_addressToUnlock].lockedTokens[i].amount);
				emit TokenUnlocking(_addressToUnlock, addressLocks[_addressToUnlock].lockedTokens[i].amount);

				if (i < addressLocks[_addressToUnlock].lockedTokens.length) {
					for (uint256 j = i; j < addressLocks[_addressToUnlock].lockedTokens.length - 1; j++){
			            addressLocks[_addressToUnlock].lockedTokens[j] = addressLocks[_addressToUnlock].lockedTokens[j + 1];
			        }
				}
		        delete addressLocks[_addressToUnlock].lockedTokens[addressLocks[_addressToUnlock].lockedTokens.length - 1];
				
				addressLocks[_addressToUnlock].lockedTokens.length = addressLocks[_addressToUnlock].lockedTokens.length.sub(1);
			}
			else {
				i = i.add(1);
			}
		}

        return true;
	}
}





 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
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

 
contract StagedCrowdsale is Ownable {

    using SafeMath for uint256;

     
    struct Stage {
        uint256 hardcap;
        uint256 price;
        uint256 minInvestment;
        uint256 invested;
        uint256 closed;
    }

    Stage[] public stages;


     
    function getCurrentStage() public view returns(uint256) {
        for(uint256 i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }


     
    function addStage(uint256 _hardcap, uint256 _price, uint256 _minInvestment, uint _invested) onlyOwner public {
        require(_hardcap > 0 && _price > 0);
        Stage memory stage = Stage(_hardcap.mul(1 ether), _price, _minInvestment.mul(1 ether).div(10), _invested.mul(1 ether), 0);
        stages.push(stage);
    }


     
    function closeStage(uint256 _stageNumber) onlyOwner public {
        require(stages[_stageNumber].closed == 0);
        if (_stageNumber != 0) require(stages[_stageNumber - 1].closed != 0);

        stages[_stageNumber].closed = now;
        stages[_stageNumber].invested = stages[_stageNumber].hardcap;

        if (_stageNumber + 1 <= stages.length - 1) {
            stages[_stageNumber + 1].invested = stages[_stageNumber].hardcap;
        }
    }


     
    function removeStages() onlyOwner public returns (bool) {
        require(stages.length > 0);

        stages.length = 0;

        return true;
    }
}

 
contract PULSCrowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	 
	address public multiSigWallet; 	 
	bool public hasEnded;
	bool public isPaused;	


	event TokenReservation(address purchaser, address indexed beneficiary, uint256 indexed sendEther, uint256 indexed pulsAmount);
	event ForwardingFunds(uint256 indexed value);


	 
	modifier notEnded() {
		require(!hasEnded);
		_;
	}


	 
	modifier notPaused() {
		require(!isPaused);
		_;
	}


	 
	function PULSCrowdsale() public {
		token = createTokenContract();

		multiSigWallet = 0x00955149d0f425179000e914F0DFC2eBD96d6f43;
		hasEnded = false;
		isPaused = false;

		addStage(3000, 1600, 1, 0);    
		addStage(3500, 1550, 1, 0);    
		addStage(4000, 1500, 1, 0);    
		addStage(4500, 1450, 1, 0);    
		addStage(42500, 1400, 1, 0);   
	}


	 
	function createTokenContract() internal returns (PULSToken) {
		return new PULSToken();
	}


	 
	function () external payable {
		buyTokens(msg.sender);
	}


	 
	function buyTokens(address _beneficiary) payable notEnded notPaused public {
		require(msg.value >= 0);
		
		uint256 stageIndex = getCurrentStage();
		Stage storage stageCurrent = stages[stageIndex];

		require(msg.value >= stageCurrent.minInvestment);

		uint256 tokens;

		 
		if (stageCurrent.invested.add(msg.value) >= stageCurrent.hardcap){
			stageCurrent.closed = now;

			if (stageIndex + 1 <= stages.length - 1) {
				Stage storage stageNext = stages[stageIndex + 1];

				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserveTokens(_beneficiary, tokens, msg.value, 0);

			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		emit TokenReservation(msg.sender, _beneficiary, msg.value, tokens);
		forwardFunds();
	}


	 
	function privatePresaleTokenReservation(address _beneficiary, uint256 _amount, uint256 _reserveTypeId) onlyOwner public {
		require (_reserveTypeId > 0);
		token.reserveTokens(_beneficiary, _amount, 0, _reserveTypeId);
		emit TokenReservation(msg.sender, _beneficiary, 0, _amount);
	}


	 
	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
		emit ForwardingFunds(msg.value);
	}


	  
	function finishCrowdsale() onlyOwner notEnded public returns (bool) {
		hasEnded = true;
		return true;
	}


	  
	function pauseCrowdsale() onlyOwner notEnded notPaused public returns (bool) {
		isPaused = true;
		return true;
	}


	  
	function unpauseCrowdsale() onlyOwner notEnded public returns (bool) {
		isPaused = false;
		return true;
	}


	  
	function changeMultiSigWallet(address _newMultiSigWallet) onlyOwner public returns (bool) {
		multiSigWallet = _newMultiSigWallet;
		return true;
	}
}