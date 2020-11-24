 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract PreSignedContract is Ownable {
  mapping (uint8 => bytes) internal _prefixPreSignedFirst;
  mapping (uint8 => bytes) internal _prefixPreSignedSecond;

  function upgradePrefixPreSignedFirst(uint8 _version, bytes _prefix) public onlyOwner {
    _prefixPreSignedFirst[_version] = _prefix;
  }

  function upgradePrefixPreSignedSecond(uint8 _version, bytes _prefix) public onlyOwner {
    _prefixPreSignedSecond[_version] = _prefix;
  }

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

  function messagePreSignedHashing(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version
  ) public view returns (bytes32 hash) {
    if (_version <= 2) {
      hash = keccak256(
        _mode,
        _token,
        _to,
        _value,
        _fee,
        _nonce
      );
    } else {
       
      hash = keccak256(
        _prefixPreSignedFirst[_version],
        _mode,
        _token,
        _to,
        _value,
        _fee,
        _nonce
      );
    }
  }

  function preSignedHashing(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version
  ) public view returns (bytes32) {
    bytes32 hash = messagePreSignedHashing(
      _mode,
      _token,
      _to,
      _value,
      _fee,
      _nonce,
      _version
    );

    if (_version <= 2) {
      if (_version == 0) {
        return hash;
      } else if (_version == 1) {
        return keccak256(
          '\x19Ethereum Signed Message:\n32',
          hash
        );
      } else {
         
        return keccak256(
          '\x19Ethereum Signed Message:\n\x20',
          hash
        );
      }
    } else {
       
      if (_prefixPreSignedSecond[_version].length > 0) {
        return keccak256(
          _prefixPreSignedSecond[_version],
          hash
        );
      } else {
        return hash;
      }
    }
  }

  function preSignedCheck(
    bytes8 _mode,
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) public view returns (address) {
    bytes32 hash = preSignedHashing(
      _mode,
      _token,
      _to,
      _value,
      _fee,
      _nonce,
      _version
    );

    address _from = recover(hash, _sig);
    require(_from != address(0));

    return _from;
  }

  function transferPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck('Transfer', _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function approvePreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck('Approval', _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function increaseApprovalPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck('IncApprv', _token, _to, _value, _fee, _nonce, _version, _sig);
  }

  function decreaseApprovalPreSignedCheck(
    address _token,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  ) external view returns (address) {
    return preSignedCheck('DecApprv', _token, _to, _value, _fee, _nonce, _version, _sig);
  }
}

 

contract MuzikaCoin is MintableToken, Pausable {
  string public name = 'MUZIKA COIN';
  string public symbol = 'MZK';
  uint8 public decimals = 18;

  event Burn(address indexed burner, uint256 value);

  event FreezeAddress(address indexed target);
  event UnfreezeAddress(address indexed target);

  event TransferPreSigned(
    address indexed from,
    address indexed to,
    address indexed delegate,
    uint256 value,
    uint256 fee
  );
  event ApprovalPreSigned(
    address indexed owner,
    address indexed spender,
    address indexed delegate,
    uint256 value,
    uint256 fee
  );

  mapping (address => bool) public frozenAddress;

  mapping (bytes => bool) internal _signatures;

  PreSignedContract internal _preSignedContract = PreSignedContract(0xE55b5f4fAd5cD3923C392e736F58dEF35d7657b8);

  modifier onlyNotFrozenAddress(address _target) {
    require(!frozenAddress[_target]);
    _;
  }

  modifier onlyFrozenAddress(address _target) {
    require(frozenAddress[_target]);
    _;
  }

  constructor(uint256 initialSupply) public {
    totalSupply_ = initialSupply;
    balances[msg.sender] = initialSupply;
    emit Transfer(address(0), msg.sender, initialSupply);
  }

   
  function freezeAddress(address _target)
    public
    onlyOwner
    onlyNotFrozenAddress(_target)
  {
    frozenAddress[_target] = true;

    emit FreezeAddress(_target);
  }

   
  function unfreezeAddress(address _target)
    public
    onlyOwner
    onlyFrozenAddress(_target)
  {
    delete frozenAddress[_target];

    emit UnfreezeAddress(_target);
  }

   
  function burn(uint256 _value) public onlyOwner {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

  function transfer(
    address _to,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(_from)
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function transferPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.transferPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );
    require(!frozenAddress[_from]);

    uint256 _burden = _value.add(_fee);
    require(_burden <= balances[_from]);

    balances[_from] = balances[_from].sub(_burden);
    balances[_to] = balances[_to].add(_value);
    balances[msg.sender] = balances[msg.sender].add(_fee);
    emit Transfer(_from, _to, _value);
    emit Transfer(_from, msg.sender, _fee);

    _signatures[_sig] = true;
    emit TransferPreSigned(_from, _to, msg.sender, _value, _fee);

    return true;
  }

  function approvePreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.approvePreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );

    require(!frozenAddress[_from]);
    require(_fee <= balances[_from]);

    allowed[_from][_to] = _value;
    emit Approval(_from, _to, _value);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, _value, _fee);

    return true;
  }

  function increaseApprovalPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.increaseApprovalPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );

    require(!frozenAddress[_from]);
    require(_fee <= balances[_from]);

    allowed[_from][_to] = allowed[_from][_to].add(_value);
    emit Approval(_from, _to, allowed[_from][_to]);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, allowed[_from][_to], _fee);

    return true;
  }

  function decreaseApprovalPreSigned(
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    uint8 _version,
    bytes _sig
  )
    public
    onlyNotFrozenAddress(msg.sender)
    whenNotPaused
    returns (bool)
  {
    require(_signatures[_sig] == false);

    address _from = _preSignedContract.decreaseApprovalPreSignedCheck(
      address(this),
      _to,
      _value,
      _fee,
      _nonce,
      _version,
      _sig
    );
    require(!frozenAddress[_from]);

    require(_fee <= balances[_from]);

    uint256 oldValue = allowed[_from][_to];
    if (_value > oldValue) {
      oldValue = 0;
    } else {
      oldValue = oldValue.sub(_value);
    }

    allowed[_from][_to] = oldValue;
    emit Approval(_from, _to, oldValue);

    if (_fee > 0) {
      balances[_from] = balances[_from].sub(_fee);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      emit Transfer(_from, msg.sender, _fee);
    }

    _signatures[_sig] = true;
    emit ApprovalPreSigned(_from, _to, msg.sender, oldValue, _fee);

    return true;
  }
}