 

 
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
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
    );
} 
contract PostboyToken is ERC20 {
    using SafeMath for uint256;

    struct Account {
        uint256 balance;
        uint256 lastDividends;
    }

    string public constant name = "PostboyToken";  
    string public constant symbol = "PBY";  
    uint8 public constant decimals = 0;  

    uint256 public constant INITIAL_SUPPLY = 100000;

    uint256 public totalDividends;
    uint256 totalSupply_;
    
    mapping (address => Account) accounts;
    mapping (address => mapping (address => uint256)) internal allowed;

    address public admin;
    address public payer;

   
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        totalDividends = 0;
        accounts[msg.sender].balance = INITIAL_SUPPLY;
        admin = msg.sender;
        payer = address(0);
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
      public
      returns (bool)
    {
        require(_value <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return accounts[_owner].balance;
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
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function dividendBalanceOf(address account) public view returns (uint256) {
        uint256 newDividends = totalDividends.sub(accounts[account].lastDividends);
        uint256 product = accounts[account].balance.mul(newDividends);
        return product.div(totalSupply_);
    }

     
    function claimDividend() public {
        uint256 owing = dividendBalanceOf(msg.sender);
        if (owing > 0) {
            accounts[msg.sender].lastDividends = totalDividends;
            msg.sender.transfer(owing);
        }
    }


     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value <= accounts[_from].balance);
        require(accounts[_to].balance + _value >= accounts[_to].balance);
    
        uint256 fromOwing = dividendBalanceOf(_from);
        uint256 toOwing = dividendBalanceOf(_to);
        require(fromOwing <= 0 && toOwing <= 0);
    
        accounts[_from].balance = accounts[_from].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
    
        accounts[_to].lastDividends = accounts[_from].lastDividends;
    
        emit Transfer(_from, _to, _value);
    }

    function changePayer(address _payer) public returns (bool) {
        require(msg.sender == admin);
        payer = _payer;
    }

    function sendDividends() public payable {
        require(msg.sender == payer);
        
        totalDividends = totalDividends.add(msg.value);
    }

    function () external payable {
        require(false);
    }
}