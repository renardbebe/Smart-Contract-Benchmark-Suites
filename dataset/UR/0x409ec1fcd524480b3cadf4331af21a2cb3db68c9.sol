 

pragma solidity ^0.4.19;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) internal balances;
    
     
    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }
    
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value && _value > 0 && _to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}



contract StandardToken is BasicToken, ERC20 {
    
    mapping (address => mapping (address => uint256)) internal allowances;
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(allowances[_from][msg.sender] >= _value && _to != 0x0 && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0 && _value > 0);
        if(allowances[msg.sender][_spender] > 0 ) {
            allowances[msg.sender][_spender] = 0;
        }
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}


contract BurnableToken is StandardToken, Ownable {
    
    event TokensBurned(address indexed burner, uint256 value);
    
    function burnFrom(address _from, uint256 _tokens) public onlyOwner {
        if(balances[_from] < _tokens) {
            TokensBurned(_from,balances[_from]);
            balances[_from] = 0;
            totalSupply = totalSupply.sub(balances[_from]);
        } else {
            balances[_from] = balances[_from].sub(_tokens);
            totalSupply = totalSupply.sub(_tokens);
            TokensBurned(_from, _tokens);
        }
    }
}


contract Propvesta is BurnableToken {

    string public website = "www.propvesta.com";
    
    function Propvesta() public {
        name = "Propvesta";
        symbol = "PROV";
        decimals = 18;
        totalSupply = 10000000000e18;
        balances[owner] = 7000000000e18;
        Transfer(address(this), owner, 7000000000e18);
        balances[0x304f970BaA307238A6a4F47caa9e0d82F082e3AD] = 2000000000e18;
        Transfer(address(this), 0x304f970BaA307238A6a4F47caa9e0d82F082e3AD, 2000000000e18);
        balances[0x19294ceEeA1ae27c571a1C6149004A9f143e1aA5] = 1000000000e18;
        Transfer(address(this), 0x19294ceEeA1ae27c571a1C6149004A9f143e1aA5, 1000000000e18);
    }
}