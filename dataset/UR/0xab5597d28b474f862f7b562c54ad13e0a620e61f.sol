 

pragma solidity >=0.4.22 <0.7.0;

 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);  
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
}
contract ERC20 {

    function getSupply() public view returns (uint supply);
    
    function balanceOf(address _owner) public view returns (uint balance);
    
    function transfer(address _to, uint _value) public returns (bool success);
    
    function burn(uint _value) public returns (bool success);
    
    function freeze(address _to, uint _value) public returns (bool success);
    
    function unfreeze(address _to, uint _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    
    function approve(address _spender, uint _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    event Burn(address indexed _from, uint value);
}
contract StandardToken is ERC20 {

    using SafeMath for uint;

    uint public totalSupply;

    mapping (address => uint) balances;
    
    mapping (address => uint) public freezeOf;
    
    mapping (address => mapping (address => uint)) allowed;

    function getSupply() public view returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    function burn(uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value); 
        emit Burn(msg.sender, _value);
        return true;
    }
   
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        require(_to != address(0));
        require(_from != address(0));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
contract Controlled {

    address public controller;

    constructor() public {
        controller = msg.sender;
    }

    function changeController(address _newController) public only_controller {
        controller = _newController;
    }
    
    function getController() view public returns (address) {
        return controller;
    }

    modifier only_controller { 
        require(msg.sender == controller);
        _; 
    }

}
contract DGPE is StandardToken, Controlled {
    
    using SafeMath for uint;
    
    uint8 public decimals;

    string public constant name = "Digital People";
    
    string public constant symbol = "DGPE";

    uint unlockTime;
    
    mapping (address => bool) internal precirculated;

    constructor(uint _unlockTime,uint8 _decimals, uint _totalSupply) public {
        unlockTime = _unlockTime;
        
        decimals = _decimals;
        
        totalSupply = _totalSupply * 10 ** uint(decimals);
        
        balances[msg.sender] = balances[msg.sender].add(totalSupply);
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint _amount) can_transfer(msg.sender, _to) public returns (bool success) {
        return super.transfer(_to, _amount);
    }
    function burn(uint _amount)  public returns (bool success) {
        return super.burn(_amount);
    }
    function freeze(address _from, uint _value) only_controller public returns (bool success) {
        require(balances[_from] >= _value && _value > 0);
        require(_from != address(0));
        balances[_from] = balances[_from].sub(_value);
        freezeOf[_from] = freezeOf[_from].add(_value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
    
    function unfreeze(address _from, uint _value) only_controller public returns (bool success) {
        require(freezeOf[_from] >= _value && _value > 0);
        require(_from != address(0));
        freezeOf[_from] = freezeOf[_from].sub(_value);
        balances[_from] = balances[_from].add(_value);
        emit Transfer(address(0), _from, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) can_transfer(_from, _to) public returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }

    function mint(address _owner, uint _amount) external only_controller returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_owner] = balances[_owner].add(_amount);

        emit Transfer(address(0), _owner, _amount);
        return true;
    }

    function allowPrecirculation(address _addr) only_controller public {
        precirculated[_addr] = true;
    }

    function disallowPrecirculation(address _addr) only_controller public {
        precirculated[_addr] = false;
    }
   

    function isPrecirculationAllowed(address _addr) view public returns(bool) {
        return precirculated[_addr];
    }
    
    function changeUnlockTime(uint _unlockTime) only_controller public {
        unlockTime = _unlockTime;
    }

    function getUnlockTime() view public returns (uint) {
        return unlockTime;
    }

    modifier can_transfer(address _from, address _to) {
        require((block.number >= unlockTime) || (isPrecirculationAllowed(_from) && isPrecirculationAllowed(_to)));
        _;
    }


}