 

pragma solidity 0.4.24;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract VestTokenAllocation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public allocatedTokens;
    uint256 public canSelfDestruct;

    mapping (address => uint256) public totalTokensLocked;
    mapping (address => uint256) public releasedTokens;

    ERC20 public golix;
    address public tokenDistribution;

    event Released(address beneficiary, uint256 amount);

     
    function VestTokenAllocation
        (
            ERC20 _token,
            address _tokenDistribution,
            uint256 _start,
            uint256 _cliff,
            uint256 _duration,
            uint256 _canSelfDestruct
        )
        public
    {
        require(_token != address(0) && _cliff != 0);
        require(_cliff <= _duration);
        require(_start > now);
        require(_canSelfDestruct > _duration.add(_start));

        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;

        golix = ERC20(_token);
        tokenDistribution = _tokenDistribution;
        canSelfDestruct = _canSelfDestruct;
    }

    modifier onlyOwnerOrTokenDistributionContract() {
        require(msg.sender == address(owner) || msg.sender == address(tokenDistribution));
        _;
    }
     
    function addVestTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwnerOrTokenDistributionContract
    {
        require(totalTokensLocked[beneficiary] == 0 && beneficiary != address(0));  

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= golix.balanceOf(this));

        totalTokensLocked[beneficiary] = allocationValue;
    }

     
    function release() public {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0);

        releasedTokens[msg.sender] = releasedTokens[msg.sender].add(unreleased);

        golix.safeTransfer(msg.sender, unreleased);

        emit Released(msg.sender, unreleased);
    }

     
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(releasedTokens[msg.sender]);
    }

     
    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = totalTokensLocked[msg.sender];

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }

     
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = golix.balanceOf(this);

        if (balance > 0) {
            golix.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
    }
}