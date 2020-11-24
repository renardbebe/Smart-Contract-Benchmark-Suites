 

pragma solidity ^0.4.17;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = true;
    }

     
    function remove(Role storage role, address addr)
    internal
    {
        role.bearer[addr] = false;
    }

     
    function check(Role storage role, address addr)
    view
    internal
    {
        require(has(role, addr));
    }

     
    function has(Role storage role, address addr)
    view
    internal
    returns (bool)
    {
        return role.bearer[addr];
    }
}



 
contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

     
    function checkRole(address addr, string roleName)
    view
    public
    {
        roles[roleName].check(addr);
    }

     
    function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
    {
        return roles[roleName].has(addr);
    }

     
    function addRole(address addr, string roleName)
    internal
    {
        roles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

     
    function removeRole(address addr, string roleName)
    internal
    {
        roles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

     
    modifier onlyRole(string roleName)
    {
        checkRole(msg.sender, roleName);
        _;
    }

     
     
     
     
     
     
     
     
     

     

     
     
}


 
contract RBACWithAdmin is RBAC {
     
    string public constant ROLE_ADMIN = "admin";

     
    modifier onlyAdmin()
    {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

     
    function RBACWithAdmin()
    public
    {
        addRole(msg.sender, ROLE_ADMIN);
    }

     
    function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
    {
        addRole(addr, roleName);
    }

     
    function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
    {
        removeRole(addr, roleName);
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
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

 
contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}



 
contract NbtToken  {
    uint256 public saleableTokens;
    uint256 public MAX_SALE_VOLUME;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function moveTokensFromSaleToCirculating(address _to, uint256 _amount) public returns (bool);
}

 
 
contract NbtCrowdsale is Crowdsale, Pausable, RBACWithAdmin {

     

    event NewStart(uint256 start);
    event NewDeadline(uint256 deadline);
    event NewRate(uint256 rate);
    event NewWallet(address new_address);
    event Sale(address indexed buyer, uint256 tokens_with_bonuses);

     

    uint256 public DECIMALS = 8;
    uint256 public BONUS1 = 100;  
    uint256 public BONUS1_LIMIT = 150000000 * 10**DECIMALS;
    uint256 public BONUS2 = 60;  
    uint256 public BONUS2_LIMIT = 250000000 * 10**DECIMALS;
    uint256 public MIN_TOKENS = 1000 * 10**DECIMALS;

    NbtToken public token;

     

    uint256 public start;
    uint256 public deadline;
    bool crowdsaleClosed = false;

     

    modifier afterDeadline() { if (now > deadline) _; }
    modifier beforeDeadline() { if (now <= deadline) _; }
    modifier afterStart() { if (now >= start) _; }
    modifier beforeStart() { if (now < start) _; }

     

     
    function NbtCrowdsale(uint256 _rate, address _wallet, NbtToken _token, uint256 _start, uint256 _deadline) Crowdsale(_rate, _wallet, ERC20(_token)) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_start < _deadline);

        start = _start;
        deadline = _deadline;

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     

     
    function setStart(uint256 _start) onlyAdmin whenPaused public returns (bool) {
        require(_start < deadline);
        start = _start;
        emit NewStart(start);
        return true;
    }

     
    function setDeadline(uint256 _deadline) onlyAdmin whenPaused public returns (bool) {
        require(start < _deadline);
        deadline = _deadline;
        emit NewDeadline(_deadline);
        return true;
    }

     
    function setWallet(address _addr) onlyAdmin public returns (bool) {
        require(_addr != address(0) && _addr != address(this));
        wallet = _addr;
        emit NewWallet(wallet);
        return true;
    }

     
    function setRate(uint256 _rate) onlyAdmin public returns (bool) {
        require(_rate > 0);
        rate = _rate;
        emit NewRate(rate);
        return true;
    }

     
    function pause() onlyAdmin whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyAdmin whenPaused public {
        paused = false;
        emit Unpause();
    }

    function getCurrentBonus() public view returns (uint256) {
        if (token.MAX_SALE_VOLUME().sub(token.saleableTokens()) < BONUS1_LIMIT) {
            return BONUS1;
        } else if (token.MAX_SALE_VOLUME().sub(token.saleableTokens()) < BONUS2_LIMIT) {
            return BONUS2;
        } else {
            return 0;
        }
    }

    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return _getTokenAmount(_weiAmount);
    }

     
    function closeCrowdsale() onlyAdmin afterDeadline public {
        crowdsaleClosed = true;
    }

     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) whenNotPaused afterStart beforeDeadline internal {
        require(!crowdsaleClosed);
        require(_weiAmount >= 1000000000000);
        require(_getTokenAmount(_weiAmount) <= token.balanceOf(this));
        require(_getTokenAmount(_weiAmount) >= MIN_TOKENS);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.moveTokensFromSaleToCirculating(_beneficiary, _tokenAmount);
        token.transfer(_beneficiary, _tokenAmount);
        emit Sale(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 _current_bonus =  getCurrentBonus();
        if (_current_bonus == 0) {
            return _weiAmount.mul(rate).div(1000000000000);  
        } else {
            return _weiAmount.mul(rate).mul(_current_bonus.add(100)).div(100).div(1000000000000);  
        }
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}