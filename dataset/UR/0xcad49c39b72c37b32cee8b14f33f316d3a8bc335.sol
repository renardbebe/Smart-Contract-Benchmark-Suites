 

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
    function checkRate() public constant returns (uint rate_);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Blacklisted(address indexed target);
	event DeleteFromBlacklist(address indexed target);
	event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint value);
	event RejectedPaymentFromLockedAddr(address indexed from, address indexed to, uint value, uint lackdatetime, uint now_);
	event RejectedPaymentMaximunFromLockedAddr(address indexed from, address indexed to, uint value);
	event test1(uint rate, uint a, uint now );
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


 
 
 
 
contract SodaCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public start;
    address founderAddr = 0x625f7Ae05DC8c22dA56F47CaDc8c647137a6B4D9;
    address advisorAddr = 0x45F6a7D7903D3A02bef15826eBCA44aB5eD11758;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => int8) public blacklist;
    UnlockDateModel[] public unlockdate;

    struct UnlockDateModel {
		 
		uint256 datetime;
		uint rate;
	}
    
     
     
     
    constructor() public {
        symbol = "SOC";
        name = "SODA Coin";
        decimals = 18;
        _totalSupply = 2000000000000000000000000000;
        balances[msg.sender] = 1400000000000000000000000000;
        emit Transfer(address(0), 0x1E7A12b193D18027E33cd3Ff0eef2Af31cbBF9ef, 1400000000000000000000000000);  
         
         
        balances[founderAddr] = 300000000000000000000000000;
        emit Transfer(address(0), founderAddr, 300000000000000000000000000); 
         
         
        balances[advisorAddr] = 300000000000000000000000000;
        emit Transfer(address(0), advisorAddr, 300000000000000000000000000);
        
        start = now;
        unlockdate.push(UnlockDateModel({datetime : 1610237400,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1612915800,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1615335000,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1618013400,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1620605400,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1623283800,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1625875800,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1628554200,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1631232600,rate : 10}));
        unlockdate.push(UnlockDateModel({datetime : 1633824600,rate : 10}));
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

    function checkRate() public constant returns (uint rate_){
        uint rate = 0;
        for (uint i = 0; i<unlockdate.length; i++) {
            if (unlockdate[i].datetime < now) {
                rate = rate + unlockdate[i].rate; 
            }
        }
        return rate;
    }
    
     
     
     
     
     
  
    function transfer(address to, uint tokens) public returns (bool success) {
        if (msg.sender == founderAddr || msg.sender == advisorAddr){
            if (unlockdate[0].datetime > now) {
                emit RejectedPaymentFromLockedAddr(msg.sender, to, tokens, unlockdate[0].datetime, now);
			    return false;
            } else {
                uint rate = checkRate();
                
                uint maximum = 300000000000000000000000000 - (300000000000000000000000000 * 0.01) * rate;
                if (maximum > (balances[msg.sender] - tokens)){
                    emit RejectedPaymentMaximunFromLockedAddr(msg.sender, to, tokens);
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