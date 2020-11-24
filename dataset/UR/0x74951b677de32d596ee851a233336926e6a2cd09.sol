 

pragma solidity ^0.4.18;


 
contract WeBetCrypto {
    string public name = "We Bet Crypto";
    string public symbol = "WBA";
	
    address public selfAddress;
    address public admin;
    address[] private users;
	
    uint8 public decimals = 7;
    uint256 public relativeDateSave;
    uint256 public totalFunds;
    uint256 public totalSupply = 400000000000000;
    uint256 public IOUSupply = 0;
    uint256 private amountInCirculation;
    uint256 private currentProfits;
    uint256 private currentIteration;
	uint256 private actualProfitSplit;
	
    bool public isFrozen;
    bool private running;
	
    mapping(address => uint256) balances;
    mapping(address => uint256) moneySpent;
    mapping(address => uint256) monthlyLimit;
	mapping(address => uint256) cooldown;
	
    mapping(address => bool) isAdded;
    mapping(address => bool) claimedBonus;
	mapping(address => bool) bannedUser;
     
	
    mapping (address => mapping (address => uint256)) allowed;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
	 
    modifier isAdmin() {
        require(msg.sender == admin);
         
        _;
    }
    
     
    modifier isRunning() {
        require(!running);
        running = true;
        _;
        running = false;
    }
    
	 
    modifier noFreeze() {
        require(!isFrozen);
        _;
    }
    
	 
    modifier userNotPlaying(address _user) {
         
        uint256 check = 0;
        check -= 1;
        require(cooldown[_user] == check);
        _;
    }
    
     
    modifier userNotBanned(address _user) {
        require(!bannedUser[_user]);
        _;
    }
    
     
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        assert((z = a - b) <= a);
    }
	
	 
    function WeBetCrypto() public {
        admin = msg.sender;
        selfAddress = this;
        balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] = 200000000000000;
        addUser(0x66AE070A8501E816CA95ac99c4E15C7e132fd289);
        Transfer(selfAddress, 0x66AE070A8501E816CA95ac99c4E15C7e132fd289, 200000000000000);
        balances[0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D] = 50000000000000;
        addUser(0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D);
        Transfer(selfAddress, 0xcf8d242C523bfaDC384Cc1eFF852Bf299396B22D, 50000000000000);
        relativeDateSave = now + 40 days;
        balances[selfAddress] = 150000000000000;
    }
    
     
    function name() external constant returns (string _name) {
        return name;
    }
    
	 
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }
    
     
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }
    
     
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
	
	 
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     
    function eligibleForDividence(address _user) public view returns (bool _success) {
        if (moneySpent[_user] == 0) {
            return false;
		} else if ((balances[_user] + allowed[selfAddress][_user])/moneySpent[_user] > 20) {
		    return false;
        }
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) external noFreeze {
        var _allowance = allowed[_from][_to];
        if (_from == selfAddress) {
            monthlyLimit[_to] = safeSub(monthlyLimit[_to], _value);
            require(cooldown[_to] < now  );
            IOUSupply -= _value;
        }
        balances[_to] = balances[_to]+_value;
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][_to] = safeSub(_allowance, _value);
        addUser(_to);
        Transfer(_from, _to, _value);
    }
    
     
    function approve(address _spender, uint256 _value) external {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    
     
    function transfer(address _to, uint256 _value) external isRunning noFreeze returns (bool success) {
        bytes memory empty;
        if (_to == selfAddress) {
            return transferToSelf(_value);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value);
        }
    }
    
     
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }
    
     
    function transfer(address _to, uint256 _value, bytes _data) external isRunning noFreeze returns (bool success){
        if (_to == selfAddress) {
            return transferToSelf(_value);
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value);
        }
    }
    
     
    function transferToAddress(address _to, uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        WeBetCrypto rec = WeBetCrypto(_to);
        rec.tokenFallback(msg.sender, _value, _data);
        addUser(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferToSelf(uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[selfAddress] = balances[selfAddress]+_value;
        Transfer(msg.sender, selfAddress, _value);
		allowed[selfAddress][msg.sender] = _value + allowed[selfAddress][msg.sender];
		IOUSupply += _value;
		Approval(selfAddress, msg.sender, allowed[selfAddress][msg.sender]);
        return true;
    }
	
	 
	function tokenFallback(address _sender, uint256 _value, bytes _data) public {}
	
	 
    function checkMonthlyLimit() external constant returns (uint256 remaining) {
        return monthlyLimit[msg.sender];
    }
	
	 
    function claimTokens(address _token) isAdmin external { 
		require(_token != selfAddress);
        WeBetCrypto token = WeBetCrypto(_token); 
        uint balance = token.balanceOf(selfAddress); 
        token.transfer(admin, balance); 
    }
    
	 
    function assetFreeze() internal {
        isFrozen = true;
    }
    
	 
    function assetThaw() internal {
        isFrozen = false;
    }
    
	 
    function emergencyFreeze() isAdmin external {
        isFrozen = true;
    }
    
	 
    function emergencyThaw() isAdmin external {
        isFrozen = false;
    }
	
	 
	function emergencySplitToggle() isAdmin external {
		uint temp = 0;
		temp -= 1;
		if (relativeDateSave == temp) {
		    relativeDateSave = now;
		} else {
	    	relativeDateSave = temp;
		}
	}
	
	 
	function addUser(address _user) internal {
		if (!isAdded[_user]) {
            users.push(_user);
            monthlyLimit[_user] = 1000000000000;
            isAdded[_user] = true;
        }
	}
    
	 
    function splitProfits() external {
        uint i;
        if (!isFrozen) {
            require(now >= relativeDateSave);
            assetFreeze();
            require(balances[selfAddress] > 30000000000000);
            relativeDateSave = now + 30 days;
            currentProfits = ((balances[selfAddress]-30000000000000)/10)*7; 
            amountInCirculation = safeSub(400000000000000, balances[selfAddress]) + IOUSupply;
            currentIteration = 0;
			actualProfitSplit = 0;
        } else {
            for (i = currentIteration; i < users.length; i++) {
                monthlyLimit[users[i]] = 1000000000000;
                if (msg.gas < 250000) {
                    currentIteration = i;
                    break;
                }
				if (!eligibleForDividence(users[i])) {
				    moneySpent[users[i]] = 0;
        			checkSplitEnd(i);
                    continue;
				}
				moneySpent[users[i]] = 0;
				actualProfitSplit += ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation;
                Transfer(selfAddress, users[i], ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation);
                balances[users[i]] += ((balances[users[i]]+allowed[selfAddress][users[i]])*currentProfits)/amountInCirculation;
				checkSplitEnd(i);
            }
        }
    }
	
	 
	function checkSplitEnd(uint256 i) internal {
		if (i == users.length-1) {
			assetThaw();
			balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] = balances[0x66AE070A8501E816CA95ac99c4E15C7e132fd289] + currentProfits/20;
			balances[selfAddress] = balances[selfAddress] - actualProfitSplit - currentProfits/20;
		}
	}
    
	 
    function alterBankBalance(address _toAlter, uint256 _amount) internal {
        if (_amount > allowed[selfAddress][_toAlter]) {
            IOUSupply += (_amount - allowed[selfAddress][_toAlter]);
            moneySpent[_toAlter] += (_amount - allowed[selfAddress][_toAlter]);
			allowed[selfAddress][_toAlter] = _amount;
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        } else {
            IOUSupply -= (allowed[selfAddress][_toAlter] - _amount);
            moneySpent[_toAlter] += (allowed[selfAddress][_toAlter] - _amount);
            allowed[selfAddress][_toAlter] = _amount;
			Approval(selfAddress, _toAlter, allowed[selfAddress][_toAlter]);
        }
    }
    
	 
    function platformLogin() userNotBanned(msg.sender) external {
         
        cooldown[msg.sender] = 0;
        cooldown[msg.sender] -= 1;
    }
	
	 
	function platformLogout(address _toLogout, uint256 _newBalance) external isAdmin {
		 
		cooldown[_toLogout] = now + 30 minutes;
		alterBankBalance(_toLogout,_newBalance);
	}
	
	 
	function checkLogin(address _toCheck) view external returns (bool) {
	    uint256 check = 0;
	    check -= 1;
	    return (cooldown[_toCheck] == check);
	}
	
	 
	function banUser(address _user) external isAdmin {
	    bannedUser[_user] = true;
	    cooldown[_user] = now + 30 minutes;
	}
	
	 
	function unbanUser(address _user) external isAdmin {
	    bannedUser[_user] = false;
	}
	
	 
	function checkBan(address _user) external view returns (bool) {
	    return bannedUser[_user];
	}
	
     
    function() payable external {
        totalFunds = totalFunds + msg.value;
		address etherTransfer = 0x66AE070A8501E816CA95ac99c4E15C7e132fd289;
        require(msg.value > 0);
		require(msg.sender != etherTransfer);
		require(totalFunds/1 ether < 2000);
        addUser(msg.sender);
        uint256 tokenAmount = msg.value/100000000;
		balances[selfAddress] = balances[selfAddress] - tokenAmount;
        balances[msg.sender] = balances[msg.sender] + tokenAmount;
        Transfer(selfAddress, msg.sender, tokenAmount);
        etherTransfer.transfer(msg.value);
    }
    
     
    function claimBonus() external {
        require(msg.sender.balance/(1000 finney) >= 1 && !claimedBonus[msg.sender]);
        claimedBonus[msg.sender] = true;
		allowed[selfAddress][msg.sender] = allowed[selfAddress][msg.sender] + 200000000;
		IOUSupply += 200000000;
        addUser(msg.sender);
		Approval(selfAddress, msg.sender, allowed[selfAddress][msg.sender]);
    }
}