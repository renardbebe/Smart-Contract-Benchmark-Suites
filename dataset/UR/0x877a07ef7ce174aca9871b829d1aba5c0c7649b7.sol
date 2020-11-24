 

pragma solidity ^0.4.18;

 

 
interface IEscrow {

  event Created(
    address indexed sender,
    address indexed recipient,
    address indexed arbitrator,
    uint256 transactionId
  );
  event Released(address indexed arbitrator, address indexed sentTo, uint256 transactionId);
  event Dispute(address indexed arbitrator, uint256 transactionId);
  event Paid(address indexed arbitrator, uint256 transactionId);

  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public;

  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public;

}

 

 
interface ISendToken {
  function transfer(address to, uint256 value) public returns (bool);

  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
}

 

 
interface ISnapshotToken {
  function requestSnapshots(uint256 _blockNumber) public;
  function takeSnapshot(address _owner) public returns(uint256);
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 
contract SnapshotToken is ISnapshotToken, StandardToken, Ownable {
  uint256 public snapshotBlock;

  mapping (address => Snapshot) internal snapshots;

  struct Snapshot {
    uint256 block;
    uint256 balance;
  }

  address public polls;

  modifier isPolls() {
    require(msg.sender == address(polls));
    _;
  }

   
  function setPolls(address _address) public onlyOwner {
    polls = _address;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    takeSnapshot(msg.sender);
    takeSnapshot(_to);
    return BasicToken.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    takeSnapshot(_from);
    takeSnapshot(_to);
    return StandardToken.transferFrom(_from, _to, _value);
  }

   
  function takeSnapshot(address _owner) public returns(uint256) {
    if (snapshots[_owner].block < snapshotBlock) {
      snapshots[_owner].block = snapshotBlock;
      snapshots[_owner].balance = balanceOf(_owner);
    }
    return snapshots[_owner].balance;
  }

   
  function requestSnapshots(uint256 _blockNumber) public isPolls {
    snapshotBlock = _blockNumber;
  }
}

 

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

 
contract SendToken is ISendToken, SnapshotToken, BurnableToken {
  IEscrow public escrow;

  mapping (address => bool) internal verifiedAddresses;

  modifier verifiedResticted() {
    require(verifiedAddresses[msg.sender]);
    _;
  }

  modifier escrowResticted() {
    require(msg.sender == address(escrow));
    _;
  }

   
  function isVerified(address _address) public view returns(bool) {
    return verifiedAddresses[_address];
  }

   
  function verify(address _address) public onlyOwner {
    verifiedAddresses[_address] = true;
  }

   
  function unverify(address _address) public onlyOwner {
    verifiedAddresses[_address] = false;
  }

   
  function setEscrow(address _address) public onlyOwner {
    escrow = IEscrow(_address);
  }

   
  function verifiedTransferFrom(
      address _from,
      address _to,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate,
      uint256 _fee
  ) public verifiedResticted {
    require(_exchangeRate > 0);

    transferFrom(_from, _to, _value);
    transferFrom(_from, msg.sender, _fee);

    VerifiedTransfer(
      _from,
      _to,
      msg.sender,
      _value,
      _referenceId,
      _exchangeRate
    );
  }

   
  function createEscrow(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public {
    escrow.create(
      _sender,
      _recipient,
      msg.sender,
      _transactionId,
      _tokens,
      _fee,
      _expiration
    );
  }

   
  function fundEscrow(
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public {
    uint256 total = _tokens.add(_fee);
    transfer(escrow, total);

    escrow.fund(
      msg.sender,
      _arbitrator,
      _transactionId,
      _tokens,
      _fee
    );
  }

   
  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public escrowResticted {
    bool noRate = (_exchangeRate == 0);
    if (isVerified(_verifiedAddress)) {
      require(!noRate);
      VerifiedTransfer(
        _from,
        _to,
        _verifiedAddress,
        _value,
        _transactionId,
        _exchangeRate
      );
    } else {
      require(noRate);
    }
  }
}

 

 
contract SDT is SendToken {
  string constant public name = "SEND Token";
  string constant public symbol = "SDT";
  uint256 constant public decimals = 18;

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

   
  function SDT(address _sale) public validAddress(_sale) {
    verifiedAddresses[owner] = true;
    totalSupply = 700000000 * 10 ** decimals;
    balances[_sale] = totalSupply;
  }
}