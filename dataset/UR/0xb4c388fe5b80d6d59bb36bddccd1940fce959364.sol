 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
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


 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
  }
}


contract IERC223Basic {
  function balanceOf(address _owner) public constant returns (uint);
  function transfer(address _to, uint _value) public;
  function transfer(address _to, uint _value, bytes _data) public;
  event Transfer(
    address indexed from,
    address indexed to,
    uint value,
    bytes data
  );
}


contract IERC223 is IERC223Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint);

  function transferFrom(address _from, address _to, uint _value, bytes _data)
    public;

  function approve(address _spender, uint _value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract IERC223BasicReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}


contract IERC223Receiver is IERC223BasicReceiver {
  function receiveApproval(address _owner, uint _value) public;
}


 
contract ERC223BasicReceiver is IERC223BasicReceiver {
  event TokensReceived(address sender, address origin, uint value, bytes data);

   
  function tokenFallback(address _from, uint _value, bytes _data) public {
    require(_from != address(0));
    emit TokensReceived(msg.sender, _from, _value, _data);
  }
}


 
contract ERC223Receiver is ERC223BasicReceiver, IERC223Receiver {
  event ApprovalReceived(address sender, address owner, uint value);

   
  function receiveApproval(address _owner, uint _value) public {
    require(_owner != address(0));
    emit ApprovalReceived(msg.sender, _owner, _value);
  }
}


 
contract Fund is ERC223Receiver, Contactable {
  IERC223 public token;
  string public fundName;

   
  constructor(IERC223 _token, string _fundName) public {
    require(address(_token) != address(0));
    token = _token;
    fundName = _fundName;
  }

   
  function transfer(address _to, uint _value) public onlyOwner {
    token.transfer(_to, _value);
  }

   
  function transfer(address _to, uint _value, bytes _data) public onlyOwner {
    token.transfer(_to, _value, _data);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    public
    onlyOwner
  {
    token.transferFrom(_from, _to, _value, _data);
  }

   
  function approve(address _spender, uint _value) public onlyOwner {
    token.approve(_spender, _value);
  }
}


 
contract Hedpay is IERC223, Contactable {
  using AddressUtils for address;
  using SafeMath for uint;

  string public constant name = "HEdpAY";
  string public constant symbol = "Hdp.ф";
  uint8 public constant decimals = 4;
  uint8 public constant secondPhaseBonus = 33;
  uint8[3] public thirdPhaseBonus = [10, 15, 20];
  uint public constant totalSupply = 10000000000000;
  uint public constant secondPhaseStartTime = 1537401600;  
  uint public constant secondPhaseEndTime = 1540943999;  
  uint public constant thirdPhaseStartTime = 1540944000; 
  uint public constant thirdPhaseEndTime = 1543622399; 
  uint public constant cap = 200000 ether;
  uint public constant goal = 25000 ether;
  uint public constant rate = 100;
  uint public constant minimumWeiAmount = 100 finney;
  uint public constant salePercent = 14;
  uint public constant bonusPercent = 1;
  uint public constant teamPercent = 2;
  uint public constant preSalePercent = 3;

  uint public creationTime;
  uint public weiRaised;
  uint public tokensSold;
  uint public buyersCount;
  uint public saleAmount;
  uint public bonusAmount;
  uint public teamAmount;
  uint public preSaleAmount;
  uint public unsoldTokens;

  address public teamAddress = 0x7d4E738477B6e8BaF03c4CB4944446dA690f76B5;
  
  Fund public reservedFund;

  mapping (address => uint) internal balances;
  mapping (address => mapping (address => uint)) internal allowed;
  mapping (address => uint) internal bonuses;

   
  constructor() public {
    balances[owner] = totalSupply;
    creationTime = block.timestamp;
    saleAmount = totalSupply.div(100).mul(salePercent).mul(
      10 ** uint(decimals)
    );
    bonusAmount = totalSupply.div(100).mul(bonusPercent).mul(
      10 ** uint(decimals)
    );
    teamAmount = totalSupply.div(100).mul(teamPercent).mul(
      10 ** uint(decimals)
    );
    preSaleAmount = totalSupply.div(100).mul(preSalePercent).mul(
      10 ** uint(decimals)
    );
  }

   
  function balanceOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    return balances[_owner];
  }

   
  function allowance(address _owner, address _spender)
    public view returns (uint)
  {
    require(_owner != address(0));
    require(_spender != address(0));
    return allowed[_owner][_spender];
  }

   
  function hasStarted() public view returns (bool) {
    return block.timestamp >= secondPhaseStartTime;
  }

   
  function hasEnded() public view returns (bool) {
    return block.timestamp > thirdPhaseEndTime;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function getTokenAmount(uint _weiAmount) public pure returns (uint) {
    return _weiAmount.mul(rate).div((18 - uint(decimals)) ** 10);
  }

   
  function getTokenAmountBonus(uint _weiAmount)
    public view returns (uint)
  {
    if (hasStarted() && secondPhaseEndTime >= block.timestamp) {
      return(
        getTokenAmount(_weiAmount).
        add(
          getTokenAmount(_weiAmount).
          div(100).
          mul(uint(secondPhaseBonus))
        )
      );
    } else if (thirdPhaseStartTime <= block.timestamp && !hasEnded()) {
      if (_weiAmount > 0 && _weiAmount < 2500 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[0]))
          )
        );
      } else if (_weiAmount >= 2510 finney && _weiAmount < 10000 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[1]))
          )
        );
      } else if (_weiAmount >= 10000 finney) {
        return(
          getTokenAmount(_weiAmount).
          add(
            getTokenAmount(_weiAmount).
            div(100).
            mul(uint(thirdPhaseBonus[2]))
          )
        );
      }
    } else {
      return getTokenAmount(_weiAmount);
    }
  }

   
  function bonusOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    return bonuses[_owner];
  }

   
  function balanceWithoutFreezedBonus(address _owner)
    public view returns (uint)
  {
    require(_owner != address(0));
    if (block.timestamp >= thirdPhaseEndTime.add(90 days)) {
      if (bonusOf(_owner) < 10000) {
        return balanceOf(_owner);
      } else {
        return balanceOf(_owner).sub(bonuses[_owner].div(2));
      }
    } else if (block.timestamp >= thirdPhaseEndTime.add(180 days)) {
      return balanceOf(_owner);
    } else {
      return balanceOf(_owner).sub(bonuses[_owner]);
    }
  }

   
  function transfer(address _to, uint _value) public {
    transfer(_to, _value, "");
  }

   
  function transfer(address _to, uint _value, bytes _data) public {
    require(_value <= balanceWithoutFreezedBonus(msg.sender));
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    _safeTransfer(msg.sender, _to, _value, _data);

    emit Transfer(msg.sender, _to, _value, _data);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    public
  {
    require(_from != address(0));
    require(_to != address(0));
    require(_value <= allowance(_from, msg.sender));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _safeTransfer(_from, _to, _value, _data);

    emit Transfer(_from, _to, _value, _data);
    emit Approval(_from, msg.sender, allowance(_from, msg.sender));
  }

   
  function approve(address _spender, uint _value) public {
    require(_spender != address(0));
    require(_value <= balanceWithoutFreezedBonus(msg.sender));
    allowed[msg.sender][_spender] = _value;
    _safeApprove(_spender, _value);
    emit Approval(msg.sender, _spender, _value);
  }

   
  function increaseApproval(address _spender, uint _value) public {
    require(_spender != address(0));
    require(
      allowance(msg.sender, _spender).add(_value) <=
      balanceWithoutFreezedBonus(msg.sender)
    );

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
    _safeApprove(_spender, allowance(msg.sender, _spender));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
  }

   
  function decreaseApproval(address _spender, uint _value) public {
    require(_spender != address(0));
    require(_value <= allowance(msg.sender, _spender));
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
    _safeApprove(_spender, allowance(msg.sender, _spender));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
  }

   
  function setBonus(address _owner, uint _value, bool preSale)
    public onlyOwner
  {
    require(_owner != address(0));
    require(_value <= balanceOf(_owner));
    require(bonusAmount > 0);
    require(_value <= bonusAmount);

    bonuses[_owner] = _value;
    if (preSale) {
      preSaleAmount = preSaleAmount.sub(_value);
      transfer(_owner, _value, abi.encode("transfer the bonus"));
    } else {
      if (_value <= bonusAmount) {
        bonusAmount = bonusAmount.sub(_value);
        transfer(_owner, _value, abi.encode("transfer the bonus"));
      }
    }

  }

   
  function refill(address _to, uint _weiAmount) public onlyOwner {
    require(_preValidateRefill(_to, _weiAmount));
    setBonus(
      _to,
      getTokenAmountBonus(_weiAmount).sub(
        getTokenAmount(_weiAmount)
      ),
      false
    );
    buyersCount = buyersCount.add(1);
    saleAmount = saleAmount.sub(getTokenAmount(_weiAmount));
    transfer(_to, getTokenAmount(_weiAmount), abi.encode("refill"));
  }

   
  function refillArray(address[] _to, uint[] _weiAmount) public onlyOwner {
    require(_to.length == _weiAmount.length);
    for (uint i = 0; i < _to.length; i++) {
      refill(_to[i], _weiAmount[i]);
    }
  }
  
   
  function setTeamFund() public onlyOwner{
    transfer(
      teamAddress,
      teamAmount,
      abi.encode("transfer reserved for team tokens to the team fund")
      );
    teamAmount = 0;
  }

   
  function finalize(Fund _reservedFund) public onlyOwner {
    require(saleAmount > 0);
    transfer(
      address(_reservedFund),
      saleAmount,
      abi.encode("transfer reserved for team tokens to the team fund")
    );
    saleAmount = 0;
  }

   
  function _safeTransfer(
    address _from,
    address _to,
    uint _value,
    bytes _data
  )
    internal
  {
    if (_to.isContract()) {
      IERC223BasicReceiver receiver = IERC223BasicReceiver(_to);
      receiver.tokenFallback(_from, _value, _data);
    }
  }

   
  function _safeApprove(address _spender, uint _value) internal {
    if (_spender.isContract()) {
      IERC223Receiver receiver = IERC223Receiver(_spender);
      receiver.receiveApproval(msg.sender, _value);
    }
  }

   
  function _preValidateRefill(address _to, uint _weiAmount)
    internal view returns (bool)
  {
    return(
      hasStarted() && _weiAmount > 0 &&  weiRaised.add(_weiAmount) <= cap
      && _to != address(0) && _weiAmount >= minimumWeiAmount &&
      getTokenAmount(_weiAmount) <= saleAmount
    );
  }
}