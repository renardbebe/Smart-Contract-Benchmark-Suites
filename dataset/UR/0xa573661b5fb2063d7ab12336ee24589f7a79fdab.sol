 

pragma solidity 0.4.24;

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
contract Ownable {

    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

     
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

     
    modifier whenLocked() {
        require(locked);
        _;
    }

     
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

     
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

 

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

     
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

     
    event Transfer(address indexed from, address indexed to, uint value);

     
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

     
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

     
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

     
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

     
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

 

 
contract BaseICOToken is BaseFixedERC20Token {

     
    uint public availableSupply;

     
    address public ico;

     
    event ICOTokensInvested(address indexed to, uint amount);

     
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

     
    constructor(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

     
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        emit ICOChanged(ico);
    }

     
    function icoInvestmentWei(address to_, uint amountWei_, uint ethTokenExchangeRatio_) public returns (uint);

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }
}

 

 
contract SelfDestructible is Ownable {

    function selfDestruct(uint8 v, bytes32 r, bytes32 s) public onlyOwner {
        if (ecrecover(prefixedHash(), v, r, s) != owner) {
            revert();
        }
        selfdestruct(owner);
    }

    function originalHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "Signed for Selfdestruct",
                address(this),
                msg.sender
            ));
    }

    function prefixedHash() internal view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, originalHash()));
    }
}

 

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
}

 

 
contract Withdrawal is Ownable {

     
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function withdrawTokens(address _someToken) public onlyOwner {
        ERC20Token someToken = ERC20Token(_someToken);
        uint balance = someToken.balanceOf(address(this));
        someToken.transfer(owner, balance);
    }
}

 

 
contract ICHXToken is BaseICOToken, SelfDestructible, Withdrawal {
    using SafeMath for uint;

    string public constant name = "IceChain";

    string public constant symbol = "ICHX";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    constructor(uint totalSupplyTokens_,
            uint companyTokens_) public
        BaseICOToken(totalSupplyTokens_.mul(ONE_TOKEN)) {
        require(availableSupply == totalSupply);

        balances[owner] = companyTokens_.mul(ONE_TOKEN);

        availableSupply = availableSupply
            .sub(balances[owner]);

        emit Transfer(0, address(this), balances[owner]);
        emit Transfer(address(this), owner, balances[owner]);
    }

     
    function() external payable {
        revert();
    }

     
    function icoInvestmentWei(address to_, uint amountWei_, uint ethTokenExchangeRatio_) public onlyICO returns (uint) {
        uint amount = amountWei_.mul(ethTokenExchangeRatio_).mul(ONE_TOKEN).div(1 ether);
        require(isValidICOInvestment(to_, amount));
        availableSupply = availableSupply.sub(amount);
        balances[to_] = balances[to_].add(amount);
        emit ICOTokensInvested(to_, amount);
        return amount;
    }
}