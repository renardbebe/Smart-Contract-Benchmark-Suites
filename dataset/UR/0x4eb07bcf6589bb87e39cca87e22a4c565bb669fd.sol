 

pragma solidity ^0.4.21;

 
contract EIP20Interface {
    
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract uptrennd is EIP20Interface {
    
    
     
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        uint _value = balances[msg.sender];
        balances[msg.sender] -= _value;
        balances[newOwner] += _value;
        emit Transfer(msg.sender, newOwner, _value);
    }

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public TokenPrice;

    string public name;                   
    uint256 public decimals;                
    string public symbol;                 

     
    function uptrennd(
        uint256 _initialAmount,
        string _tokenName,
        uint256 _decimalUnits,
        string _tokenSymbol,
        uint256 _price
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        owner = msg.sender;
        TokenPrice = _price;
    }
    
     
    function setPrice(uint256 _price) onlyOwner public returns(bool success){
        TokenPrice =  _price;
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }
    
     
    function purchase(address _to, uint256 _value) public payable returns (bool success) {
       
        uint amount = msg.value/TokenPrice;
        require(balances[owner] >= amount);
        require(_value == amount);
        balances[owner] -= amount;
        balances[_to] += amount;
        emit Transfer(owner, _to, amount); 
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        totalSupply = totalSupply - value;
        balances[account] = balances[account] - value;
        emit Transfer(account, address(0), value);
    }
   
     
    function burn(uint256 value) onlyOwner public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address to, uint256 value) public returns (bool success) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);  
        return true;
    }
}