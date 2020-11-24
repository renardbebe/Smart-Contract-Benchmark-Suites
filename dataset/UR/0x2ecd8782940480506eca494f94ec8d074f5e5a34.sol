 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Whitelist is Ownable {
    mapping (address => bool)       public  whitelist;

    constructor() public {
    }

    modifier whitelistOnly {
        require(whitelist[msg.sender], "MEMBERS_ONLY");
        _;
    }

    function addMember(address member)
        public
        onlyOwner
    {
        require(!whitelist[member], "ALREADY_EXISTS");
        whitelist[member] = true;
    }

    function removeMember(address member)
        public
        onlyOwner
    {
        require(whitelist[member], "NOT_EXISTS");
        whitelist[member] = false;
    }
}


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}



 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20Token token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Token token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20Token token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Token token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Token token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20Token token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


library WadMath {
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }
}


contract ERC20Token {
    uint8   public decimals = 18;
    string  public name;
    string  public symbol;
    uint256 public totalSupply;

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    event  Approval(address indexed _owner, address indexed _spender, uint _value);
    event  Transfer(address indexed _from, address indexed _to, uint _value);

    constructor(
        string memory _name,
        string memory _symbol
    ) public {
        name = _name;
        symbol = _symbol;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "INSUFFICIENT_FUNDS");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "NOT_ALLOWED");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}


contract MintableERC20Token is ERC20Token {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol
    )
        public
        ERC20Token(_name, _symbol)
    {}

    function _mint(address to, uint256 wad)
        internal
    {
        balanceOf[to] = balanceOf[to].add(wad);
        totalSupply = totalSupply.add(wad);

        emit Transfer(address(0), to, wad);
    }

    function _burn(address owner, uint256 wad)
        internal
    {
        balanceOf[owner] = balanceOf[owner].sub(wad);
        totalSupply = totalSupply.sub(wad);

        emit Transfer(owner, address(0), wad);
    }
}



contract IERC20Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value)
        external
        returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool);

    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}



contract MBFToken is
    MintableERC20Token,
    Ownable,
    Whitelist
{
    using SafeMath for uint256;
    using WadMath for uint256;
    using SafeERC20 for IERC20Token;

     
    uint256 constant             public   globalDecimals = 18;
    IERC20Token                  internal collateral;
    uint256                      public   maxSupply;

    bool                         public   finalized;
    uint256                      public   targetPrice;
    uint256                      public   totalProfit;
    uint256[]                    public   historyProfits;
    uint256[]                    public   historyTime;
    mapping (address => Account) public   accounts;

     
    struct Account {
        uint256 profit;
        uint256 taken;
        uint256 settled;
    }

     
    event  Mint(address indexed _owner, uint256 _value);
    event  Burn(address indexed _owner, uint256 _value);
    event  Withdraw(address indexed _owner, uint256 _value);
    event  Pay(uint256 _value);

    constructor(
        address _collateralAddress,
        uint256 _maxSupply
    )
        public
        MintableERC20Token("P106 Token", "P106")
    {
        collateral = IERC20Token(_collateralAddress);
        maxSupply = _maxSupply;
        finalized = false;
    }

    function finalize()
        public
        onlyOwner
    {
        require(finalized == false, "CAN_ONLY_FINALIZE_ONCE");
        finalized = true;
        uint256 remaining = maxSupply.sub(totalSupply);
        _mint(owner(), remaining);

        emit Mint(owner(), remaining);
    }

    modifier beforeFinalized {
        require(finalized == false, "ALREADY_FINALIZED");
        _;
    }

    modifier afterFinalized {
        require(finalized == true, "NOT_FINALIZED");
        _;
    }

    function historyProfitsArray()
        public
        view
        returns (uint256[] memory)
    {
        return historyProfits;
    }

    function historyTimeArray()
        public
        view
        returns (uint256[] memory)
    {
        return historyTime;
    }

    function setTargetPrice(uint256 wad)
        public
        onlyOwner
    {
        require(wad > 0, "INVALID_RIG_PRICE");
        targetPrice = wad;
    }

    function pay(uint256 wad)
        public
        onlyOwner
        afterFinalized
    {
        totalProfit = totalProfit.add(wad);
        historyProfits.push(wad);
        historyTime.push(now);

        emit Pay(wad);
    }

    function unsettledProfitOf(address beneficiary)
        public
        view
        returns (uint256)
    {
        if (totalProfit == accounts[beneficiary].settled) {
            return 0;
        }
        uint256 toSettle = totalProfit.sub(accounts[beneficiary].settled);
        return toSettle.wmul(balanceOf[beneficiary]).wdiv(maxSupply);
    }

    function profitOf(address beneficiary)
        public
        view
        returns (uint256)
    {
         
        return unsettledProfitOf(beneficiary) + accounts[beneficiary].profit;
    }

    function totalProfitOf(address beneficiary)
        public
        view
        returns (uint256)
    {
        return accounts[beneficiary].taken.add(profitOf(beneficiary));
    }

    function adjustProfit(address beneficiary)
        internal
    {
        if (accounts[beneficiary].settled == totalProfit) {
            return;
        }
        accounts[beneficiary].profit = profitOf(beneficiary);
        accounts[beneficiary].settled = totalProfit;
    }

    function withdraw()
        public
    {
        require(msg.sender != address(0), "INVALID_ADDRESS");

        adjustProfit(msg.sender);
        require(accounts[msg.sender].profit > 0, "NO_PROFIT");

        uint256 available = accounts[msg.sender].profit;
        accounts[msg.sender].profit = 0;
        accounts[msg.sender].taken = accounts[msg.sender].taken.add(available);
        collateral.safeTransferFrom(owner(), msg.sender, available);

        emit Withdraw(msg.sender, available);
    }

    function transferFrom(address src, address dst, uint256 wad)
        public
        returns (bool)
    {
        adjustProfit(src);
        if (balanceOf[dst] == 0) {
            accounts[dst].settled = totalProfit;
        } else {
            adjustProfit(dst);
        }
        return super.transferFrom(src, dst, wad);
    }

    function join(uint256 wad)
        public
        whitelistOnly
        beforeFinalized
    {
        require(targetPrice > 0, "PRICE_NOT_INIT");
        require(wad > 0 && wad <= maxSupply.sub(totalSupply), "EXCEEDS_MAX_SUPPLY");

        uint256 joinPrice = wad.wmul(targetPrice);
        collateral.safeTransferFrom(msg.sender, owner(), joinPrice);
        _mint(msg.sender, wad);

        emit Mint(msg.sender, wad);
    }
}