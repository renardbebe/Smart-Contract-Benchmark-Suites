 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

contract HAVesting is Ownable {
  using SafeMath for uint;
  using SafeERC20 for ERC20;

     
    ERC20 public token;

     
    struct Grant {
        uint value;
        uint start;
        uint cliff;
        uint end;
        uint installmentLength;  
        uint transferred;
        bool revokable;
    }

     
    mapping (address => Grant) public grants;

     
    uint public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint _value);
    event TokensUnlocked(address indexed _to, uint _value);
    event GrantRevoked(address indexed _holder, uint _refund);

     
     
    constructor(ERC20 _token) public {
        require(_token != address(0));

        token = _token;
    }

     
     
     
     
     
     
     
     
    function grantTo(address _to, uint _value, uint _start, uint _cliff, uint _end,
        uint _installmentLength, bool _revokable)
        external onlyOwner {

        require(_to != address(0));
        require(_to != address(this));  
        require(_value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

         
        require(totalVesting.add(_value) <= token.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(_value);

        emit NewGrant(msg.sender, _to, _value);
    }

     
     
    function revoke(address _holder) public onlyOwner {
        Grant memory grant = grants[_holder];

         
        require(grant.revokable);

         
         
        uint refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

         
        totalVesting = totalVesting.sub(refund);
        token.transfer(msg.sender, refund);

        emit GrantRevoked(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint _time) external constant returns (uint) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
    function calculateVestedTokens(Grant _grant, uint _time) internal pure returns (uint) {
         
        if (_time < _grant.cliff) {
            return 0;
        }

         
        if (_time >= _grant.end) {
            return _grant.value;
        }

         
         
         
        uint installmentsPast = _time.sub(_grant.start).div(_grant.installmentLength);

         
        uint vestingDays = _grant.end.sub(_grant.start);

         
        return _grant.value.mul(installmentsPast.mul(_grant.installmentLength)).div(vestingDays);
    }

     
     
    function unlockVestedTokens() external {
        Grant storage grant = grants[msg.sender];

         
        require(grant.value != 0);

         
        uint vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

         
        uint transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

         
        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        token.transfer(msg.sender, transferable);

        emit TokensUnlocked(msg.sender, transferable);
    }
}