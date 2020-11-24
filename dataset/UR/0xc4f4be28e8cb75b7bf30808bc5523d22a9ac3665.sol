 

pragma solidity ^0.4.19;
contract ETHRoyale {
    address devAccount = 0x50334D202f61F80384C065BE6537DD3d609FF9Ab;  
    uint masterBalance;  
    uint masterApparentBalance;  
    
     
    address[] public participants;
    mapping (address => uint) participantsArrayLocation;
    uint participantsCount;
    
     
    bool isDisabled;
	bool hasStarted;
	
     
    uint blockHeightStart;
    bool isStart;
    event Deposit(uint _valu);
	
     
    mapping (address => uint) accountBalance;
    mapping (address => uint) realAccountBalance;
    mapping (address => uint) depositBlockheight;
    
     
    function checkAccBalance() public view returns (uint) {
        address _owner = msg.sender;
        return (accountBalance[_owner]);
    }
    
     
    function checkGlobalBalance() public view returns (uint) {
        return masterBalance;
    }
    
	 
	function checkGameStatus() public view returns (bool) {
        return (isStart);
    }
    function checkDisabledStatus() public view returns (bool) {
        return (isDisabled);
    }
	
     
    function checkInterest() public view returns (uint) {
        address _owner = msg.sender;
        uint _interest;
        if (isStart) {
            if (blockHeightStart > depositBlockheight[_owner]) {
		        _interest = ((accountBalance[_owner] * (block.number - blockHeightStart) / 2000));
		    } else {
		        _interest = ((accountBalance[_owner] * (block.number - depositBlockheight[_owner]) / 2000));
		    }
		return _interest;
        }else {
			return 0;
        }
    }
	
     
    function checkWithdrawalAmount() public view returns (uint) {
        address _owner = msg.sender;
        uint _interest;
		if (isStart) {
		    if (blockHeightStart > depositBlockheight[_owner]) {
		        _interest = ((accountBalance[_owner] * (block.number - blockHeightStart) / 2000));
		    } else {
		        _interest = ((accountBalance[_owner] * (block.number - depositBlockheight[_owner]) / 2000));
		    }
	    return (accountBalance[_owner] + _interest);
		} else {
			return accountBalance[_owner];
		}
    }
     
    function numberParticipants() public view returns (uint) {
        return participantsCount;
    }
    
     
    function deposit() payable public {
        address _owner = msg.sender;
        uint _amt = msg.value;         
        require (!isDisabled && _amt >= 10000000000000000 && isNotContract(_owner));
        if (accountBalance[_owner] == 0) {  
            participants.push(_owner);
            participantsArrayLocation[_owner] = participants.length - 1;
            depositBlockheight[_owner] = block.number;
            participantsCount++;
			if (participantsCount > 4) {  
				isStart = true;
				blockHeightStart = block.number;
				hasStarted = true;
			}
        }
        else {
            isStart = false;
            blockHeightStart = 0;
        }
		Deposit(_amt);
         
        accountBalance[_owner] += _amt;
        realAccountBalance[_owner] += _amt;
        masterBalance += _amt;
        masterApparentBalance += _amt;
    }
    
     
    function collectInterest(address _owner) internal {
        require (isStart);
        uint blockHeight; 
         
        if (depositBlockheight[_owner] < blockHeightStart) {
            blockHeight = blockHeightStart;
        }
        else {
            blockHeight = depositBlockheight[_owner];
        }
         
        uint _tempInterest = accountBalance[_owner] * (block.number - blockHeight) / 2000;
        accountBalance[_owner] += _tempInterest;
        masterApparentBalance += _tempInterest;
		 
		depositBlockheight[_owner] = block.number;
	}

     
    function withdraw(uint _amount) public  {
        address _owner = msg.sender; 
		uint _amt = _amount;
        uint _devFee;
        require (accountBalance[_owner] > 0 && _amt > 0 && isNotContract(_owner));
        if (isStart) {  
        collectInterest(msg.sender);
        }
		require (_amt <= accountBalance[_owner]);
        if (accountBalance[_owner] == _amount || accountBalance[_owner] - _amount < 10000000000000000) {  
			_amt = accountBalance[_owner];
			if (_amt > masterBalance) {  
				_amt = masterBalance;
			}	
            _devFee = _amt / 133;  
            _amt -= _devFee;
            masterApparentBalance -= _devFee;
            masterBalance -= _devFee;
            accountBalance[_owner] -= _devFee;
            masterBalance -= _amt;
            masterApparentBalance -= _amt;
             
            delete accountBalance[_owner];
            delete depositBlockheight[_owner];
            delete participants[participantsArrayLocation[_owner]];
			delete participantsArrayLocation[_owner];
            delete realAccountBalance[_owner];
            participantsCount--;
            if (participantsCount < 5) {  
                isStart = false;
				if (participantsCount < 3 && hasStarted) {  
					isDisabled = true;
				}
				if (participantsCount == 0) {  
					isDisabled = false;
					hasStarted = false;
				}	
            }
        }
        else if (accountBalance[_owner] > _amount){  
			if (_amt > masterBalance) {
				_amt = masterBalance;
			}	
            _devFee = _amt / 133;  
            _amt -= _devFee;
            masterApparentBalance -= _devFee;
            masterBalance -= _devFee;
            accountBalance[_owner] -= _devFee;
            accountBalance[_owner] -= _amt;
            realAccountBalance[_owner] -= _amt;
            masterBalance -= _amt;
            masterApparentBalance -= _amt;
        }
		Deposit(_amt);
        devAccount.transfer(_devFee);
        _owner.transfer(_amt);
    }
	
	 
	function isNotContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return (!(size > 0));
	}
}