 

pragma solidity ^0.4.19;

contract Frikandel {
    address creator = msg.sender;  

    bool public Enabled = true;  
    bool internal Killable = true;  

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply = 500000;  
    uint256 public hardLimitICO = 750000;  

    function name() public pure returns (string) { return "Frikandel"; }  
    function symbol() public pure returns (string) { return "FRKNDL"; }
    function decimals() public pure returns (uint8) { return 0; }  

    function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

	function Frikandel() public {
	    balances[creator] = totalSupply;  
	}
	
	function Destroy() public {
	    if (msg.sender != creator) { revert(); }  
	    
	    if ((balances[creator] > 25000) && Killable == true){  
	        selfdestruct(creator);
	    }
	}
	
	function DisableSuicide() public returns (bool success){
	    if (msg.sender != creator) { revert(); }  
	    
	    Killable = false;
	    return true;
	}

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(msg.data.length < (2 * 32) + 4) { revert(); }  

        if (_value == 0) { return false; }  

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];

        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;  
        } else { return false; }  
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(msg.data.length < (3 * 32) + 4) { revert(); }  

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) internal returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enable() public {
        if (msg.sender != creator) { revert(); }  
        Enabled = true;
    }

    function disable() public {
        if (msg.sender != creator) { revert(); }  
        Enabled = false;
    }

    function() payable public {
        if (!Enabled) { revert(); }
        if(balances[msg.sender]+(msg.value / 1e14) > 30000) { revert(); }  
        if(totalSupply+(msg.value / 1e14) > hardLimitICO) { revert(); }  
        if (msg.value == 0) { return; }

        creator.transfer(msg.value);

        uint256 tokensIssued = (msg.value / 1e14);  

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;

        Transfer(address(this), msg.sender, tokensIssued);
    }
}