 

 
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

 
 
pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
 

pragma solidity 0.4.24;



contract TokenVault {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ERC20 public token;
    uint256 public releaseTime;

    mapping(address => uint256) public lockedBalances;

     
    constructor(address _token, uint256 _releaseTime) public {
        require(block.timestamp < _releaseTime);
        token = ERC20(_token);
        releaseTime = _releaseTime;
    }

     
    function batchRelease(address[] beneficiaries) external {
        uint256 length = beneficiaries.length;
        for (uint256 i = 0; i < length; i++) {
            releaseFor(beneficiaries[i]);
        }
    }

     
    function release() public {
        releaseFor(msg.sender);
    }

     
    function releaseFor(address beneficiary) public {
        require(block.timestamp >= releaseTime);
        uint256 amount = lockedBalances[beneficiary];
        require(amount > 0);
        lockedBalances[beneficiary] = 0;
        token.safeTransfer(beneficiary, amount);
    }

     
    function addBalance(uint256 value) public {
        addBalanceFor(msg.sender, value);
    }

     
    function addBalanceFor(address account, uint256 value) public {
        lockedBalances[account] = lockedBalances[account].add(value);
        token.safeTransferFrom(msg.sender, address(this), value);
    }

      
    function getLockedBalance(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
}



 