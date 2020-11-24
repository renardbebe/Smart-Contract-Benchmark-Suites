 

pragma solidity ^0.4.24;

 

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
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

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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

 

contract KoreanLiberationDayToken is StandardToken, Ownable {
  string public constant name = "Token to commemorate the 73th Korean Liberation Day";
  string public constant symbol = "815";
  uint8 public constant decimals = 0;
  uint16 internal constant TOTAL_SUPPLY = 815;

  mapping (uint16 => address) internal tokenIndexToOwner;

  bytes32[TOTAL_SUPPLY] tokens;

  event changeOwnerShip(address _from, address _to, uint16 indexed _tokenId);

  constructor() public {
    totalSupply_ = 0;
    balances[owner] = totalSupply_;
    emit Transfer(address(0), owner, totalSupply_);
  }

  function _firstTokenId(address _owner) private view returns(uint16) {
    require(balanceOf(_owner) > 0);
    for (uint16 tokenId = 0; tokenId < totalSupply(); tokenId++) {
      if (this.ownerOf(tokenId) == _owner) {
        return tokenId;
      }
    }
  }

  function _bytes32ToString(bytes32 x) private pure returns(string) {
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

  function speech(uint16 tokenId) public view returns(string) {
      return _bytes32ToString(tokens[tokenId]);
  }

  function createTokens(bytes32[] _tokens) public onlyOwner {
      require(_tokens.length > 0);
      require(totalSupply_ + _tokens.length <= TOTAL_SUPPLY);
      for (uint16 i = 0; i < _tokens.length; i++) {
          tokens[totalSupply_++] = _tokens[i];
          balances[owner]++;
      }
  }

  function transferTokenOwnership(address _from, address _to, uint16 _tokenId) public returns(bool) {
    require(_from != address(0));
    require(_to != address(0));
    require(balanceOf(_from) > 0);

    tokenIndexToOwner[_tokenId] = _to;
    emit changeOwnerShip(_from, _to, _tokenId);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns(bool) {
    require(balanceOf(msg.sender) >= _value);
    for (uint16 i = 0; i < _value; i++) {
      transferTokenOwnership(msg.sender, _to, _firstTokenId(msg.sender));
      super.transfer(_to, 1);
    }
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    require(balanceOf(_from) >= _value);
    for (uint16 i = 0; i < _value; i++) {
      transferTokenOwnership(_from, _to, _firstTokenId(_from));
      super.transferFrom(_from, _to, 1);
    }
    return true;
  }

  function transferBatch(address [] _to) public returns(bool) {
    require(_to.length > 0);
    require(balanceOf(msg.sender) >= _to.length);

    for (uint16 i = 0; i < _to.length; i++) {
      transferTokenOwnership(msg.sender, _to[i], _firstTokenId(msg.sender));
      super.transfer(_to[i], 1);
    }
    return true;
  }

  function approveBatch(address [] _to) public returns(bool) {
    require(_to.length > 0);
    require(balanceOf(msg.sender) >= _to.length);
    for (uint16 i = 0; i < _to.length; i++) {
      allowed[msg.sender][_to[i]] = 1;
      emit Approval(msg.sender, _to[i], 1);
    }
    return true;
  }

  function ownerOf(uint16 _tokenId) external view returns(address tokenOwner) {
    require(_tokenId < totalSupply());
    tokenOwner = tokenIndexToOwner[_tokenId];
    if (tokenOwner == address(0)) {
        return owner;
    }
  }

  function tokensOfOwner(address _owner) external view returns(uint16[]) {
    uint256 tokenCount = balanceOf(_owner);
    uint16 idx = 0;

    if (tokenCount == 0) {
      return new uint16[](0);
    } else {
      uint16[] memory result = new uint16[](tokenCount);
      for(uint16 tokenId = 0; tokenId < totalSupply(); tokenId++) {
        if (this.ownerOf(tokenId) == _owner) {
          result[idx++] = tokenId;
        }
      }
    }

    return result;
  }

  function speechOfOwner(address _owner) external view returns(bytes32[]) {
    uint256 tokenCount = balanceOf(_owner);
    uint16 idx = 0;

    if (tokenCount == 0) {
      return new bytes32[](0);
    } else {
      bytes32[] memory result = new bytes32[](tokenCount);
      for(uint16 tokenId = 0; tokenId < totalSupply(); tokenId++) {
        if (this.ownerOf(tokenId) == _owner) {
          result[idx++] = tokens[tokenId];
        }
      }
    }

    return result;
  }
}