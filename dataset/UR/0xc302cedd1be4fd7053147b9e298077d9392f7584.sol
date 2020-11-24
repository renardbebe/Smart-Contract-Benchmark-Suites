 

pragma solidity ^0.4.18;
pragma solidity ^0.4.18;


 
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
pragma solidity ^0.4.18;

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract Bob {
  using SafeMath for uint;

  enum DepositState {
    Uninitialized,
    BobMadeDeposit,
    AliceClaimedDeposit,
    BobClaimedDeposit
  }

  enum PaymentState {
    Uninitialized,
    BobMadePayment,
    AliceClaimedPayment,
    BobClaimedPayment
  }

  struct BobDeposit {
    bytes20 depositHash;
    uint64 lockTime;
    DepositState state;
  }

  struct BobPayment {
    bytes20 paymentHash;
    uint64 lockTime;
    PaymentState state;
  }

  mapping (bytes32 => BobDeposit) public deposits;

  mapping (bytes32 => BobPayment) public payments;

  function Bob() public {
  }

  function bobMakesEthDeposit(
    bytes32 _txId,
    address _alice,
    bytes20 _secretHash,
    uint64 _lockTime
  ) external payable {
    require(_alice != 0x0 && msg.value > 0 && deposits[_txId].state == DepositState.Uninitialized);
    bytes20 depositHash = ripemd160(
      _alice,
      msg.sender,
      _secretHash,
      address(0),
      msg.value
    );
    deposits[_txId] = BobDeposit(
      depositHash,
      _lockTime,
      DepositState.BobMadeDeposit
    );
  }

  function bobMakesErc20Deposit(
    bytes32 _txId,
    uint256 _amount,
    address _alice,
    bytes20 _secretHash,
    address _tokenAddress,
    uint64 _lockTime
  ) external {
    bytes20 depositHash = ripemd160(
      _alice,
      msg.sender,
      _secretHash,
      _tokenAddress,
      _amount
    );
    deposits[_txId] = BobDeposit(
      depositHash,
      _lockTime,
      DepositState.BobMadeDeposit
    );
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transferFrom(msg.sender, address(this), _amount));
  }

  function bobClaimsDeposit(
    bytes32 _txId,
    uint256 _amount,
    bytes32 _secret,
    address _alice,
    address _tokenAddress
  ) external {
    require(deposits[_txId].state == DepositState.BobMadeDeposit);
    bytes20 depositHash = ripemd160(
      _alice,
      msg.sender,
      ripemd160(sha256(_secret)),
      _tokenAddress,
      _amount
    );
    require(depositHash == deposits[_txId].depositHash && now < deposits[_txId].lockTime);
    deposits[_txId].state = DepositState.BobClaimedDeposit;
    if (_tokenAddress == 0x0) {
      msg.sender.transfer(_amount);
    } else {
      ERC20 token = ERC20(_tokenAddress);
      assert(token.transfer(msg.sender, _amount));
    }
  }

  function aliceClaimsDeposit(
    bytes32 _txId,
    uint256 _amount,
    address _bob,
    address _tokenAddress,
    bytes20 _secretHash
  ) external {
    require(deposits[_txId].state == DepositState.BobMadeDeposit);
    bytes20 depositHash = ripemd160(
      msg.sender,
      _bob,
      _secretHash,
      _tokenAddress,
      _amount
    );
    require(depositHash == deposits[_txId].depositHash && now >= deposits[_txId].lockTime);
    deposits[_txId].state = DepositState.AliceClaimedDeposit;
    if (_tokenAddress == 0x0) {
      msg.sender.transfer(_amount);
    } else {
      ERC20 token = ERC20(_tokenAddress);
      assert(token.transfer(msg.sender, _amount));
    }
  }

  function bobMakesEthPayment(
    bytes32 _txId,
    address _alice,
    bytes20 _secretHash,
    uint64 _lockTime
  ) external payable {
    require(_alice != 0x0 && msg.value > 0 && payments[_txId].state == PaymentState.Uninitialized);
    bytes20 paymentHash = ripemd160(
      _alice,
      msg.sender,
      _secretHash,
      address(0),
      msg.value
    );
    payments[_txId] = BobPayment(
      paymentHash,
      _lockTime,
      PaymentState.BobMadePayment
    );
  }

  function bobMakesErc20Payment(
    bytes32 _txId,
    uint256 _amount,
    address _alice,
    bytes20 _secretHash,
    address _tokenAddress,
    uint64 _lockTime
  ) external {
    require(
      _alice != 0x0 &&
      _amount > 0 &&
      payments[_txId].state == PaymentState.Uninitialized &&
      _tokenAddress != 0x0
    );
    bytes20 paymentHash = ripemd160(
      _alice,
      msg.sender,
      _secretHash,
      _tokenAddress,
      _amount
    );
    payments[_txId] = BobPayment(
      paymentHash,
      _lockTime,
      PaymentState.BobMadePayment
    );
    ERC20 token = ERC20(_tokenAddress);
    assert(token.transferFrom(msg.sender, address(this), _amount));
  }

  function bobClaimsPayment(
    bytes32 _txId,
    uint256 _amount,
    address _alice,
    address _tokenAddress,
    bytes20 _secretHash
  ) external {
    require(payments[_txId].state == PaymentState.BobMadePayment);
    bytes20 paymentHash = ripemd160(
      _alice,
      msg.sender,
      _secretHash,
      _tokenAddress,
      _amount
    );
    require(now >= payments[_txId].lockTime && paymentHash == payments[_txId].paymentHash);
    payments[_txId].state = PaymentState.BobClaimedPayment;
    if (_tokenAddress == 0x0) {
      msg.sender.transfer(_amount);
    } else {
      ERC20 token = ERC20(_tokenAddress);
      assert(token.transfer(msg.sender, _amount));
    }
  }

  function aliceClaimsPayment(
    bytes32 _txId,
    uint256 _amount,
    bytes32 _secret,
    address _bob,
    address _tokenAddress
  ) external {
    require(payments[_txId].state == PaymentState.BobMadePayment);
    bytes20 paymentHash = ripemd160(
      msg.sender,
      _bob,
      ripemd160(sha256(_secret)),
      _tokenAddress,
      _amount
    );
    require(now < payments[_txId].lockTime && paymentHash == payments[_txId].paymentHash);
    payments[_txId].state = PaymentState.AliceClaimedPayment;
    if (_tokenAddress == 0x0) {
      msg.sender.transfer(_amount);
    } else {
      ERC20 token = ERC20(_tokenAddress);
      assert(token.transfer(msg.sender, _amount));
    }
  }
}