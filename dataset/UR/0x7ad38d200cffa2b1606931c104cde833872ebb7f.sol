 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) onlyOwner public {
        owner = _newOwner;
    }
}

contract GOG is owned {

    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 6;
     
    uint256 public totalSupply;
    bool public paused;

     
    mapping (address => uint256) public balances;
     
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);
     
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Pause(address indexed owner);
    event Unpause(address indexed owner);

    modifier onlyUnpaused() {
      require(!paused);
      _;
    }

     
    constructor() public {
        totalSupply = 10000000000000000;                
        balances[msg.sender] = totalSupply;           
        name = "GoGlobe Token";                        
        symbol = "GOG";                                
    }

     
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _value) public onlyUnpaused returns (bool) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
       
  function increaseApproval(address _spender, uint _addedValue) public onlyUnpaused returns (bool) {
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public onlyUnpaused returns (bool) {
    uint oldValue = allowance[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowance[msg.sender][_spender] = 0;
    } else {
      allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }

     
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowance[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0));

         
        require(balances[_from] >= _value);
         
        uint previousBalances = balances[_from].add(balances[_to]);
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public onlyUnpaused {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnpaused returns (bool) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function burn(uint256 _value) public onlyUnpaused returns (bool) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] = balances[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyUnpaused returns (bool) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }

    function pause() public onlyOwner returns (bool) {
      paused = true;
      return true;
    }

    function unPause() public onlyOwner returns (bool) {
      paused = false;
      return true;
    }
}