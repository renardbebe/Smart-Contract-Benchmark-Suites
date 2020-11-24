 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external;
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    function transfer(address _to, uint256 _value) external {
        address _from = msg.sender;
        require (balances[_from] >= _value && balances[_to] + _value > balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
    }

     

    function transferFrom(address _from, address _to, uint256 _value) external {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
      }
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        balance = balances[_owner];
    }

    function approve(address _spender, uint256 _value) external {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
  }
}


contract HadeCoin is BasicToken {

    using SafeMath for uint256;

     

     
    string public name = "HADE Platform";

     
    string public symbol = "HADE";

     
    uint8 public decimals = 18;

     
    uint256 public totalSupply = 150000000 * 10**18;

     
    address public adminMultiSig;

     

    event ChangeAdminWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

     

    function HadeCoin(address _adminMultiSig) public {

        adminMultiSig = _adminMultiSig;
        balances[adminMultiSig] = totalSupply;
    }

     

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminMultiSig);
        _;
    }

     

     
     
     
    function mint(address _to, uint256 _value) external onlyAdmin {

        require(_to != address(0));
        require(_value > 0);
        totalSupply += _value;
        balances[_to] += _value;
        Transfer(address(0), _to, _value);
    }

     
     
     
    function burn(uint256 _value) external onlyAdmin {

        require(_value > 0 && balances[msg.sender] >= _value);
        totalSupply -= _value;
        balances[msg.sender] -= _value;
    }

     
     
     
    function changeAdminAddress(address _newAddress)

    external
    onlyAdmin
    nonZeroAddress(_newAddress)
    {
        adminMultiSig = _newAddress;
        ChangeAdminWalletAddress(now, adminMultiSig);
    }

     
     
    function() public {
        revert();
    }
}