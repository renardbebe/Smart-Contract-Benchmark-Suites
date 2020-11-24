 

pragma solidity ^0.4.11;

contract CyberyTokenSale {
    address public owner;  
    bool public purchasingAllowed = false;
    uint256 public totalContribution = 0;
    uint256 public totalSupply = 0;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    function name() constant returns (string) { return "Cybery Token"; }
    function symbol() constant returns (string) { return "CYB"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { 
        return balances[_owner]; 
    }

    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function CyberyTokenSale() {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    function enablePurchasing() onlyOwner {
        purchasingAllowed = true;
    }

     
    function disablePurchasing() onlyOwner {
        purchasingAllowed = false;
    }

     
     
    function transfer(address _to, uint256 _value) validAddress(_to) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) validAddress(_from) returns (bool success) {
        require(_to != 0x0);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 _value) validAddress(_spender) returns (bool success) {
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function () payable validAddress(msg.sender) {
        require(msg.value > 0);
        assert(purchasingAllowed);
        owner.transfer(msg.value);  
        totalContribution = safeAdd(totalContribution, msg.value);
        uint256 tokensIssued = (msg.value * 100);  
         
        totalSupply = safeAdd(totalSupply, tokensIssued);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokensIssued);
        balances[owner] = safeAdd(balances[owner], tokensIssued);  
        Transfer(address(this), msg.sender, tokensIssued);
    }

    function getStats() returns (uint256, uint256, bool) {
        return (totalContribution, totalSupply, purchasingAllowed);
    }
}