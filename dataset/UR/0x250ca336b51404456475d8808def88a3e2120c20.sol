 

pragma solidity 0.4.24;


 
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



 
contract CoyVesting is Ownable {

    using SafeMath for uint256;

    using SafeERC20 for ERC20;

    ERC20 public token;

     
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength;  
        uint256 transferred;
        bool revocable;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);

    event TokensUnlocked(address indexed _to, uint256 _value);

    event GrantRevoked(address indexed _holder, uint256 _refund);

     
    constructor(ERC20 _token) public {
        require(_token != address(0), "Token must exist and cannot be 0 address.");
        
        token = _token;
    }
    
     
    function unlockVestedTokens() external {
        Grant storage grant_ = grants[msg.sender];

         
        require(grant_.value != 0);
        
         
        uint256 vested = calculateVestedTokens(grant_, block.timestamp);
        
        if (vested == 0) {
            return;
        }
        
         
        
        uint256 transferable = vested.sub(grant_.transferred);
        
        if (transferable == 0) {
            return;
        }
        
         
        grant_.transferred = grant_.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        
        token.safeTransfer(msg.sender, transferable);

        emit TokensUnlocked(msg.sender, transferable);
    }

     
    function granting(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
    uint256 _installmentLength, bool _revocable)
    external onlyOwner 
    {    
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
            revocable: _revocable
        });
        
         
        totalVesting = totalVesting.add(_value);
        
        emit NewGrant(msg.sender, _to, _value);
    }
    
     
    function vestedTokens(address _holder, uint256 _time) external view returns (uint256) {
        Grant memory grant_ = grants[_holder];
        if (grant_.value == 0) {
            return 0;
        }
        return calculateVestedTokens(grant_, _time);
    }

     
    function revoke(address _holder) public onlyOwner {
        Grant memory grant_ = grants[_holder];

         
        require(grant_.revocable);

         
        uint256 vested = calculateVestedTokens(grant_, block.timestamp);
        
        uint256 notTransferredInstallment = vested.sub(grant_.transferred);
        
        uint256 refund = grant_.value.sub(vested);
        
         
        
         
        delete grants[_holder];
        
         
        totalVesting = totalVesting.sub(refund).sub(notTransferredInstallment);
        
         
        token.safeTransfer(_holder, notTransferredInstallment);
        
        emit TokensUnlocked(_holder, notTransferredInstallment);
        
        token.safeTransfer(msg.sender, refund);
        
        emit TokensUnlocked(msg.sender, refund);
        
        emit GrantRevoked(_holder, refund);
    }

     
    function calculateVestedTokens(Grant _grant, uint256 _time) private pure returns (uint256) {
         
        if (_time < _grant.cliff) {
            return 0;
        }
       
         
        if (_time >= _grant.end) {
            return _grant.value;
        }
       
         
         
        uint256 installmentsPast = _time.sub(_grant.start).div(_grant.installmentLength);
       
         
        uint256 vestingDays = _grant.end.sub(_grant.start);
       
         
        return _grant.value.mul(installmentsPast.mul(_grant.installmentLength)).div(vestingDays);
    }
}