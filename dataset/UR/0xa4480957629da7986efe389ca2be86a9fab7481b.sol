 

pragma solidity ^0.4.20;

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC223 {
  uint public totalSupply;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);
  function balanceOf(address who) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
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








 
 
contract CLIP is ERC223, Ownable {
  using SafeMath for uint256;

  string public name = "ClipToken";
  string public symbol = "CLIP";
  uint8 public decimals = 8;
  uint256 public totalSupply = 333e8 * 1e8;
  uint256 public distributeAmount = 0;

  mapping (address => uint256) public balanceOf;
  mapping (address => bool) public frozenAccount;
  mapping (address => uint256) public unlockUnixTime;

  event FrozenFunds(address indexed target, bool frozen);
  event LockedFunds(address indexed target, uint256 locked);
  event Burn(address indexed burner, uint256 value);

  function CLIP() public {
      balanceOf[msg.sender] = totalSupply;
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

  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balanceOf[_owner];
  }
    
    
  modifier onlyPayloadSize(uint256 size){
    assert(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    if(isContract(_to)) {
        if (balanceOf[msg.sender] < _value) revert();
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }


   
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

   
   
  function transfer(address _to, uint _value) public returns (bool success) {
    require(_value > 0
            && frozenAccount[msg.sender] == false
            && frozenAccount[_to] == false
            && now > unlockUnixTime[msg.sender]
            && now > unlockUnixTime[_to]);

     
     
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
    if (balanceOf[msg.sender] < _value) revert();
    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf[msg.sender] < _value) revert();
    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
    balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length > 0);

    for (uint i = 0; i < targets.length; i++) {
      require(targets[i] != 0x0);
      frozenAccount[targets[i]] = isFrozen;
      FrozenFunds(targets[i], isFrozen);
    }
  }

   
  function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
    require(targets.length > 0
            && targets.length == unixTimes.length);

    for(uint i = 0; i < targets.length; i++){
      require(unlockUnixTime[targets[i]] < unixTimes[i]);
      unlockUnixTime[targets[i]] = unixTimes[i];
      LockedFunds(targets[i], unixTimes[i]);
    }
  }

   
  function burn(address _from, uint256 _unitAmount) onlyOwner public {
    require(_unitAmount > 0
            && balanceOf[_from] >= _unitAmount);

    balanceOf[_from] = SafeMath.sub(balanceOf[_from], _unitAmount);
    totalSupply = SafeMath.sub(totalSupply, _unitAmount);
    Burn(_from, _unitAmount);
  }

     
    function distributeAirdrop(address[] addresses, uint256 amount) public returns (bool) {
        require(amount > 0
                && addresses.length > 0
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        amount = amount.mul(1e8);
        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);

        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != 0x0
                    && frozenAccount[addresses[i]] == false
                    && now > unlockUnixTime[addresses[i]]);

            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amount);
            Transfer(msg.sender, addresses[i], amount);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function distributeToken(address[] addresses, uint[] amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0
                    && addresses[i] != 0x0
                    && frozenAccount[addresses[i]] == false
                    && now > unlockUnixTime[addresses[i]]);

            amounts[i] = amounts[i].mul(1e8);
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(balanceOf[msg.sender] >= totalAmount);

        for (i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amounts[i]);
            Transfer(msg.sender, addresses[i], amounts[i]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }
  
   
  function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
    require(addresses.length > 0
            && addresses.length == amounts.length);

    uint256 totalAmount = 0;

    for (uint i = 0; i < addresses.length; i++) {
      require(amounts[i] > 0
              && addresses[i] != 0x0
              && frozenAccount[addresses[i]] == false
              && now > unlockUnixTime[addresses[i]]);

      amounts[i] = SafeMath.mul(amounts[i], 1e8);
      require(balanceOf[addresses[i]] >= amounts[i]);
      balanceOf[addresses[i]] = SafeMath.sub(balanceOf[addresses[i]], amounts[i]);
      totalAmount = SafeMath.add(totalAmount, amounts[i]);
      Transfer(addresses[i], msg.sender, amounts[i]);
    }
    balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], totalAmount);
    return true;
  }

  function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
    distributeAmount = _unitAmount;
  }

   
  function autoDistribute() payable public {
    require(distributeAmount > 0
            && balanceOf[owner] >= distributeAmount
            && frozenAccount[msg.sender] == false
            && now > unlockUnixTime[msg.sender]);
    if (msg.value > 0) owner.transfer(msg.value);

    balanceOf[owner] = SafeMath.sub(balanceOf[owner], distributeAmount);
    balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], distributeAmount);
    Transfer(owner, msg.sender, distributeAmount);
  }

   
  function() payable public {
    autoDistribute();
  }
}