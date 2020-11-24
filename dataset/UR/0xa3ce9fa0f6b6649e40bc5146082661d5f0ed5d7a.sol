 

pragma solidity ^0.4.2;
 
contract Owned {
     
    address public owner;

     
    function Owned() { owner = msg.sender; }

     
    function delegate(address _owner) onlyOwner
    { owner = _owner; }

     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }
}
 
contract Mortal is Owned {
     
    function kill() onlyOwner
    { suicide(owner); }
}
 
contract Token is Mortal {
    event Transfer(address indexed _from,  address indexed _to,      uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    string public name;
    string public symbol;

     
    uint public totalSupply;

     
    uint8 public decimals;
    
     
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
 
     
    function getBalance() constant returns (uint)
    { return balanceOf[msg.sender]; }
 
     
    function getBalance(address _address) constant returns (uint) {
        return allowance[_address][msg.sender]
             > balanceOf[_address] ? balanceOf[_address]
                                   : allowance[_address][msg.sender];
    }
 
     
    function Token(string _name, string _symbol, uint8 _decimals, uint _count) {
        name     = _name;
        symbol   = _symbol;
        decimals = _decimals;
        totalSupply           = _count;
        balanceOf[msg.sender] = _count;
    }
 
     
    function transfer(address _to, uint _value) returns (bool) {
        if (balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to]        += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

     
    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        var avail = allowance[_from][msg.sender]
                  > balanceOf[_from] ? balanceOf[_from]
                                     : allowance[_from][msg.sender];
        if (avail >= _value) {
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from] -= _value;
            balanceOf[_to]   += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

     
    function approve(address _address, uint _value) {
        allowance[msg.sender][_address] += _value;
        Approval(msg.sender, _address, _value);
    }

     
    function unapprove(address _address)
    { allowance[msg.sender][_address] = 0; }
}
 
contract TokenEther is Token {
    function TokenEther(string _name, string _symbol)
             Token(_name, _symbol, 18, 0)
    {}

     
    function withdraw(uint _value) {
        if (balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] -= _value;
            totalSupply           -= _value;
            if(!msg.sender.send(_value)) throw;
        }
    }

     
    function refill() payable returns (bool) {
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
        return true;
    }

     
    function () payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
    }
    
     
    function kill() onlyOwner { throw; }
}


 
 
 
 

contract Registrar {
	event Changed(string indexed name);

	function owner(string _name) constant returns (address o_owner);
	function addr(string _name) constant returns (address o_address);
	function subRegistrar(string _name) constant returns (address o_subRegistrar);
	function content(string _name) constant returns (bytes32 o_content);
}

 
 
 
 

contract AiraRegistrarService is Registrar, Mortal {
	struct Record {
		address addr;
		address subRegistrar;
		bytes32 content;
	}
	
    function owner(string _name) constant returns (address o_owner)
    { return 0; }

	function disown(string _name) onlyOwner {
		delete m_toRecord[_name];
		Changed(_name);
	}

	function setAddr(string _name, address _a) onlyOwner {
		m_toRecord[_name].addr = _a;
		Changed(_name);
	}
	function setSubRegistrar(string _name, address _registrar) onlyOwner {
		m_toRecord[_name].subRegistrar = _registrar;
		Changed(_name);
	}
	function setContent(string _name, bytes32 _content) onlyOwner {
		m_toRecord[_name].content = _content;
		Changed(_name);
	}
	function record(string _name) constant returns (address o_addr, address o_subRegistrar, bytes32 o_content) {
		o_addr = m_toRecord[_name].addr;
		o_subRegistrar = m_toRecord[_name].subRegistrar;
		o_content = m_toRecord[_name].content;
	}
	function addr(string _name) constant returns (address) { return m_toRecord[_name].addr; }
	function subRegistrar(string _name) constant returns (address) { return m_toRecord[_name].subRegistrar; }
	function content(string _name) constant returns (bytes32) { return m_toRecord[_name].content; }

	mapping (string => Record) m_toRecord;
}

contract AiraEtherFunds is TokenEther {
    function AiraEtherFunds(address _bot_reg, string _name, string _symbol)
            TokenEther(_name, _symbol) {
        reg = AiraRegistrarService(_bot_reg);
    }

     
    event ActivationRequest(address indexed sender, bytes32 indexed code);

     
    uint public limit;
    
    function setLimit(uint _limit) onlyOwner
    { limit = _limit; }

     
    uint public fee;
    
    function setFee(uint _fee) onlyOwner
    { fee = _fee; }

     
    function activate(string _code) payable {
        var value = msg.value;
 
         
        if (fee > 0) {
            if (value < fee) throw;
            balanceOf[owner] += fee;
            value            -= fee;
        }

         
        if (limit > 0 && value > limit) {
            var refund = value - limit;
            if (!msg.sender.send(refund)) throw;
            value = limit;
        }

         
        balanceOf[msg.sender] += value;
        totalSupply           += value;

         
        ActivationRequest(msg.sender, stringToBytes32(_code));
    }

     
    function stringToBytes32(string memory source) constant returns (bytes32 result)
    { assembly { result := mload(add(source, 32)) } }

     
    function refill() payable returns (bool) {
         
        if (balanceOf[msg.sender] + msg.value > limit) throw;

         
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
        return true;
    }

     
    function refill(address _dest) payable returns (bool) {
         
        if (balanceOf[_dest] + msg.value > limit) throw;

         
        balanceOf[_dest] += msg.value;
        totalSupply      += msg.value;
        return true;
    }

     
    function () payable {
         
        if (balanceOf[msg.sender] + msg.value > limit) throw;

         
        balanceOf[msg.sender] += msg.value;
        totalSupply           += msg.value;
    }

     
    function sendFrom(address _from, address _to, uint _value) {
        var avail = allowance[_from][msg.sender]
                  > balanceOf[_from] ? balanceOf[_from]
                                     : allowance[_from][msg.sender];
        if (avail >= _value) {
            allowance[_from][msg.sender] -= _value;
            balanceOf[_from]             -= _value;
            totalSupply                  -= _value;
            if (!_to.send(_value)) throw;
        }
    }

    AiraRegistrarService public reg;
    modifier onlySecure { if (msg.sender != reg.addr("AiraSecure")) throw; _; }

     
    function secureApprove(address _client, uint _value) onlySecure {
        var ethBot = reg.addr("AiraEth");
        if (ethBot != 0)
            allowance[_client][ethBot] += _value;
    }

     
    function secureUnapprove(address _client) onlySecure {
        var ethBot = reg.addr("AiraEth");
        if (ethBot != 0)
            allowance[_client][ethBot] = 0;
    }
}