 

pragma solidity ^0.4.24;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function checkRate(uint unlockIndex) public constant returns (uint rate_);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Blacklisted(address indexed target);
    
	event DeleteFromBlacklist(address indexed target);
	event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentToLockedAddr(address indexed from, address indexed to, uint value, uint lackdatetime, uint now_);
	event RejectedPaymentFromLockedAddr(address indexed from, address indexed to, uint value, uint lackdatetime, uint now_);
	event RejectedPaymentMaximunFromLockedAddr(address indexed from, address indexed to, uint value, uint maximum, uint rate);
}


 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
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

 
 
 
 
contract GNB is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startTime;

    address addr_1	= 0x9223C73D91D32427ff4A180931Dd9623B40889df;  
    address addr_2	= 0x594d7b3C4691EEa823f4153b458D7115560058ca;  
	address addr_3	= 0x30fe67d39527E6722f3383Be7553E7c07C7B7C59;  
	address addr_4	= 0x44d33cFac0626391308c72Af66B96848516497a2;  
	address addr_5	= 0xE1cf664584CC7632Db07482f158CEC264c72b1De;  

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => int8) public blacklist;
    UnlockDateModel[] public unlockdate_T1;
    UnlockDateModel[] public unlockdate_T2;

    struct UnlockDateModel {
		uint256 datetime;
		uint rate;
	}
	
     
     
     
    constructor() public {
        symbol = "GNB";
        name = "Game Network Blockchain";
        decimals = 18;
        _totalSupply = 2000000000000000000000000000;
        
        balances[addr_1] = 600000000000000000000000000;  
        emit Transfer(address(0), addr_1, balances[addr_1]); 
        balances[addr_2] = 600000000000000000000000000;  
        emit Transfer(address(0), addr_2, balances[addr_2]); 
        balances[addr_3] = 400000000000000000000000000;  
        emit Transfer(address(0), addr_3, balances[addr_3]); 
        balances[addr_4] = 100000000000000000000000000;  
        emit Transfer(address(0), addr_4, balances[addr_4]); 
        balances[addr_5] = 300000000000000000000000000;  
        emit Transfer(address(0), addr_5, balances[addr_5]); 
        
        startTime = now;
        
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 365 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 395 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 425 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 455 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 485 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 515 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 545 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 575 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 605 days, rate : 100}));
        unlockdate_T1.push(UnlockDateModel({datetime : startTime + 635 days, rate : 100}));
        
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 180 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 210 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 240 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 270 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 300 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 330 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 360 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 390 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 420 days, rate : 100}));
        unlockdate_T2.push(UnlockDateModel({datetime : startTime + 450 days, rate : 100}));
        
    }
    
    function now_() public constant returns (uint){
        return now;
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function checkRate(uint unlockIndex) public constant returns (uint rate_ ){
        uint rate = 0;
        if (unlockIndex == 1){
            for (uint i = 0; i<unlockdate_T1.length; i++) {
                if (unlockdate_T1[i].datetime < now) {
                    rate = rate + unlockdate_T1[i].rate; 
                }
            }
        } else if (unlockIndex == 2){
            for (uint s = 0; s<unlockdate_T2.length; s++) {
                if (unlockdate_T2[s].datetime < now) {
                    rate = rate + unlockdate_T2[s].rate; 
                }
            }
        }
        return rate;
    }
     
     
     
     
     
  
    function transfer(address to, uint tokens) public returns (bool success) {

        if (msg.sender == addr_1){  
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T1[0].datetime, now);
			    return false;
            } else {
                uint rate1 = checkRate(1);
                uint maximum1 = 600000000000000000000000000 - (600000000000000000000000000 * 0.001) * rate1;
                if (maximum1 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum1, rate1);
			        return false;
                }
            }
        } else if (msg.sender == addr_2){  
            if (unlockdate_T1[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate_T1[0].datetime, now);
			    return false;
            } else {
                uint rate2 = checkRate(1);
                uint maximum2 = 600000000000000000000000000 - (600000000000000000000000000 * 0.001) * rate2;
                if (maximum2 > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens, maximum2, rate2);
			        return false;
                }
            }
        }
        
        if (blacklist[msg.sender] > 0) {  
			emit RejectedPaymentFromBlacklistedAddr(msg.sender, to, tokens);
			return false;
		} else if (blacklist[to] > 0) {  
			emit RejectedPaymentToBlacklistedAddr(msg.sender, to, tokens);
			return false;
		} else {
			balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
		}
		
    }

     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
     
     
	function totalSupplyIncrease(uint256 _supply) public onlyOwner{
		_totalSupply = _totalSupply + _supply;
		balances[msg.sender] = balances[msg.sender] + _supply;
	}
	
	 
     
     
	function blacklisting(address _addr) public onlyOwner{
		blacklist[_addr] = 1;
		emit Blacklisted(_addr);
	}
	
	
	 
     
     
	function deleteFromBlacklist(address _addr) public onlyOwner{
		blacklist[_addr] = -1;
		emit DeleteFromBlacklist(_addr);
	}
	
}