 

pragma solidity ^0.5.0;

 

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

interface IGlobalIndex {
    function getControllerAddress() external view returns (address);
    function setControllerAddress(address _newControllerAddress) external;
}

 

interface ICRWDController {
    function buyFromCrowdsale(address _to, uint256 _amountInWei) external returns (uint256 _tokensCreated, uint256 _overpaidRefund);  
    function assignFromCrowdsale(address _to, uint256 _tokenAmount, bytes8 _tag) external returns (uint256 _tokensCreated);  
    function calcTokensForEth(uint256 _amountInWei) external view returns (uint256 _tokensWouldBeCreated);  
}

 

 
contract Secondary {
    address private _primary;

    event PrimaryTransferred(
        address recipient
    );

     
    constructor () internal {
        _primary = msg.sender;
        emit PrimaryTransferred(_primary);
    }

     
    modifier onlyPrimary() {
        require(msg.sender == _primary);
        _;
    }

     
    function primary() public view returns (address) {
        return _primary;
    }

     
    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0));
        _primary = recipient;
        emit PrimaryTransferred(_primary);
    }
}

 

 
contract Escrow is Secondary {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

     
    function deposit(address payee) public onlyPrimary payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].add(amount);

        emit Deposited(payee, amount);
    }

     
    function withdraw(address payable payee) public onlyPrimary {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}

 

 
contract ConditionalEscrow is Escrow {
     
    function withdrawalAllowed(address payee) public view returns (bool);

    function withdraw(address payable payee) public {
        require(withdrawalAllowed(payee));
        super.withdraw(payee);
    }
}

 

 
contract RefundEscrow is ConditionalEscrow {
    enum State { Active, Refunding, Closed }

    event RefundsClosed();
    event RefundsEnabled();

    State private _state;
    address payable private _beneficiary;

     
    constructor (address payable beneficiary) public {
        require(beneficiary != address(0));
        _beneficiary = beneficiary;
        _state = State.Active;
    }

     
    function state() public view returns (State) {
        return _state;
    }

     
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

     
    function deposit(address refundee) public payable {
        require(_state == State.Active);
        super.deposit(refundee);
    }

     
    function close() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Closed;
        emit RefundsClosed();
    }

     
    function enableRefunds() public onlyPrimary {
        require(_state == State.Active);
        _state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function beneficiaryWithdraw() public {
        require(_state == State.Closed);
        _beneficiary.transfer(address(this).balance);
    }

     
    function withdrawalAllowed(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}

 

 






 
library CrowdsaleL {
    using SafeMath for uint256;

 
 
 

     
    enum State { Draft, Started, Ended, Finalized, Refunding, Closed }

    struct Data {
         
        address token;

         
        State state;

         
        uint256 cap;

         
        uint256 startTime;
        
         
        uint256 endTime;

         
        address payable wallet;

         
        IGlobalIndex globalIndex;

         
        uint256 tokensRaised;
    }

    struct Roles {
         
        address tokenAssignmentControl;

         
        address tokenRescueControl;
    }

 
 
 

     
     
    function init(Data storage _self, address _assetToken) public {
        _self.token = _assetToken;
        _self.state = State.Draft;
    }

     
     
     
    function configure(
        Data storage _self, 
        address payable _wallet, 
        address _globalIndex)
    public 
    {
        require(_self.state == CrowdsaleL.State.Draft, "not draft state");
        require(_wallet != address(0), "wallet zero addr");
        require(_globalIndex != address(0), "globalIdx zero addr");

        _self.wallet = _wallet;
        _self.globalIndex = IGlobalIndex(_globalIndex);

        emit CrowdsaleConfigurationChanged(_wallet, _globalIndex);
    }

     
     
     
    function setRoles(Roles storage _self, address _tokenAssignmentControl, address _tokenRescueControl) public {
        require(_tokenAssignmentControl != address(0), "addr0");
        require(_tokenRescueControl != address(0), "addr0");
        
        _self.tokenAssignmentControl = _tokenAssignmentControl;
        _self.tokenRescueControl = _tokenRescueControl;

        emit RolesChanged(msg.sender, _tokenAssignmentControl, _tokenRescueControl);
    }

     
    function getControllerAddress(Data storage _self) public view returns (address) {
        return IGlobalIndex(_self.globalIndex).getControllerAddress();
    }

     
    function getController(Data storage _self) private view returns (ICRWDController) {
        return ICRWDController(getControllerAddress(_self));
    }

     
     
    function setCap(Data storage _self, uint256 _cap) public {
         
         
        _self.cap = _cap;
    }

     
     
     
    function buyTokensFor(Data storage _self, address _beneficiary, uint256 _investedAmount) 
    public 
    returns (uint256)
    {
        require(validPurchasePreCheck(_self), "invalid purchase precheck");

        (uint256 tokenAmount, uint256 overpaidRefund) = getController(_self).buyFromCrowdsale(_beneficiary, _investedAmount);

        if(tokenAmount == 0) {
             
            overpaidRefund = _investedAmount;
        }

        require(validPurchasePostCheck(_self, tokenAmount), "invalid purchase postcheck");
        _self.tokensRaised = _self.tokensRaised.add(tokenAmount);

        emit TokenPurchase(msg.sender, _beneficiary, tokenAmount, overpaidRefund, "ETH");

        return overpaidRefund;
    }

     
    function requireActiveOrDraftState(Data storage _self) public view returns (bool) {
        require((_self.state == State.Draft) || (_self.state == State.Started), "only active or draft state");

        return true;
    }

     
     
    function validStart(Data storage _self) public view returns (bool) {
        require(_self.wallet != address(0), "wallet is zero addr");
        require(_self.token != address(0), "token is zero addr");
        require(_self.cap > 0, "cap is 0");
        require(_self.startTime != 0, "time not set");
        require(now >= _self.startTime, "too early");

        return true;
    }

     
     
     
    function setTime(Data storage _self, uint256 _startTime, uint256 _endTime) public
    {
        _self.startTime = _startTime;
        _self.endTime = _endTime;

        emit CrowdsaleTimeChanged(_startTime, _endTime);
    }

     
     
     
    function hasEnded(Data storage _self) public view returns (bool) {
        bool capReached = _self.tokensRaised >= _self.cap; 
        bool endStateReached = (_self.state == CrowdsaleL.State.Ended || _self.state == CrowdsaleL.State.Finalized || _self.state == CrowdsaleL.State.Closed || _self.state == CrowdsaleL.State.Refunding);
        
        return endStateReached || capReached || now > _self.endTime;
    }

     
     
    function closeCrowdsale(Data storage _self) public {
        require((_self.state == State.Finalized) || (_self.state == State.Refunding), "state");

        _self.state = State.Closed;
    }

     
     
    function validPurchasePreCheck(Data storage _self) private view returns (bool) {
        require(_self.state == State.Started, "not in state started");
        bool withinPeriod = now >= _self.startTime && _self.endTime >= now;
        require(withinPeriod, "not within period");

        return true;
    }

     
     
    function validPurchasePostCheck(Data storage _self, uint256 _tokensCreated) private view returns (bool) {
        require(_self.state == State.Started, "not in state started");
        bool withinCap = _self.tokensRaised.add(_tokensCreated) <= _self.cap; 
        require(withinCap, "not within cap");

        return true;
    }

     
    function assignTokens(
        Data storage _self, 
        address _beneficiaryWallet, 
        uint256 _tokenAmount, 
        bytes8 _tag) 
        public returns (uint256 _tokensCreated)
    {
        _tokensCreated = getController(_self).assignFromCrowdsale(
            _beneficiaryWallet, 
            _tokenAmount,
            _tag);
        
        emit TokenPurchase(msg.sender, _beneficiaryWallet, _tokensCreated, 0, _tag);

        return _tokensCreated;
    }

     
     
    function calcTokensForEth(Data storage _self, uint256 _ethAmountInWei) public view returns (uint256 _tokensWouldBeCreated) {
        return getController(_self).calcTokensForEth(_ethAmountInWei);
    }

     
     
     
    function rescueToken(Data storage _self, address _foreignTokenAddress, address _to) public
    {
        ERC20(_foreignTokenAddress).transfer(_to, ERC20(_foreignTokenAddress).balanceOf(address(this)));
    }

 
 
 

    event TokenPurchase(address indexed invoker, address indexed beneficiary, uint256 tokenAmount, uint256 overpaidRefund, bytes8 tag);
    event CrowdsaleTimeChanged(uint256 startTime, uint256 endTime);
    event CrowdsaleConfigurationChanged(address wallet, address globalIndex);
    event RolesChanged(address indexed initiator, address tokenAssignmentControl, address tokenRescueControl);
}

 

 


 
library VaultGeneratorL {

     
     
     
    function generateEthVault(address payable _wallet) public returns (address ethVaultInterface) {
        return address(new RefundEscrow(_wallet));
    }
}

 

interface IBasicAssetToken {
     
    function getLimits() external view returns (uint256, uint256, uint256, uint256);
    function isTokenAlive() external view returns (bool);

     
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
}

 

 
interface EthVaultInterface {

    event Closed();
    event RefundsEnabled();

     
     
    function deposit(address _refundee) external payable;

     
     
    function close() external;

     
    function enableRefunds() external;

     
    function beneficiaryWithdraw() external;

     
    function withdrawalAllowed(address _payee) external view returns (bool);

     
    function withdraw(address _payee) external;
}

 

 








 
contract BasicAssetTokenCrowdsaleNoFeature is Ownable {
    using SafeMath for uint256;
    using CrowdsaleL for CrowdsaleL.Data;
    using CrowdsaleL for CrowdsaleL.Roles;

     

 
 
 

    CrowdsaleL.Data crowdsaleData;
    CrowdsaleL.Roles roles;

 
 
 

    constructor(address _assetToken) public {
        crowdsaleData.init(_assetToken);
    }

 
 
 

    modifier onlyTokenRescueControl() {
        require(msg.sender == roles.tokenRescueControl, "rescueCtrl");
        _;
    }

 
 
 

    function token() public view returns (address) {
        return crowdsaleData.token;
    }

    function wallet() public view returns (address) {
        return crowdsaleData.wallet;
    }

    function tokensRaised() public view returns (uint256) {
        return crowdsaleData.tokensRaised;
    }

    function cap() public view returns (uint256) {
        return crowdsaleData.cap;
    }

    function state() public view returns (CrowdsaleL.State) {
        return crowdsaleData.state;
    }

    function startTime() public view returns (uint256) {
        return crowdsaleData.startTime;
    }

    function endTime() public view returns (uint256) {
        return crowdsaleData.endTime;
    }

    function getControllerAddress() public view returns (address) {
        return address(crowdsaleData.getControllerAddress());
    }

 
 
 

    event TokenPurchase(address indexed invoker, address indexed beneficiary, uint256 tokenAmount, uint256 overpaidRefund, bytes8 tag);
    event CrowdsaleTimeChanged(uint256 startTime, uint256 endTime);
    event CrowdsaleConfigurationChanged(address wallet, address globalIndex);
    event RolesChanged(address indexed initiator, address tokenAssignmentControl, address tokenRescueControl);
    event Started();
    event Ended();
    event Finalized();

 
 
 

    modifier onlyTokenAssignmentControl() {
        require(_isTokenAssignmentControl(), "only tokenAssignmentControl");
        _;
    }

    modifier onlyDraftState() {
        require(crowdsaleData.state == CrowdsaleL.State.Draft, "only draft state");
        _;
    }

    modifier onlyActive() {
        require(_isActive(), "only when active");
        _;
    }

    modifier onlyActiveOrDraftState() {
        require(_isActiveOrDraftState(), "only active/draft");
        _;
    }

    modifier onlyUnfinalized() {
        require(crowdsaleData.state != CrowdsaleL.State.Finalized, "only unfinalized");
        _;
    }

     
    function _isActiveOrDraftState() internal view returns (bool) {
        return crowdsaleData.requireActiveOrDraftState();
    }

     
    function _isTokenAssignmentControl() internal view returns (bool) {
        return msg.sender == roles.tokenAssignmentControl;
    }

     
    function _isActive() internal view returns (bool) {
        return crowdsaleData.state == CrowdsaleL.State.Started;
    }
 
 
 
 

     
     
     
    function setCrowdsaleData(
        address payable _wallet,
        address _globalIndex)
    public
    onlyOwner 
    {
        crowdsaleData.configure(_wallet, _globalIndex);
    }

     
    function getTokenAssignmentControl() public view returns (address) {
        return roles.tokenAssignmentControl;
    }

     
    function getTokenRescueControl() public view returns (address) {
        return roles.tokenRescueControl;
    }

     
     
    function setCap(uint256 _cap) internal onlyUnfinalized {
        crowdsaleData.setCap(_cap);
    }

     
     
     
    function setRoles(address _tokenAssignmentControl, address _tokenRescueControl) public onlyOwner {
        roles.setRoles(_tokenAssignmentControl, _tokenRescueControl);
    }

     
     
     
    function setCrowdsaleTime(uint256 _startTime, uint256 _endTime) internal onlyUnfinalized {
         
        require(_endTime >= _startTime, "endTime smaller start");

        crowdsaleData.setTime(_startTime, _endTime);
    }

     
     
    function updateFromAssetToken() public {
        (uint256 _cap,  , uint256 _startTime, uint256 _endTime) = IBasicAssetToken(crowdsaleData.token).getLimits();
        setCap(_cap);
        setCrowdsaleTime(_startTime, _endTime);
    }

 
 
 

     
    function startCrowdsale() public onlyDraftState {
        updateFromAssetToken();  
        
        require(validStart(), "validStart");
        prepareStart();
        crowdsaleData.state = CrowdsaleL.State.Started;
        emit Started();
    }

     
    function calcTokensForEth(uint256 _ethAmountInWei) public view returns (uint256 _tokensWouldBeCreated) {
        return crowdsaleData.calcTokensForEth(_ethAmountInWei);
    }

     
     
     
    function validStart() internal view returns (bool) {
        return crowdsaleData.validStart();
    }

     
     
     
    function prepareStart() internal {
    }

     
     
    function forwardWeiFunds(uint256 _overpaidRefund) internal {
        require(_overpaidRefund <= msg.value, "unrealistic overpay");
        crowdsaleData.wallet.transfer(msg.value.sub(_overpaidRefund));
        
         
        msg.sender.transfer(_overpaidRefund);
    }

 
 
 

     
    function endCrowdsale() public onlyOwner onlyActive {
        updateFromAssetToken();

        crowdsaleData.state = CrowdsaleL.State.Ended;

        emit Ended();
    }


 
 
 

     
    function finalizeCrowdsale() public {
        updateFromAssetToken();  

        require(crowdsaleData.state == CrowdsaleL.State.Ended || crowdsaleData.state == CrowdsaleL.State.Started, "state");
        require(hasEnded(), "not ended");
        crowdsaleData.state = CrowdsaleL.State.Finalized;
        
        finalization();
        emit Finalized();
    }

     
     
    function hasEnded() public view returns (bool) {
        return crowdsaleData.hasEnded();
    }

     
     
     
    function finalization() internal {
    }
    
 
 
 

     
     
    function closeCrowdsale() public onlyOwner {
        crowdsaleData.closeCrowdsale();
    }

 
 
 

     
     
     
    function rescueToken(address _foreignTokenAddress, address _to)
    public
    onlyTokenRescueControl
    {
        crowdsaleData.rescueToken(_foreignTokenAddress, _to);
    }
}

 

 

 
contract AssignTokensOffChainPaymentFeature {

 
 
 

    modifier assignTokensPrerequisit {
        require(_assignTokensPrerequisit(), "assign prerequisit");
        _;
    }

 
 
 

     
     
    function assignTokensOffChainPayment(
        address _beneficiaryWallet, 
        uint256 _tokenAmount,
        bytes8 _tag) 
        public 
        assignTokensPrerequisit
    {
        _assignTokensOffChainPaymentAct(_beneficiaryWallet, _tokenAmount, _tag);
    }

 
 
 

     
    function _assignTokensPrerequisit() internal view returns (bool) {
        revert("override assignTokensPrerequisit");
    }

     
    function _assignTokensOffChainPaymentAct(address  , uint256  , bytes8  ) 
        internal returns (bool)
    {
        revert("override buyTokensWithEtherAct");
    }
}

 

 
contract AssetTokenCrowdsaleT001 is BasicAssetTokenCrowdsaleNoFeature, AssignTokensOffChainPaymentFeature {

 
 
 

    constructor(address _assetToken) public BasicAssetTokenCrowdsaleNoFeature(_assetToken) {

    }

 
 
 

     
    function _assignTokensPrerequisit() internal view returns (bool) {
        return (_isTokenAssignmentControl() && _isActiveOrDraftState());
    }

     
    function _assignTokensOffChainPaymentAct(address _beneficiaryWallet, uint256 _tokenAmount, bytes8 _tag)
        internal returns (bool) 
    {
        crowdsaleData.assignTokens(_beneficiaryWallet, _tokenAmount, _tag);
        return true;
    }
}