 

pragma solidity ^0.4.22;

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

 
library SafeMath {
   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public _totalSupply;

     
    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);   
        _balanceOf[msg.sender] = _totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

    function balanceOf(address _addr) public view returns (uint256) {
        return _balanceOf[_addr];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(_balanceOf[_from] >= _value);
         
        require(_balanceOf[_to].add(_value) > _balanceOf[_to]);
         
        uint previousBalances = _balanceOf[_from].add(_balanceOf[_to]);
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(_balanceOf[_from].add(_balanceOf[_to]) == previousBalances);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

 
 
 

contract MGT is owned, TokenERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _frozenOf;
    event FrozenFunds(address _taget,  uint256 _value);
     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {

    }
    function transfer(address _to, uint256 _value)  public returns (bool) {
        if (_value > 0 && _balanceOf[msg.sender].sub(_frozenOf[msg.sender]) >= _value) {
            _transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_value > 0 && allowance[_from][msg.sender] > 0 &&
            allowance[_from][msg.sender] >= _value &&
            _balanceOf[_from].sub(_frozenOf[_from]) >= _value
            ) {
            _transfer(_from, _to, _value);
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    
    function frozen(address _frozenaddress, uint256 _value) onlyOwner public returns (bool) {
        if (_value >= 0 && _balanceOf[_frozenaddress] >= _value) {
            _frozenOf[_frozenaddress] = _value;
            emit FrozenFunds(_frozenaddress, _value);
            return true;
        } else {
            return false;
        }
    }

    
    function frozenOf(address _frozenaddress) public view returns (uint256) {
        return _frozenOf[_frozenaddress];
    }

     
    function approveAirdrop(address _owner, address _spender, uint256 _value) public returns (bool success) {
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
        return true;
    }

     
    function transferAirdrop(address _owner, address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][_owner]);
        allowance[_from][_owner] = allowance[_from][_owner].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}