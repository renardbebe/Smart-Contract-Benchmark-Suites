 

pragma solidity 0.5.3;


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

   
  function divCeil(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    return ((_a - 1) / _b) + 1;
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

contract BZRxOTCSwapSimple is Ownable {
    using SafeMath for uint256;

    ERC20 public token;

    mapping (address => uint256) public ethDeposit;
    mapping (address => uint256) public tokenDeposit;
    mapping (address => bool) public whitelist;

    bool public contractDisabled = false;

    modifier usageAllowed() {
        require(!contractDisabled,
        "usage not allowed");
        _;
    }

    modifier whitelisted() {
        require(whitelist[msg.sender],
        "not whitelisted");
        _;
    }

    constructor(
        address tokenAddress)
        public
    {
        token = ERC20(tokenAddress);
        whitelist[msg.sender] = true;
    }

    function()
        external
    {
        revert("invalid");
    }

    function completeSwap(
        address tokenBuyer,
        address payable tokenSeller,
        uint256 ethAmountFromBuyer,
        uint256 tokenAmountFromSeller)
        public
        usageAllowed
        whitelisted
    {
        require(msg.sender == tokenBuyer ||
            msg.sender == tokenSeller ||
            msg.sender == owner, "unauthorized");
        ethDeposit[tokenBuyer] = ethDeposit[tokenBuyer].sub(ethAmountFromBuyer);
        tokenDeposit[tokenSeller] = tokenDeposit[tokenSeller].sub(tokenAmountFromSeller);

        tokenSeller.transfer(ethAmountFromBuyer);
        require(token.transfer(
            tokenBuyer,
            tokenAmountFromSeller),
            "transfer failed"
        );
    }

    function depositEther()
        public
        payable
        usageAllowed
        whitelisted
    {
        ethDeposit[msg.sender] = ethDeposit[msg.sender].add(msg.value);
    }

    function depositToken(
        uint256 amount)
        public
        usageAllowed
        whitelisted
    {
        require(token.transferFrom(
            msg.sender,
            address(this),
            amount),
            "transfer failed"
        );
        tokenDeposit[msg.sender] = tokenDeposit[msg.sender].add(amount);
    }

    function withdrawEther(
        uint256 amount)
        public
    {
        if (amount > ethDeposit[msg.sender]) {
            amount = ethDeposit[msg.sender];
        }

        require(amount != 0, "no ether");
        ethDeposit[msg.sender] = ethDeposit[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }

    function withdrawToken(
        uint256 amount)
        public
    {
        if (amount > tokenDeposit[msg.sender]) {
            amount = tokenDeposit[msg.sender];
        }

        require(amount != 0, "no token");
        tokenDeposit[msg.sender] = tokenDeposit[msg.sender].sub(amount);
        require(token.transfer(
            msg.sender,
            amount),
            "transfer failed"
        );
    }

    function toggleUsageAllowed(
        bool isAllowed)
        public
        onlyOwner
    {
        contractDisabled = !isAllowed;
    }

    function setWhitelist(
        address[] memory users,
        bool[] memory toggles)
        public
        onlyOwner
    {
        require(users.length == toggles.length, "count mismatch");

        for (uint256 i=0; i < users.length; i++) {
            whitelist[users[i]] = toggles[i];
        }
    }
}