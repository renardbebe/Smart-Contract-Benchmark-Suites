 

 

contract DVIP {
  function transfer(address to, uint256 value) returns (bool success);
}

contract Assertive {
  function assert(bool assertion) {
    if (!assertion) throw;
  }
}

contract Math is Assertive {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Owned is Assertive {
  address public owner;
  event SetOwner(address indexed previousOwner, address indexed newOwner);
  function Owned () {
    owner = msg.sender;
  }
  modifier onlyOwner {
    assert(msg.sender == owner);
    _
  }
  function setOwner(address newOwner) onlyOwner {
    SetOwner(owner, newOwner);
    owner = newOwner;
  }
}

contract MembershipVendor is Owned, Math {
  event MembershipPurchase(address indexed from, uint256 indexed amount, uint256 indexed price);
  event PropertySet(address indexed from, bytes32 indexed sig, bytes32 indexed args);
  address public dvipAddress;
  address public beneficiary;
  uint256 public price;
  string public tos;
  string[] public terms;
  function setToS(string _tos) onlyOwner returns (bool success) {
    tos = _tos;
    PropertySet(msg.sender, msg.sig, sha3(tos));
    return true;
  }
  function pushTerm(string term) onlyOwner returns (bool success) {
    terms.push(term);
    PropertySet(msg.sender, msg.sig, sha3(term));
    return true;
  }
  function setTerm(uint256 idx, string term) onlyOwner returns (bool success) {
    terms[idx] = term;
    PropertySet(msg.sender, msg.sig, sha3(idx, term));
    return true;
  }
  function setBeneficiary(address addr) onlyOwner returns (bool success) {
    beneficiary = addr;
    PropertySet(msg.sender, msg.sig, bytes32(addr));
    return true;
  }
  function withdraw(address addr, uint256 amt) onlyOwner returns (bool success) {
    if (!addr.send(amt)) throw;
    return true;
  }
  function setDVIP(address addr) onlyOwner returns (bool success) {
    dvipAddress = addr;
    PropertySet(msg.sender, msg.sig, bytes32(addr));
    return true;
  }
  function setPrice(uint256 _price) onlyOwner returns (bool success) {
    price = _price;
    PropertySet(msg.sender, msg.sig, bytes32(_price));
    return true;
  }
  function () {
    if (msg.value < price) throw;
    uint256 qty = msg.value / price;
    uint256 val = safeMul(price, qty);
    if (!DVIP(dvipAddress).transfer(msg.sender, qty)) throw;
    if (msg.value > val && !msg.sender.send(safeSub(msg.value, val))) throw;
    if (beneficiary != address(0x0) && !beneficiary.send(val)) throw;
  }
}