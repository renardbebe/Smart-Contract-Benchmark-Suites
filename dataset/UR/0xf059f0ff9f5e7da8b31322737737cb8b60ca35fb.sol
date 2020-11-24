 

pragma solidity ^0.4.24;


contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint256 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract ContractReceiver {
     
  struct TKN {
    address sender;
    uint value;
    bytes data;
    bytes4 sig;
  }
  
  
  function tokenFallback(address _from, uint _value, bytes _data) public {
    TKN memory tkn;
    tkn.sender = _from;
    tkn.value = _value;
    tkn.data = _data;
    uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    tkn.sig = bytes4(u);
    
     
  }
}


contract ERC223Token is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;
  
  string public name;
  string public symbol;
  uint256 public decimals;
  uint256 public totalSupply;

  modifier validDestination( address to ) {
    require(to != address(0x0));
    _;
  }
  
  
   
  function name() public view returns (string _name) {
    return name;
  }
   
  function symbol() public view returns (string _symbol) {
    return symbol;
  }
   
  function decimals() public view returns (uint256 _decimals) {
    return decimals;
  }
   
  function totalSupply() public view returns (uint256 _totalSupply) {
    return totalSupply;
  }
  
  
   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) validDestination(_to) public returns (bool success) {
      
    if(isContract(_to)) {
      if (balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      emit Transfer(msg.sender, _to, _value, _data);
      return true;
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
}
  

   
  function transfer(address _to, uint _value, bytes _data) validDestination(_to) public returns (bool success) {
      
    if(isContract(_to)) {
      return transferToContract(_to, _value, _data);
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
  }
  
   
   
  function transfer(address _to, uint _value) validDestination(_to) public returns (bool success) {
      
     
     
    bytes memory empty;
    if(isContract(_to)) {
      return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

   
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
       
      length := extcodesize(_addr)
    }
    return (length>0);
  }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}


contract ReleasableToken is ERC223Token, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
      require(transferAgents[_sender]);
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
     
    return super.transfer(_to, _value);
  }

  function transfer(address _to, uint _value, bytes _data) public canTransfer(msg.sender) returns (bool success) {
     
    return super.transfer(_to, _value, _data);
  }

  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public canTransfer(msg.sender) returns (bool success) {
    return super.transfer(_to, _value, _data, _custom_fallback);
  }
}


contract AMLToken is ReleasableToken {

   
  event OwnerReclaim(address fromWhom, uint amount);

  constructor(string _name, string _symbol, uint _initialSupply, uint _decimals) public {
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    totalSupply = _initialSupply;
    decimals = _decimals;

    balances[owner] = totalSupply;
  }

   
   
   
  function transferToOwner(address fromWhom) public onlyOwner {
    if (released) revert();

    uint amount = balanceOf(fromWhom);
    balances[fromWhom] = balances[fromWhom].sub(amount);
    balances[owner] = balances[owner].add(amount);
    bytes memory empty;
    emit Transfer(fromWhom, owner, amount, empty);
    emit OwnerReclaim(fromWhom, amount);
  }
}


contract MediarToken is AMLToken {

  uint256 public constant INITIAL_SUPPLY = 420000000 * (10 ** uint256(18));

   
  constructor() public 
    AMLToken("Mediar", "MDR", INITIAL_SUPPLY, 18) {
  }
}