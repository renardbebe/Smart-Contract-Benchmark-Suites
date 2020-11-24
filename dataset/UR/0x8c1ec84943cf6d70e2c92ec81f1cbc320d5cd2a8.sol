 

pragma solidity 0.4.13;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract Token is owned {
    

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract StandardToken is Token {
    string messageString = "[ Welcome to the «ZENITH | Tokens Ttansfer Adaptation» Project 0xbt ]";

    function transfer(address _to, uint _value) returns (bool) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            
            return true;
        } else { return false; }
    }
    
     
    function transferAndData(address _to, uint _value, string _data) returns (bool) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnlimitedAllowanceToken is StandardToken {

    uint constant MAX_UINT = 2**256 - 1;
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract ZENITH is UnlimitedAllowanceToken {

    uint8 constant public decimals = 6;
    uint public totalSupply = 270000000000000;
    string constant public name = "ZENITH Protocol";
    string constant public symbol = "ZENITH";
    string messageString = "[ Welcome to the «ZENITH | Tokens Ttansfer Adaptation» Project 0xbt ]";
	event Approval(address indexed owner, address indexed spender, uint256 value);
  
     
	 
    function TransferTokenData(address _token, address[] addresses, uint amount, string _data) public {
    ZENITH token = ZENITH(_token);
    for(uint i = 0; i < addresses.length; i++) {
      require(token.transferFrom(msg.sender, addresses[i], amount));
    }
  }
     
    function SendEthData(address[] addresses, string _data) public payable {
    uint256 amount = msg.value / addresses.length;
    for(uint i = 0; i < addresses.length; i++) {
      addresses[i].transfer(amount);
    }
  }
    
    function getNews() public constant returns (string message) {
        return messageString;
    }
    
    function setNews(string lastNews) public {
        messageString = lastNews;
    }
    
    function ZENITH() {
        balances[msg.sender] = totalSupply;
    }
}