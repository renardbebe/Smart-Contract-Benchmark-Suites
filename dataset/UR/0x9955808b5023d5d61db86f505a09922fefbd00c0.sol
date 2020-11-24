 

pragma solidity ^0.4.8;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface Token { 
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

interface EOSToken {
  function balanceOf(address who) constant public returns (uint value);
}

contract EOSDRAM is ERC20Interface {
    string public constant symbol = "DRAM";
    string public constant name = "EOS DRAM";
    uint8 public constant decimals = 18;

    address EOSContract = 0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0;

     
     
     
     
     
    

    uint256 _totalSupply = 67108864e18;
    
     
     
     
   
   uint256 _airdropAmount = 182e18;
    

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;

     
    mapping(address => mapping (address => uint256)) allowed;

    address public owner;
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

    function EOSDRAM() public {
        owner = msg.sender;
        initialized[msg.sender] = true;
         
        balances[msg.sender] = 6923830e18;
        Transfer(0, owner, 6923830e18);
      }

    function totalSupply() public constant returns (uint256 supply) {
        return _totalSupply;
    }

     
    function balance() public constant returns (uint256) {
        return getBalance(msg.sender);
    }

     
    function balanceOf(address _address) public constant returns (uint256) {
        return getBalance(_address);
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        initialize(msg.sender);

        if (balances[msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(msg.sender, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        initialize(_from);

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(_from, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function initialize(address _address) internal returns (bool success) {
        
        if (!initialized[_address]) {
       
        
       EOSToken token = EOSToken(EOSContract);
       uint256 has_eos = token.balanceOf(_address);
       if (has_eos > 0) {
       	     
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            }
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (!initialized[_address]) {
            EOSToken token = EOSToken(EOSContract);
	    uint256 has_eos = token.balanceOf(_address);
      	   
      	   if (has_eos > 0) {
            return balances[_address] + _airdropAmount;
            }
            else {
            return balances[_address];
            }
        }
        else {
            return balances[_address];
        }
    }
}