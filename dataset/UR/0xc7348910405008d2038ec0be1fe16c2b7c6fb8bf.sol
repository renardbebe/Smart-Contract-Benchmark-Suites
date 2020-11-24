 

pragma solidity ^0.4.24;

 
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract TokenControl {
     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

      
    bool public enablecontrol = true;


    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
  
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    
    modifier whenNotPaused() {
        require(enablecontrol);
        _;
    }
    

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }
    
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
    
    function enableControl(bool _enable) public onlyCEO{
        enablecontrol = _enable;
    }

  
}

 
contract StandardToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract BurnableToken is StandardToken, TokenControl {

    event Burn(address indexed burner, uint256 value);

 
     
    function burn(uint256 _value) onlyCOO whenNotPaused public {
        _burn(_value);
    }

    function _burn( uint256 _value) internal {
        require(_value <= balances[cfoAddress]);
         
         

        balances[cfoAddress] = balances[cfoAddress].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(cfoAddress, _value);
        emit Transfer(cfoAddress, address(0), _value);
    }
}

contract MintableToken is StandardToken, TokenControl {
    event Mint(address indexed to, uint256 amount);
    

      
    function mint(uint256 _value) onlyCOO whenNotPaused  public {
        _mint(_value);
    }

    function _mint( uint256 _value) internal {
        
        balances[cfoAddress] = balances[cfoAddress].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        emit Mint(cfoAddress, _value);
        emit Transfer(address(0), cfoAddress, _value);
    }

}

 

contract PausableToken is StandardToken, TokenControl {
    
      
    bool public transferEnabled = true;
    
     
    function enableTransfer(bool _enable) public onlyCEO{
        transferEnabled = _enable;
    }
    
    modifier transferAllowed() {
          
        assert(transferEnabled);
        _;
    }
    

    function transfer(address _to, uint256 _value) public transferAllowed() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public transferAllowed() returns (bool) {
        return super.approve(_spender, _value);
    }
}

contract BABA is BurnableToken, MintableToken, PausableToken {
    
     
    string public name;
    string public symbol;
     
    uint8 public decimals;

    constructor(address _ceoAddress, address _cfoAddress, address _cooAddress)  public {
        name = "T-BABA";
        symbol = "T-BABA";
        decimals = 8;
        
        ceoAddress = _ceoAddress;
        cfoAddress = _cfoAddress;
        cooAddress = _cooAddress;
         
        totalSupply_ = 5000;
         
        balances[cfoAddress] = totalSupply_;
    }

    
     
    function() payable public { }
}