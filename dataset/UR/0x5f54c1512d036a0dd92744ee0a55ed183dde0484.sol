 

pragma solidity ^0.4.16;
 

contract owned  {
  address owner;
  function owned() {
    owner = msg.sender;
  }
  function changeOwner(address newOwner) onlyOwner {
    owner = newOwner;
  }
  modifier onlyOwner() {
    if (msg.sender==owner) 
    _;
  }
}

contract mortal is owned() {
  function kill() onlyOwner {
    if (msg.sender == owner) selfdestruct(owner);
  }
}

library ERC20Lib {
 
  struct TokenStorage {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 totalSupply;
  }
  
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	modifier onlyPayloadSize(uint numwords) {
		 
        assert(msg.data.length >= numwords * 32 + 4);
        _;
	}
  
	modifier validAddress(address _address) { 
		 		
        require(_address != 0x0); 
        require(_address != address(msg.sender)); 
        _; 
    } 
	
	modifier IsWallet(address _address) {
		 		
		uint codeLength;
		assembly {
             
            codeLength := extcodesize(_address)
        }
		assert(codeLength==0);		
        _; 
    } 

   function safeMul(uint a, uint b) returns (uint) { 
     uint c = a * b; 
     assert(a == 0 || c / a == b); 
     return c; 
   } 
 
   function safeSub(uint a, uint b) returns (uint) { 
     assert(b <= a); 
     return a - b; 
   }  
 
   function safeAdd(uint a, uint b) returns (uint) { 
     uint c = a + b; 
     assert(c>=a && c>=b); 
     return c; 
   } 
	
	function init(TokenStorage storage self, uint _initial_supply) {
		self.totalSupply = _initial_supply;
		self.balances[msg.sender] = _initial_supply;
	}
  
	function transfer(TokenStorage storage self, address _to, uint256 _value) 
		onlyPayloadSize(3)
		IsWallet(_to)		
		returns (bool success) {				
		 
       if (self.balances[msg.sender] >= _value && self.balances[_to] + _value > self.balances[_to]) {
            self.balances[msg.sender] = safeSub(self.balances[msg.sender], _value);
            self.balances[_to] = safeAdd(self.balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
  
	function transferFrom(TokenStorage storage self, address _from, address _to, uint256 _value) 
		onlyPayloadSize(4) 
		validAddress(_from)
		validAddress(_to)
		returns (bool success) {
		 
        if (self.balances[_from] >= _value && self.allowed[_from][msg.sender] >= _value && self.balances[_to] + _value > self.balances[_to]) {
			var _allowance = self.allowed[_from][msg.sender];
            self.balances[_to] = safeAdd(self.balances[_to], _value);
            self.balances[_from] = safeSub(self.balances[_from], _value);
            self.allowed[_from][msg.sender] = safeSub(_allowance, _value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
     
    function balanceOf(TokenStorage storage self, address _owner) constant 
		onlyPayloadSize(2) 
		validAddress(_owner)
		returns (uint256 balance) {
		 
        return self.balances[_owner];
    }
	 
    function approve(TokenStorage storage self, address _spender, uint256 _value) 
		onlyPayloadSize(3) 
		validAddress(_spender)	
		returns (bool success) {
	 
		 
		if ((_value != 0) && (self.allowed[msg.sender][_spender] != 0)) { 
           return false; 
        } else {
			self.allowed[msg.sender][_spender] = _value;
			Approval(msg.sender, _spender, _value);
			return true;
		}
    }
		
	function allowance(TokenStorage storage self, address _owner, address _spender) constant 
		onlyPayloadSize(3) 
		validAddress(_owner)	
		validAddress(_spender)	
		returns (uint256 remaining) {
			 
        return self.allowed[_owner][_spender];
    }
	
	function increaseApproval(TokenStorage storage self, address _spender, uint256 _addedValue)  
		onlyPayloadSize(3) 
		validAddress(_spender)	
		returns (bool success) { 
		 
        uint256 oldValue = self.allowed[msg.sender][_spender]; 
        self.allowed[msg.sender][_spender] = safeAdd(oldValue, _addedValue); 
        return true; 
    } 
	
	function decreaseApproval(TokenStorage storage self,address _spender, uint256 _subtractedValue)  
		onlyPayloadSize(3) 
		validAddress(_spender)	
		returns (bool success) { 
		 
		uint256 oldValue = self.allowed[msg.sender][_spender]; 
		if (_subtractedValue > oldValue) { 
			self.allowed[msg.sender][_spender] = 0; 
		} else { 
			self.allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue); 
		} 
		return true; 
	} 

     
    function approveAndCall(TokenStorage storage self, address _spender, uint256 _value, bytes _extraData)
		onlyPayloadSize(4) 
		validAddress(_spender)   
		returns (bool success) {
	 
			 
		if ((_value != 0) && (self.allowed[msg.sender][_spender] != 0)) { 
				return false; 
			} else {
			self.allowed[msg.sender][_spender] = _value;
			Approval(msg.sender, _spender, _value);
			 
			 
			 
			if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
			return true;
		}
    }	
	
	function mintCoin(TokenStorage storage self, address target, uint256 mintedAmount, address owner) 
		internal
		returns (bool success) {
			 
        self.balances[target] = safeAdd(self.balances[target], mintedAmount); 
        self.totalSupply = safeAdd(self.totalSupply, mintedAmount); 
        Transfer(0, owner, mintedAmount);  
        Transfer(owner, target, mintedAmount);  
		return true;
    }

    function meltCoin(TokenStorage storage self, address target, uint256 meltedAmount, address owner) 
		internal
		returns (bool success) {
			 
        if(self.balances[target]<meltedAmount){
            return false;
        }
		self.balances[target] = safeSub(self.balances[target], meltedAmount);  
		self.totalSupply = safeSub(self.totalSupply, meltedAmount);  
		Transfer(target, owner, meltedAmount);  
		Transfer(owner, 0, meltedAmount);  
		return true;
    }
}

 
contract StandardToken is owned{
    using ERC20Lib for ERC20Lib.TokenStorage;
    ERC20Lib.TokenStorage public token;

	string public name;                    
    uint8 public decimals=18;                 
    string public symbol;                  
    string public version = 'H0.1';        
    uint public INITIAL_SUPPLY = 0;		 

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);   
   
    function StandardToken() {
		token.init(INITIAL_SUPPLY);
    }

    function totalSupply() constant returns (uint) {
		return token.totalSupply;
    }

    function balanceOf(address who) constant returns (uint) {
		return token.balanceOf(who);
    }

    function allowance(address owner, address _spender) constant returns (uint) {
		return token.allowance(owner, _spender);
    }

	function transfer(address to, uint value) returns (bool ok) {
		return token.transfer(to, value);
	}

	function transferFrom(address _from, address _to, uint _value) returns (bool ok) {
		return token.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint value) returns (bool ok) {
		return token.approve(_spender, value);
	}
   
	function increaseApproval(address _spender, uint256 _addedValue) returns (bool ok) {  
		return token.increaseApproval(_spender, _addedValue);
	}    
 
	function decreaseApproval(address _spender, uint256 _subtractedValue) returns (bool ok) {  
		return token.decreaseApproval(_spender, _subtractedValue);
	}

	function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool ok){
		return token.approveAndCall(_spender,_value,_extraData);
    }
	
	function mintCoin(address target, uint256 mintedAmount) onlyOwner returns (bool ok) {
		return token.mintCoin(target,mintedAmount,owner);
    }

    function meltCoin(address target, uint256 meltedAmount) onlyOwner returns (bool ok) {
		return token.meltCoin(target,meltedAmount,owner);
    }
}

 
contract Coin is StandardToken, mortal{
    I_minter public mint;				   
    event EventClear();

    function Coin(string _tokenName, string _tokenSymbol, address _minter) { 
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        changeOwner(_minter);
        mint=I_minter(_minter); 
	}
}

 
contract RiskCoin is Coin{
    function RiskCoin(string _tokenName, string _tokenSymbol, address _minter) 
	Coin(_tokenName,_tokenSymbol,_minter) {} 
	
    function() payable {
		 
        mint.NewRiskAdr.value(msg.value)(msg.sender);
    }  
}

 
contract StatiCoin is Coin{
    function StatiCoin(string _tokenName, string _tokenSymbol, address _minter) 
	Coin(_tokenName,_tokenSymbol,_minter) {} 

    function() payable {        
		 
        mint.NewStaticAdr.value(msg.value)(msg.sender);
    }  
}

 
contract I_coin is mortal {

    event EventClear();

	I_minter public mint;
    string public name;                    
    uint8 public decimals=18;                 
    string public symbol;                  
    string public version = '';        
	
    function mintCoin(address target, uint256 mintedAmount) returns (bool success) {}
    function meltCoin(address target, uint256 meltedAmount) returns (bool success) {}
    function approveAndCall(address _spender, uint256 _value, bytes _extraData){}

    function setMinter(address _minter) {}   
	function increaseApproval (address _spender, uint256 _addedValue) returns (bool success) {}    
	function decreaseApproval (address _spender, uint256 _subtractedValue) 	returns (bool success) {} 

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}    


     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}


     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

	 
    uint256 public totalSupply;
}

 
contract I_minter { 
    event EventCreateStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemStatic(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventCreateRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventRedeemRisk(address indexed _from, uint128 _value, uint _transactionID, uint _Price); 
    event EventBankrupt();
	
    function Leverage() constant returns (uint128)  {}
    function RiskPrice(uint128 _currentPrice,uint128 _StaticTotal,uint128 _RiskTotal, uint128 _ETHTotal) constant returns (uint128 price)  {}
    function RiskPrice(uint128 _currentPrice) constant returns (uint128 price)  {}     
    function PriceReturn(uint _TransID,uint128 _Price) {}
    function NewStatic() external payable returns (uint _TransID)  {}
    function NewStaticAdr(address _Risk) external payable returns (uint _TransID)  {}
    function NewRisk() external payable returns (uint _TransID)  {}
    function NewRiskAdr(address _Risk) external payable returns (uint _TransID)  {}
    function RetRisk(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function RetStatic(uint128 _Quantity) external payable returns (uint _TransID)  {}
    function Strike() constant returns (uint128)  {}
}