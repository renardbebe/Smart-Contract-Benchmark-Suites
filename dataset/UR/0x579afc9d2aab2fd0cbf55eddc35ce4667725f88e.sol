 

pragma solidity ^0.4.19;

contract FrikandelToken {
    address public contractOwner = msg.sender;  

    bool public ICOEnabled = true;  
    bool public Killable = true;  

    mapping (address => uint256) balances;

    uint256 public totalSupply = 500000;  
    uint256 internal hardLimitICO = 750000;  

    function name() public pure returns (string) { return "Frikandel"; }  
    function symbol() public pure returns (string) { return "FRKNDL"; }
    function decimals() public pure returns (uint8) { return 0; }  

    function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

	function FrikandelToken() public {
	    balances[contractOwner] = totalSupply;  
	}
	
	function transferOwnership(address newOwner) public {
	    if (msg.sender != contractOwner) { revert(); }  

        contractOwner = newOwner;  
	}
	
	function Destroy() public {
	    if (msg.sender != contractOwner) { revert(); }  
	    
	    if (Killable == true){  
	        selfdestruct(contractOwner);
	    }
	}
	
	function DisableSuicide() public returns (bool success){
	    if (msg.sender != contractOwner) { revert(); }  
	    
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function enableICO() public {
        if (msg.sender != contractOwner) { revert(); }  
        ICOEnabled = true;
    }

    function disableICO() public {
        if (msg.sender != contractOwner) { revert(); }  
        ICOEnabled = false;
    }

    function() payable public {
        if (!ICOEnabled) { revert(); }
        if(balances[msg.sender]+(msg.value / 1e14) > 30000) { revert(); }  
        if(totalSupply+(msg.value / 1e14) > hardLimitICO) { revert(); }  
        if (msg.value == 0) { return; }

        contractOwner.transfer(msg.value);

        uint256 tokensIssued = (msg.value / 1e14);  

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;

        Transfer(address(this), msg.sender, tokensIssued);
    }
}