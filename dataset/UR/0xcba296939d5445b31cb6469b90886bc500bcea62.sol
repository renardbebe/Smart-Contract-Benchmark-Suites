 

pragma solidity >=0.4.22 <0.6.0;

contract NowTees {

  uint256 public _maxNowTeeSets;
  address payable public _owner;
  uint256 public _nowTeeSetPrice;
   
  mapping(address => uint256) public _nowTeeKeys;
  mapping(uint256 => NowTeeSet) public _nowTeeSets;
  uint256 public _soldSets;

  event NewNowTeeSet(uint256 setID);

  struct NowTeeSet {
    address firstKey;
    address secondKey;
    address thirdKey;
  }

  constructor(address payable owner, uint256 nowTeeSetPrice, uint256 maxNowTeeSets) public {
    _owner = owner;
    _nowTeeSetPrice = nowTeeSetPrice;
    _maxNowTeeSets = maxNowTeeSets;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

  function changeOwner(address payable newOwner) public onlyOwner() {
    require(newOwner != address(0));
    _owner = newOwner;
  }

  function changePriceForNowTeeSet(uint256 newPrice) public onlyOwner() {

     
    _nowTeeSetPrice = newPrice;

  }

  function soldSets() view public returns (uint256) {
    return _soldSets;
  }

  function nowTeeSetByKey(address key) view public returns (address, address, address) {
    NowTeeSet memory set = _nowTeeSets[_nowTeeKeys[key]];
    return (set.firstKey, set.secondKey, set.thirdKey);
  }

  function isValidNowTeeKey(address key) view public returns (bool) {
    return _nowTeeKeys[key] != 0;
  }

  function allocateKey(address key, uint256 set) internal {
     
    require(key != address (0));
     
    require(_nowTeeKeys[key] == 0);
    _nowTeeKeys[key] = set;
  }

  function buySet(address firstKey, address secondKey, address thirdKey) payable public {

     
    require(msg.value >= _nowTeeSetPrice);
    _owner.transfer(address(this).balance);

     
    _soldSets += 1;
    require(_soldSets <= _maxNowTeeSets);

     
    NowTeeSet memory keySet = NowTeeSet(firstKey, secondKey, thirdKey);
    _nowTeeSets[_soldSets] = keySet;
    emit NewNowTeeSet(_soldSets);

     
    allocateKey(firstKey, _soldSets);
    allocateKey(secondKey, _soldSets);
    allocateKey(thirdKey, _soldSets);

  }

}