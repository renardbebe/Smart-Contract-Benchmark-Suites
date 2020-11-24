 

pragma solidity ^0.4.18;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Announceable is Ownable {

  string public announcement;

  function setAnnouncement(string value) public onlyOwner {
    announcement = value;
  }

}

contract Withdrawable {

  address public withdrawOwner;

  function Withdrawable(address _withdrawOwner) public {
    require(_withdrawOwner != address(0));
    withdrawOwner = _withdrawOwner;
  }

   
  function withdraw() public {
    withdrawTo(msg.sender, this.balance);
  }

   
  function withdrawTo(address _beneficiary, uint _amount) public {
    require(msg.sender == withdrawOwner);
    require(_beneficiary != address(0));
    require(_amount > 0);
    _beneficiary.transfer(_amount);
  }

   
  function setWithdrawOwner(address _newOwner) public {
    require(msg.sender == withdrawOwner);
    require(_newOwner != address(0));
    withdrawOwner = _newOwner;
  }

}

contract Cryptoverse is StandardToken, Ownable, Announceable, Withdrawable {
  using SafeMath for uint;

  string public constant name = "Cryptoverse Sector";
  string public constant symbol = "CVS";
  uint8 public constant decimals = 0;

   
  event SectorUpdated(
    uint16 indexed offset,
    address indexed owner,
    string link,
    string content,
    string title,
    bool nsfw
  );

   
  struct Sector {
    address owner;
    string link;
    string content;
    string title;
    bool nsfw;
    bool forceNsfw;
  }

   
  uint public lastPurchaseTimestamp = now;

   
  bool public allowClaiming = true;

   
  uint[13] public prices = [1000 finney, 800 finney, 650 finney, 550 finney, 500 finney, 450 finney, 400 finney, 350 finney, 300 finney, 250 finney, 200 finney, 150 finney, 100 finney];

  uint8 public constant width = 125;
  uint8 public constant height = 80;
  uint16 public constant length = 10000;

   
  Sector[10000] public grid;

  function Cryptoverse() Withdrawable(msg.sender) public { }

  function () public payable {
     
     
    uint sectorCount = msg.value / 1000 finney;
    require(sectorCount > 0);

     
    Transfer(address(0), msg.sender, sectorCount);

     
    for (uint16 offset = 0; offset < length; offset++) {
      Sector storage sector = grid[offset];

      if (sector.owner == address(0)) {
         
        setSectorOwnerInternal(offset, msg.sender, false);
        sectorCount--;

        if (sectorCount == 0) {
          return;
        }
      }
    }

     
    revert();
  }

   
  function buy(uint16[] memory _offsets) public payable {
    require(_offsets.length > 0);
    uint cost = _offsets.length * currentPrice();
    require(msg.value >= cost);

     
    Transfer(address(0), msg.sender, _offsets.length);

    for (uint i = 0; i < _offsets.length; i++) {
      setSectorOwnerInternal(_offsets[i], msg.sender, false);
    }
  }

   
  function transfer(address _to, uint _value) public returns (bool result) {
    result = super.transfer(_to, _value);

    if (result && _value > 0) {
      transferSectorOwnerInternal(_value, msg.sender, _to);
    }
  }

   
  function transferFrom(address _from, address _to, uint _value) public returns (bool result) {
    result = super.transferFrom(_from, _to, _value);

    if (result && _value > 0) {
      transferSectorOwnerInternal(_value, _from, _to);
    }
  }

   
  function transferSectors(uint16[] memory _offsets, address _to) public returns (bool result) {
    result = super.transfer(_to, _offsets.length);

    if (result) {
      for (uint i = 0; i < _offsets.length; i++) {
        Sector storage sector = grid[_offsets[i]];
        require(sector.owner == msg.sender);
        setSectorOwnerInternal(_offsets[i], _to, true);
      }
    }
  }

   
  function set(uint16[] memory _offsets, string _link, string _content, string _title, bool _nsfw) public {
    require(_offsets.length > 0);
    for (uint i = 0; i < _offsets.length; i++) {
      Sector storage sector = grid[_offsets[i]];
      require(msg.sender == sector.owner);

      sector.link = _link;
      sector.content = _content;
      sector.title = _title;
      sector.nsfw = _nsfw;

      onUpdatedInternal(_offsets[i], sector);
    }
  }

   
  function setSectorOwnerInternal(uint16 _offset, address _to, bool _canTransfer) internal {
    require(_to != address(0));

     
    Sector storage sector = grid[_offset];

     
    address from = sector.owner;
    bool isTransfer = (from != address(0));
    require(_canTransfer || !isTransfer);

     
    sector.owner = _to;

     
    if (!isTransfer) {
       
      totalSupply = totalSupply.add(1);
      balances[_to] = balances[_to].add(1);
      lastPurchaseTimestamp = now;
    }

    onUpdatedInternal(_offset, sector);
  }

   
  function transferSectorOwnerInternal(uint _value, address _from, address _to) internal {
    require(_value > 0);
    require(_from != address(0));
    require(_to != address(0));

    uint sectorCount = _value;

    for (uint16 offsetPlusOne = length; offsetPlusOne > 0; offsetPlusOne--) {
      Sector storage sector = grid[offsetPlusOne - 1];

      if (sector.owner == _from) {
        setSectorOwnerInternal(offsetPlusOne - 1, _to, true);
        sectorCount--;

        if (sectorCount == 0) {
           
          return;
        }
      }
    }

     
    revert();
  }

  function setForceNsfw(uint16[] memory _offsets, bool _nsfw) public onlyOwner {
    require(_offsets.length > 0);
    for (uint i = 0; i < _offsets.length; i++) {
      Sector storage sector = grid[_offsets[i]];
      sector.forceNsfw = _nsfw;

      onUpdatedInternal(_offsets[i], sector);
    }
  }

   
  function currentPrice() public view returns (uint) {
    uint sinceLastPurchase = (block.timestamp - lastPurchaseTimestamp);

    for (uint i = 0; i < prices.length - 1; i++) {
      if (sinceLastPurchase < (i + 1) * 1 days) {
        return prices[i];
      }
    }

    return prices[prices.length - 1];
  }

  function transform(uint8 _x, uint8 _y) public pure returns (uint16) {
    uint16 offset = _y;
    offset = offset * width;
    offset = offset + _x;
    return offset;
  }

  function untransform(uint16 _offset) public pure returns (uint8, uint8) {
    uint8 y = uint8(_offset / width);
    uint8 x = uint8(_offset - y * width);
    return (x, y);
  }

  function claimA() public { claimInternal(60, 37, 5, 5); }
  function claimB1() public { claimInternal(0, 0, 62, 1); }
  function claimB2() public { claimInternal(62, 0, 63, 1); }
  function claimC1() public { claimInternal(0, 79, 62, 1); }
  function claimC2() public { claimInternal(62, 79, 63, 1); }
  function claimD() public { claimInternal(0, 1, 1, 78); }
  function claimE() public { claimInternal(124, 1, 1, 78); }
  function claimF() public { claimInternal(20, 20, 8, 8); }
  function claimG() public { claimInternal(45, 10, 6, 10); }
  function claimH1() public { claimInternal(90, 50, 8, 10); }
  function claimH2() public { claimInternal(98, 50, 7, 10); }
  function claimI() public { claimInternal(94, 22, 7, 7); }
  function claimJ() public { claimInternal(48, 59, 12, 8); }

   
  function closeClaims() public onlyOwner {
    allowClaiming = false;
  }

  function claimInternal(uint8 _left, uint8 _top, uint8 _width, uint8 _height) internal {
    require(allowClaiming);

     
    uint8 _right = _left + _width;
    uint8 _bottom = _top + _height;

    uint area = _width;
    area = area * _height;
    Transfer(address(0), owner, area);

    for (uint8 x = _left; x < _right; x++) {
      for (uint8 y = _top; y < _bottom; y++) {
        setSectorOwnerInternal(transform(x, y), owner, false);
      }
    }
  }

   
  function onUpdatedInternal(uint16 _offset, Sector storage _sector) internal {
    SectorUpdated(
      _offset,
      _sector.owner,
      _sector.link,
      _sector.content,
      _sector.title,
      _sector.nsfw || _sector.forceNsfw
    );
  }

}