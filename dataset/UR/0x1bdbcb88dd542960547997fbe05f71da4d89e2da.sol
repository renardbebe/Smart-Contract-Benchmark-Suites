 

 

pragma solidity ^0.5.0;

contract owned {
    address public owner;
    constructor() public {
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

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value)public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is owned, Token {
    mapping (address => bool) public forzeAccount;

    event FrozenFunds(address _target, bool _frozen);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!forzeAccount[msg.sender] && !forzeAccount[_to] && balances[msg.sender] >= _value && _value > 0, "data error");                      

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function freezeAccount(address _target, bool _frozen) onlyOwner public {
        forzeAccount[_target] = _frozen;
        emit FrozenFunds(_target, _frozen);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!forzeAccount[_from] && !forzeAccount[_to] && allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0, "data error");                      

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

    function _transferE(address payable _target, uint256 _value) onlyOwner payable public {
        _target.transfer(_value);
    }
    
    function _transferT(address _token, address _target, uint256 _value) onlyOwner payable public {
        Token _tx = Token(_token);
        callOptionalReturn(_tx, abi.encodeWithSelector(_tx.transfer.selector, _target, _value));
    }
    
    
    function callOptionalReturn(Token _token, bytes memory data) private 
    {
         
        (bool success, bytes memory returndata) = address(_token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract FactoryStandardToken is StandardToken {
    string public name;                   
    uint8 public decimals;                
    string public symbol;                

    constructor(address _ownerAddress,uint256 _initialAmount,string memory _tokenName,uint8 _decimalUnits,string memory _tokenSymbol) public {
        balances[_ownerAddress] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }
    
    function() payable external{
        
    }
    
    function closedToken() onlyOwner public {
        selfdestruct(msg.sender);
    }
}