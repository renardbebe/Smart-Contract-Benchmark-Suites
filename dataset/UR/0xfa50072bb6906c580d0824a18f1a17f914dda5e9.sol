 

pragma solidity 0.5.9;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract Token {

     
    function totalSupply() public view returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 internal _totalSupply;
}


contract HumanStandardToken is StandardToken {

    function () external {
         
        revert();
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;                
        _totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
        emit OwnershipTransferred(address(0), owner);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }


     
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0), "Cannot transfer control of the contract to zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    
}