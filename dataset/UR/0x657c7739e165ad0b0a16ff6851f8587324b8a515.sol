 

 
pragma solidity ^0.4.11;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}



 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



 
contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract HonestisNetworkTokenWire3{

    string public name = "Honestis.Network Token Version 1";
    string public symbol = "HNT";
    uint8 public constant decimals = 18;   
     
 
	
     
    address public honestisFort = 0xF03e8E4cbb2865fCc5a02B61cFCCf86E9aE021b5;
     
    address public migrationMaster = 0x0f32f4b37684be8a1ce1b2ed765d2d893fa1b419;
     
	 
   
 
 
uint256 public constant supply = 3300000.0 ether;
		 
	 
	 
	address public firstChainHNw1 = 0x0;
	address public secondChainHNw2 = 0x0;
	address public thirdChainETH = 0x0;
	address public fourthChainETC = 0x0;
				
	struct sendTokenAway{
		StandardToken coinContract;
		uint amount;
		address recipient;
	}
	mapping(uint => sendTokenAway) transfers;
	uint numTransfers=0;
	
  mapping (address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

	event UpdatedTokenInformation(string newName, string newSymbol);	
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function HonestisNetworkTokenWire3() {
 
 
 
 
 
 
 
 balances[0x8585d5a25b1fa2a0e6c3bcfc098195bac9789be2]=3300000000000000000000000;
}

  
  function transfer(address _to, uint256 _value) returns (bool success) {
     
     
     
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
     
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


	function() payable {

   }


function justSendDonations() external {
    if (msg.sender != honestisFort) throw;
	if (!honestisFort.send(this.balance)) throw;
}
	
  function setTokenInformation(string _name, string _symbol) {
    
	   if (msg.sender != honestisFort) {
      throw;
    }
	name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

function setChainsAddresses(address chainAd, int chainnumber) {
    
	   if (msg.sender != honestisFort) {
      throw;
    }
	if(chainnumber==1){firstChainHNw1=chainAd;}
	if(chainnumber==2){secondChainHNw2=chainAd;}
	if(chainnumber==3){thirdChainETH=chainAd;}
	if(chainnumber==4){fourthChainETC=chainAd;}		
  } 

  function HonestisnetworkICOregulations() external returns(string wow) {
	return 'Regulations of preICO and ICO are present at website  honestis.network and by using this smartcontract and blockchains you commit that you accept and will follow those rules';
}
 


	function sendTokenAw(address StandardTokenAddress, address receiver, uint amount){
		if (msg.sender != honestisFort) {
		throw;
		}
		sendTokenAway t = transfers[numTransfers];
		t.coinContract = StandardToken(StandardTokenAddress);
		t.amount = amount;
		t.recipient = receiver;
		t.coinContract.transfer(receiver, amount);
		numTransfers++;
	}




}


 