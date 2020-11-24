 

pragma solidity ^0.4.19;

contract FrikandelToken {
    address public contractOwner = msg.sender;  

    bool public ICOEnabled = true;  
    bool public Killable = true;  

    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

    uint256 internal airdropLimit = 450000;  
    uint256 public airdropSpent = 0;  
    
     
    uint256 public totalSupply = 500000;  
    uint256 internal hardLimitICO = 750000;  

    function name() public pure returns (string) { return "Frikandel"; }  
    function symbol() public pure returns (string) { return "FRIKANDEL"; }  
    function decimals() public pure returns (uint8) { return 0; }  

    function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

	function FrikandelToken() public {
	    balances[contractOwner] = 50000;  
	    Transfer(0x0, contractOwner, 50000);  
	}
	
	function transferOwnership(address _newOwner) public {
	    require(msg.sender == contractOwner);  

        contractOwner = _newOwner;  
	}
	
	function Destroy() public {
	    require(msg.sender == contractOwner);  
	    
	    if (Killable == true){  
	        selfdestruct(contractOwner);
	    }
	}
	
	function disableSuicide() public returns (bool success){
	    require(msg.sender == contractOwner);  
	    
	    Killable = false;  
	    return true;
	}
	
    function Airdrop(address[] _recipients) public {
        require(msg.sender == contractOwner);  
        if((_recipients.length + airdropSpent) > airdropLimit) { revert(); }  
        for (uint256 i = 0; i < _recipients.length; i++) {
            balances[_recipients[i]] += 1;  
        }
        airdropSpent += _recipients.length;  
    }
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {  
         
        if (_value == 0) { Transfer(msg.sender, _to, 0); return; }  

         
         
        if (allowed[_from][msg.sender] >= _value && balances[_from] >= _value) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            allowed[_from][msg.sender] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }  
    }
	
	function approve(address _spender, uint256 _value) public returns (bool success) {  
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }  
        
        allowed[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        if (allowed[msg.sender][_spender] >= allowed[msg.sender][_spender] + _addedValue) { revert(); }  
        allowed[msg.sender][_spender] += _addedValue;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
	
	function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         

        if (_value == 0) { Transfer(msg.sender, _to, 0); return; }  

         
         

        if (balances[msg.sender] >= _value && !(balances[_to] + _value < balances[_to])) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;  
        } else { return false; }  
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function enableICO() public {
        require(msg.sender == contractOwner);  
        ICOEnabled = true;
    }

    function disableICO() public {
        require(msg.sender == contractOwner);  
        ICOEnabled = false;  
    }

    function() payable public {
        require(ICOEnabled);
        require(msg.value > 0);  
        if(balances[msg.sender]+(msg.value / 1e14) > 50000) { revert(); }  
        if(totalSupply+(msg.value / 1e14) > hardLimitICO) { revert(); }  
        
        contractOwner.transfer(msg.value);  

        uint256 tokensIssued = (msg.value / 1e14);  

        totalSupply += tokensIssued;  
        balances[msg.sender] += tokensIssued;  

        Transfer(address(this), msg.sender, tokensIssued);  
    }
}