 

pragma solidity ^0.4.0;

 
 
contract ERC20Interface {
	 
	function totalSupply() public constant returns (uint256);
	
	 
	function balanceOf(address _owner) public constant returns (uint256);
	
	 
	function transfer(address _to, uint256 _value) public returns (bool);
	
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
	
	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool);
	
	 
	function allowance(address _owner, address _spender) public constant returns (uint256);
	
	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract RandomToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract Number1Dime is ERC20Interface {
    bool public is_purchase_allowed;
    bool public is_transfer_allowed;
    uint256 public totSupply = 0;
    uint256 public totContribution = 0;
    address owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    modifier onlyOwner() {
        if (msg.sender != owner) { revert(); }
        _;
    }
    
    modifier transferAllowed() {
        if (! is_transfer_allowed) { revert(); }
        _;
    }
    
    modifier purchaseAllowed() {
        if (! is_purchase_allowed) { revert(); }
        _;
    }
    
    function Number1Dime() public {
        owner = msg.sender;
        enableTransfer(false);
        enablePurchase(false);
    }

    function name() public pure returns (string)    { return "Number One Dime"; }
    function symbol() public pure returns (string)  { return "N1D"; }
    function decimals() public pure returns (uint8) { return 0; }
    
    function get_balance(address a) public view returns (uint256) { return a.balance; }
    
    function get_stats() public view onlyOwner returns (uint256 _totSupply, uint256 _totContribution) {
        _totSupply = totSupply;
        _totContribution = totContribution;
    }
    
    function enablePurchase(bool _enab) public onlyOwner returns (bool) {
        return is_purchase_allowed = _enab;
    }
    
    function enableTransfer(bool _enab) public onlyOwner returns (bool) {
        return is_transfer_allowed = _enab;
    }
    
    function totalSupply() public view returns (uint256) {
        return totSupply;
    }
    
    function balanceOf(address a) public view returns (uint256) {
        return balances[a];
    }

    function transfer(address _to, uint256 _amount) public transferAllowed returns (bool) {
        if ( 
                _amount > 0
            &&  balances[msg.sender] >= _amount
            &&  balances[_to] + _amount > balances[_to]
        ) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public transferAllowed returns (bool) {
        if (
                _amount > 0
            &&  balances[_from] >= _amount
            &&  allowed[_from][msg.sender] >= _amount
            &&  balances[_to] + _amount > balances[_to]
        ) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function() public payable purchaseAllowed {
        if (msg.value == 0) { return; }

        totContribution += msg.value;
        uint256 tokensIssued = msg.value;
        totSupply += tokensIssued;
        owner.transfer(msg.value);
        balances[msg.sender] += tokensIssued;
        Transfer(address(this), msg.sender, tokensIssued);
    }
    
    function withdrawForeignTokens(address _tokenContract) public onlyOwner returns (bool) {
        RandomToken token = RandomToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}