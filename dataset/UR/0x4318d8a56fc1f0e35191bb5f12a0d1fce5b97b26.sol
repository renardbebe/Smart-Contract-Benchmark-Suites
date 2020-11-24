 

pragma solidity ^0.4.23;

library SafeMath {

 
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract Bitcrore is Ownable{
using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    uint256 public releaseTime;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    constructor (uint256 initialSupply,string tokenName,string tokenSymbol,uint256 _releaseTime) public
    {
        releaseTime = _releaseTime;
        totalSupply = initialSupply;   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(now >= releaseTime);
        require(!frozenAccount[_to]);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function allowance( address _owner, address _spender  ) public view returns (uint256)
    {
        return allowance[_owner][_spender];
    }
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(now >= releaseTime);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function distributeToken(address[] addresses, uint256[] _value) public onlyOwner returns (bool success){
         
        assert (addresses.length == _value.length);
        for (uint i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], _value[i]);
        }
        return true;
    }
    
    function burn(uint256 _value) public onlyOwner returns (bool success) {
         
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply =totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, 0x0 , _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
         
        require(balanceOf[_from] >= _value);                 
        require(!frozenAccount[_from]);
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        emit Transfer(msg.sender, 0x0 , _value);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!frozenAccount[_spender]);
        require(!frozenAccount[msg.sender]);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseApproval( address _spender, uint256 _addedValue) public returns (bool)  {
        require(!frozenAccount[_spender]);
        require(!frozenAccount[msg.sender]);
        allowance[msg.sender][_spender] = (
        allowance[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
  
    function decreaseApproval( address _spender, uint256 _subtractedValue ) public returns (bool)  {
        require(!frozenAccount[_spender]);
        require(!frozenAccount[msg.sender]);
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
          allowance[msg.sender][_spender] = 0;
        } else {
          allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

}