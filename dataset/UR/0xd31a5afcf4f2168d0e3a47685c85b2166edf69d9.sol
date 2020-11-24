 

pragma solidity ^0.4.24;

 
 
 
 


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface ERC20Interface {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external;
    function balanceOf(address _owner) external view returns (uint256 _balance);
}

interface ERC20InterfaceClassic {
    function transfer(address to, uint tokens) external returns (bool success);
}

contract DailyRewards is Owned {

	event RewardClaimed(
		address indexed buyer,
		uint256 day
	);
	
	 
	mapping (address => uint) private daysInRow;

	 
	mapping (address => uint) private timeout;
	
	 
	uint waitingTime = 24 hours;
	 
	uint waitingTimeBuffer = 48 hours;
	
	
	constructor() public {
	     
	     
	     
	}
	
	
	function requestReward() public returns (uint _days) {
	    require (msg.sender != address(0));
	    require (now > timeout[msg.sender]);
	    
	     
	    if (now > timeout[msg.sender] + waitingTimeBuffer) {
	        daysInRow[msg.sender] = 1;    
	    } else {
	         
	        daysInRow[msg.sender]++;
	    }
	    
	    timeout[msg.sender] = now + waitingTime;
	    
	    emit RewardClaimed(msg.sender, daysInRow[msg.sender]);
	    
	    return daysInRow[msg.sender];
	}
	
	
	 
	function nextReward() public view returns (uint _day, uint _nextClaimTime, uint _nextClaimExpire) {
	    uint _dayCheck;
	    if (now > timeout[msg.sender] + waitingTimeBuffer) _dayCheck = 1; else _dayCheck = daysInRow[msg.sender] + 1;
	    
	    return (_dayCheck, timeout[msg.sender], timeout[msg.sender] + waitingTimeBuffer);
	}
	
	
	function queryWaitingTime() public view returns (uint _waitingTime) {
	    return waitingTime;
	}
	
	function queryWaitingTimeBuffer() public view returns (uint _waitingTimeBuffer) {
	    return waitingTimeBuffer;
	}
	

	 
	function setWaitingTime(uint newTime) public onlyOwner returns (uint _newWaitingTime) {
	    waitingTime = newTime;
	    return waitingTime;
	}
	
	
	 
	function setWaitingTimeBuffer(uint newTime) public onlyOwner returns (uint _newWaitingTimeBuffer) {
	    waitingTimeBuffer = newTime;
	    return waitingTimeBuffer;
	}


     
    function weiToOwner(address _address, uint _amountWei) public onlyOwner returns (bool) {
        require(_amountWei <= address(this).balance);
        _address.transfer(_amountWei);
        return true;
    }

    function ERC20ToOwner(address _to, uint256 _amount, ERC20Interface _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }

    function ERC20ClassicToOwner(address _to, uint256 _amount, ERC20InterfaceClassic _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }

}