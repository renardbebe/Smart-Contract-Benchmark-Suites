 

 
library SafeMath {
  uint constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
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

 
contract Owned {
  address public owner;
  address private newOwner;

  event OwnershipTransferred(address indexed_from, address indexed_to);

  function Owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);  
  }
}

 
contract ERC223 {
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 
 
 contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
       
    }
}

 
contract C2L is ERC223, Owned {
   
  uint internal constant INITIAL_COIN_BALANCE = 21000000;  

   
  string public name = "C2L";  
  string public symbol = "C2L";
  uint8 public decimals = 0;
  mapping(address => bool) beingEdited;  

  uint public totalCoinSupply = INITIAL_COIN_BALANCE;  
  mapping(address => uint) internal balances;  
  mapping(address => mapping(address => uint)) internal allowed;  
  address[] addressLUT;

   
  function C2L() public {
    totalCoinSupply = INITIAL_COIN_BALANCE;
    balances[owner] = totalCoinSupply;
    updateAddresses(owner);
  }

   
  function name() public view returns (string _name) {
    return name;
  }

  function symbol() public view returns (string _symbol) {
    return symbol;
  }

  function decimals() public view returns (uint8 _decimals) {
    return decimals;
  }

   
  function totalSupply() public view returns (uint256 _supply) {
    return totalCoinSupply;
  }

   
  function setEditedTrue(address _subject) private {
    beingEdited[_subject] = true;
  }

  function setEditedFalse(address _subject) private {
    beingEdited[_subject] = false;
  }

   
  function balanceOf(address who) public view returns (uint) {
    return balances[who];
  }

   
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
           
          length := extcodesize(_addr)
    }
    return (length>0);
  }

   
  function mint(uint amount) public onlyOwner {
    require(beingEdited[owner] != true);
    setEditedTrue(owner);
    totalCoinSupply = SafeMath.add(totalCoinSupply, amount);
    balances[owner] = SafeMath.add(balances[owner], amount);
    setEditedFalse(owner);
  }

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if(isContract(_to)) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
       
      require (balances[msg.sender] >= _value); 
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
       
      balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
      balances[_to] = SafeMath.add(balances[_to], _value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      emit Transfer(msg.sender, _to, _value, _data);  
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
    }
    else {
      return transferToAddress(_to, _value, _data);
    }
  }

   
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
      if(isContract(_to)) {
          return transferToContract(_to, _value, _data);
      }
      else {
          return transferToAddress(_to, _value, _data);
      }
  }

   
  function transfer(address _to, uint _value) public returns (bool success) {
       
       
      bytes memory empty;
      if(isContract(_to)) {
          return transferToContract(_to, _value, empty);
      }
      else {
          return transferToAddress(_to, _value, empty);
      }
  }

   
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
      require (balanceOf(msg.sender) >= _value);
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
      balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
      balances[_to] = SafeMath.add(balanceOf(_to), _value);
      emit Transfer(msg.sender, _to, _value, _data);
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
    }

   
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
      require(beingEdited[_to] != true && beingEdited[msg.sender] != true);
      require (balanceOf(msg.sender) >= _value);
      setEditedTrue(_to);
      setEditedTrue(msg.sender);
      balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
      balances[_to] = SafeMath.add(balanceOf(_to), _value);
      ContractReceiver receiver = ContractReceiver(_to);
      receiver.tokenFallback(msg.sender, _value, _data);
      emit Transfer(msg.sender, _to, _value, _data);
      setEditedFalse(_to);
      setEditedFalse(msg.sender);
      updateAddresses(_to);
      updateAddresses(msg.sender);
      return true;
  }

   
  function updateAddresses(address _lookup) private {
    for(uint i = 0; i < addressLUT.length; i++) {
      if(addressLUT[i] == _lookup) return;
    }
    addressLUT.push(_lookup);
  }

   
  function () public payable {
  }

   
  function killCoin() public onlyOwner {
    selfdestruct(owner);
  }

}