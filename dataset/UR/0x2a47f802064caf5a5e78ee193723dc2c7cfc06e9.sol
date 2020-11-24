 

pragma solidity ^0.4.24;


 
library SafeMath {

     
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
    event OwnershipRenounced(address indexed previousOwner);
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

   
 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}
    
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
     public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
      public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
     address indexed owner,
     address indexed spender,
     uint256 value
    );
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public 
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

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
        uint _addedValue
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
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;
    
   
  mapping (address => bool) public transferAgents;

  modifier canTransfer(address _sender) {
    if(!released) {
        require(transferAgents[_sender]);
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner  public {
    require( addr != address(0));
     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner  public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }


   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}
 
contract Moolyacoin is StandardToken, Ownable, ReleasableToken{
    string  public  constant name = "moolyacoin";
    string  public  constant symbol = "moolya";
    uint8   public  constant decimals = 18;
        
    constructor(uint _value) public{
        totalSupply_ = _value * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0x0), msg.sender, totalSupply_);
    }

    function allocate(address _investor, uint _amount) public onlyOwner returns (bool){
    require(_investor != address(0));
    uint256 amount = _amount * (10 ** uint256(decimals));
    require(amount <= balances[owner]);
    balances[owner] = balances[owner].sub(amount);
    balances[_investor] = balances[_investor].add(amount);
    return true;
    }
    
    function mintable(uint _value) public onlyOwner returns (bool){
        uint256 amount = _value * (10 ** uint256(decimals));
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_ = totalSupply_.add(amount);
    }

    function burnReturn(address _addr, uint _value) public onlyOwner returns (bool) {
        require(_addr != address(0));
        require(balances[_addr] >= _value);
        balances[_addr] = balances[_addr].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        return true;
        
    }

    function burnDead(address _addr, uint _value) public onlyOwner returns (bool){
        require(_addr != address(0));
        require(balances[_addr] >= _value);
        balances[_addr] = balances[_addr].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        return true;
    }

}