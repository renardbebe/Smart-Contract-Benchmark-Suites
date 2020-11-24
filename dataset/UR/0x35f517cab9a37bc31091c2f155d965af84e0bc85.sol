 

pragma solidity ^0.4.13;

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

contract TokenContinuousDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Released(ERC20Basic token, uint256 amount);

     
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public endTime;
     
    uint256 public secondsIn1Unit = 86400;
     
    uint256 public numberOfUnits = 1825;
     
    uint256 public duration = 157680000;

     
    uint256 numberOfPhases = 5;
     
    uint256 slice = 15;

    mapping(address => uint256) public released;

     
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff
    )
    public
    {
        require(_beneficiary != address(0), "Beneficiary address should NOT be null.");
        require(_cliff <= duration, "Cliff should be less than or equal to duration (i.e. secondsIn1Unit.mul(numberOfUnits)).");
        require((numberOfUnits % 5) == 0, "numberOfUnits should be a multiple of 5");


        beneficiary = _beneficiary;
        cliff = _start.add(_cliff);
        start = _start;
        endTime = _start.add(duration);
    }

     
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0, "Unreleased amount should be larger than 0.");

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        emit Released(token, unreleased);
    }

     
    function releasableAmount(ERC20Basic token) public view returns (uint256) {
        return distributedAmount(token).sub(released[token]);
    }

     
    function distributedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 blockTimestamp = block.timestamp;
        return distributedAmountWithBlockTimestamp(token, blockTimestamp);
    }


    function distributedAmountWithBlockTimestamp(ERC20Basic token, uint256 blockTimestamp) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (blockTimestamp < cliff) {
            return 0;
        } else if (blockTimestamp >= endTime) {
            return totalBalance;
        } else {
            uint256 unitsPassed = blockTimestamp.sub(start).div(secondsIn1Unit);  
            uint256 unitsIn1Phase = numberOfUnits.div(numberOfPhases);  
            uint256 unitsInThisPhase;
            uint256 weight;

            if (unitsPassed < unitsIn1Phase) {
                weight = 5;
                unitsInThisPhase = unitsPassed;
                 
                return unitsInThisPhase.mul(totalBalance).mul(weight).div(slice).div(unitsIn1Phase);
            } else if (unitsPassed < unitsIn1Phase.mul(2)) {
                weight = 4;
                unitsInThisPhase = unitsPassed.sub(unitsIn1Phase);
                 
                 
                return totalBalance.mul(5).add(unitsInThisPhase.mul(totalBalance).mul(weight).div(unitsIn1Phase)).div(slice);
            } else if (unitsPassed < unitsIn1Phase.mul(3)) {
                weight = 3;
                unitsInThisPhase = unitsPassed.sub(unitsIn1Phase.mul(2));
                 
                 
                return totalBalance.mul(9).add(unitsInThisPhase.mul(totalBalance).mul(weight).div(unitsIn1Phase)).div(slice);
            } else if (unitsPassed < unitsIn1Phase.mul(4)) {
                weight = 2;
                unitsInThisPhase = unitsPassed.sub(unitsIn1Phase.mul(3));
                 
                 
                return totalBalance.mul(12).add(unitsInThisPhase.mul(totalBalance).mul(weight).div(unitsIn1Phase)).div(slice);
            } else if (unitsPassed < unitsIn1Phase.mul(5)) {
                weight = 1;
                unitsInThisPhase = unitsPassed.sub(unitsIn1Phase.mul(4));
                 
                 
                return totalBalance.mul(14).add(unitsInThisPhase.mul(totalBalance).mul(weight).div(unitsIn1Phase)).div(slice);
            }
            require(blockTimestamp < endTime, "Block timestamp is expected to have not reached distribution endTime if the code even falls in here.");
        }
    }
}