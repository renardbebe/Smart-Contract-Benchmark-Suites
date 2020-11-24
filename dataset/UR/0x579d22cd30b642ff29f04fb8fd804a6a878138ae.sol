 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Peony is Ownable {

  string public version;
  string public unit = "piece";
  uint256 public total;
  struct Bullion {
    string index;
    string unit;
    uint256 amount;
    string ipfs;
  }
  bytes32[] public storehouseIndex;
  mapping (bytes32 => Bullion) public storehouse;
  address public tokenAddress;
  uint256 public rate = 10;
  PeonyToken token;





  function Peony(string _version) {
    version = _version;
  }




  event Stock (
    string index,
    string unit,
    uint256 amount,
    string ipfs,
    uint256 total
  );

  event Ship (
    string index,
    uint256 total
  );

  event Mint (
    uint256 amount,
    uint256 total
  );

  event Reduce (
    uint256 amount,
    uint256 total
  );





  function stock(string _index, string _unit, uint256 _amount, string _ipfs) onlyOwner returns (bool);

  function ship(string _index) onlyOwner returns (bool);

  function mint(uint256 _ptAmount) onlyOwner returns (bool);

  function reduce(uint256 _tokenAmount) onlyOwner returns (bool);

  function setRate(uint256 _rate) onlyOwner returns (bool);

  function setTokenAddress(address _address) onlyOwner returns (bool);



  function convert2Peony(uint256 _amount) constant returns (uint256);

  function convert2PeonyToken(uint256 _amount) constant returns (uint256);

  function info(string _index) constant returns (string, string, uint256, string);

  function suicide() onlyOwner returns (bool);
}

contract PeonyToken is Ownable, ERC20 {
  using SafeMath for uint256;

  string public version;
  string public name;
  string public symbol;
  uint256 public decimals;
  address public peony;

  mapping(address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  uint256 public totalSupply;
  uint256 public totalSupplyLimit;
  mapping(address => uint256) public transferLimits;

  function PeonyToken(
    string _version,
    uint256 initialSupply,
    uint256 totalSupplyLimit_,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
    require(totalSupplyLimit_ == 0 || totalSupplyLimit_ >= initialSupply);
    version = _version;
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    totalSupplyLimit = totalSupplyLimit_;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  modifier isPeonyContract() {
    require(peony != 0x0);
    require(msg.sender == peony);
    _;
  }

  modifier isOwnerOrPeonyContract() {
    require(msg.sender != address(0) && (msg.sender == peony || msg.sender == owner));
    _;
  }

   
  function produce(uint256 amount) isPeonyContract returns (bool) {
    require(totalSupplyLimit == 0 || totalSupply.add(amount) <= totalSupplyLimit);

    balances[owner] = balances[owner].add(amount);
    totalSupply = totalSupply.add(amount);

    return true;
  }

   
  function reduce(uint256 amount) isPeonyContract returns (bool) {
    require(balances[owner].sub(amount) >= 0);
    require(totalSupply.sub(amount) >= 0);

    balances[owner] = balances[owner].sub(amount);
    totalSupply = totalSupply.sub(amount);

    return true;
  }

   
  function setPeonyAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    peony = _address;
    return true;
  }

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));
    require(transferLimits[msg.sender] == 0 || transferLimits[msg.sender] >= _value);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function setTransferLimit(uint256 transferLimit) returns (bool) {
    transferLimits[msg.sender] = transferLimit;
  }

   
  function suicide() onlyOwner returns (bool) {
    selfdestruct(owner);
    return true;
  }
}

library ConvertStringByte {
  function bytes32ToString(bytes32 x) constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
          bytesString[charCount] = char;
          charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  function stringToBytes32(string memory source) returns (bytes32 result) {
    assembly {
      result := mload(add(source, 32))
    }
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}