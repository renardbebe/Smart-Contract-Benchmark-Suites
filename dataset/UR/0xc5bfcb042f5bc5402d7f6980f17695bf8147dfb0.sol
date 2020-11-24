 

pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    function Owned() public {
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

 
 
contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;


     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public 
    {
        _totalSupply = initialSupply * TOKEN_UNIT;   
        _balanceOf[msg.sender] = _totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }


    function totalSupply() constant public returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address src) constant public returns (uint256) {
        return _balanceOf[src];
    }
    function allowance(address src, address guy) constant public returns (uint256) {
        return _allowance[src][guy];
    }


     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(_balanceOf[_from] >= _value);
         
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
         
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
         
        _balanceOf[_from] -= _value;
         
        _balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);      
        _allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) 
    {
        _allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);    
        _balanceOf[msg.sender] -= _value;             
        _totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_balanceOf[_from] >= _value);                 
        require(_value <= _allowance[_from][msg.sender]);     
        _balanceOf[_from] -= _value;                          
        _allowance[_from][msg.sender] -= _value;              
        _totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}


 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


contract PeralToken is Owned, TokenERC20 {
    using SafeMath for uint256;

     
    event FrozenFunds(address target, bool frozen);
    
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) private allowMint;
    bool _closeSale = false;

     
    function PeralToken(uint remainAmount,string tokenName,string tokenSymbol) TokenERC20(remainAmount, tokenName, tokenSymbol) public {
        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (_balanceOf[_from] >= _value);                
        require (_balanceOf[_to].add(_value) > _balanceOf[_to]);  
        require(_closeSale);
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                          
        _balanceOf[_to] = _balanceOf[_to].add(_value);                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) public {
        require(allowMint[msg.sender]);
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function mintTokenWithUnit(address target, uint256 mintedAmount) public {
        require(allowMint[msg.sender]);
        uint256 amount = mintedAmount.mul(TOKEN_UNIT);
        _balanceOf[target] = _balanceOf[target].add(amount);
        _totalSupply = _totalSupply.add(amount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }



     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     function setMintContactAddress(address _contactAddress) onlyOwner public {
        allowMint[_contactAddress] = true;
    }

    function disableContactMint(address _contactAddress) onlyOwner public {
        allowMint[_contactAddress] = false;
    }

    function closeSale(bool close) onlyOwner public {
        _closeSale = close;
    }

}