 

 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;



 
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
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity ^0.5.2;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.2;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.2;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity ^0.5.2;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.2;




 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         

        require(address(token).isContract());

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)));
        }
    }
}

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.2;





 
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    uint256 private _supply;

     
    uint256 private _sold;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event RateUpdated(uint256 indexed rate);

     
    event CrowdsalePaused();
    event CrowdsaleUnpaused();

     
    constructor (uint256 rate, uint256 supply, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _supply = supply;
        _wallet = wallet;
        _token = token;
    }

     
    function() external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function supply() internal view returns (uint256) {
        return _supply;
    }

     
    function sold() public view returns (uint256) {
        return _sold;
    }

     
    function _addSold(uint256 tokenAmount) internal {
        _sold = _sold.add(tokenAmount);
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }


     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        uint256 surplus = _countSurplus(weiAmount);
        weiAmount -= surplus;

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds(weiAmount);
        _returnSurplus(surplus);

        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
        require(rate() > 0);
        require(_supply >= _sold + _getTokenAmount(weiAmount));  
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
        _addSold(tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _getWeiAmount(uint256 tokenAmount) internal view returns (uint256) {
        return tokenAmount.div(_rate);
    }

     
    function _forwardFunds(uint256 weiAmount) internal {
        _wallet.transfer(weiAmount);
    }

     
    function _countSurplus(uint256 weiAmount) internal returns (uint256){
         
    }

     
    function _returnSurplus(uint256 weiAmount) internal {
        if (weiAmount > 0) {
            msg.sender.transfer(weiAmount);
        }
    }

     
    function _changeRate(uint256 newRate) internal {
        if ((newRate > 0) && (_rate == 0)) {
            emit CrowdsaleUnpaused();
        } else if (newRate == 0) {
            emit CrowdsalePaused();
        }

        _rate = newRate;
        emit RateUpdated(newRate);
    }

}

 

pragma solidity ^0.5.2;

library Role {

    struct RoleContainer {
        address[] bearer;
    }

     
    function total (RoleContainer storage role) internal view returns (uint count) {
        for (uint i = 0; i < role.bearer.length; i++) {
            count += (role.bearer[i] == address(0)) ? 0 : 1;
        }
        return count;
    }


     
    function has(RoleContainer storage role, address account) internal view returns (bool) {
        require(account != address(0));
        address[] memory list = role.bearer;
        uint len = role.bearer.length;
        for (uint index = 0; index < len; index++) {
            if (list[index] == account) {
                return true;
            }
        }
        return false;
    }

     
    function add(RoleContainer storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer.push(account);
    }

     
    function remove(RoleContainer storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        removeFromList(role, account);
    }

     
    function removeFromList(RoleContainer storage role, address account) private {
        address[] storage list = role.bearer;
        uint len = role.bearer.length;

        for (uint index = 0; index <= len; index++) {
            if (list[index] != account) {
                continue;
            }
            list[index] = list[len - 1];
            delete list[len - 1];
            return;
        }
    }
}

 

pragma solidity ^0.5.2;

library Helpers {
    function majority(uint total) internal pure returns (uint) {
        return uint(total / 2) + 1;
    }

    function idFromAddress(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encode(addr));
    }

    function idFromUint256(uint256 x) internal pure returns (bytes32) {
        return keccak256(abi.encode(x));
    }

    function mixId(address addr, uint256 x) internal pure returns (bytes32) {
        return keccak256(abi.encode(addr, x));
    }
}

 

pragma solidity ^0.5.2;


library Votings {

    struct Voting {
        mapping(bytes32 => address[]) process;
    }

     
    function voteAndCheck(Voting storage voting,
        bytes32 index, address issuer, uint required) internal returns (bool)
    {
        vote(voting, index, issuer);
        return isComplete(voting, index, required);
    }

     
    function isComplete(Voting storage voting,
        bytes32 index, uint required) internal returns (bool)
    {
        if (voting.process[index].length < required) {
            return false;
        }

        delete voting.process[index];
        return true;
    }



     
    function vote(Voting storage voting,
        bytes32 index, address issuer) internal
    {
        require(!hadVoted(voting, index, issuer));
        voting.process[index].push(issuer);
    }

     
    function hadVoted(Voting storage voting,
        bytes32 index, address issuer) internal view returns (bool)
    {
        address[] storage _process = voting.process[index];

        for (uint ind = 0; ind < _process.length; ind++) {
            if (_process[ind] == issuer) {
                return true;
            }
        }

        return false;
    }
}

 

pragma solidity ^0.5.2;





contract AdminRole {
    using Role for Role.RoleContainer;
    using Votings for Votings.Voting;

     
    Role.RoleContainer private _admins;

     
    Votings.Voting private _addVoting;
    Votings.Voting private _expelVoting;

     
    event AdminAdded(address indexed account);

     
    event AdminRemoved(address indexed account);

    modifier AdminOnly() {
        require(isAdmin(msg.sender));
        _;
    }

    modifier WhileSetup() {
        require(isAdmin(msg.sender));
        require(countAdmins() == 1);
        _;
    }

    constructor () internal {
        _add(msg.sender);
    }

     
    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

     
    function listAdmins() public view returns (address[] memory) {
        return _admins.bearer;
    }

     
    function countAdmins() public view returns (uint) {
        return _admins.total();
    }

     
    function initAdmins(address[] memory defaultAdmins) WhileSetup internal {
        for (uint256 index = 0; index < defaultAdmins.length; index++) {
            _add(defaultAdmins[index]);
        }
    }

     
    function addAdmin(address account) AdminOnly public {
        if (_addAdminVoting(account)) {
            _add(account);
        }
    }

     
    function expelAdmin(address account) AdminOnly public {
        if (_expelAdminVoting(account)) {
            _expel(account);
        }
    }


     
    function _addAdminVoting(address account) private returns (bool) {
        return _addVoting.voteAndCheck(
            Helpers.idFromAddress(account),
            msg.sender,
            Helpers.majority(countAdmins())
        );
    }

     
    function _expelAdminVoting(address account) private returns (bool) {
        require(msg.sender != account);
        return _expelVoting.voteAndCheck(
            Helpers.idFromAddress(account),
            msg.sender,
            Helpers.majority(countAdmins())
        );
    }


     
    function _add(address account) private {
        _admins.add(account);
        emit AdminAdded(account);
    }

     
    function _expel(address account) private {
        _admins.remove(account);
        emit AdminRemoved(account);
    }


}

 

pragma solidity ^0.5.2;





contract InvestOnBehalf is AdminRole, Crowdsale {
    using Votings for Votings.Voting;

     
    Votings.Voting private _votings;

     
    event InvestedOnBehalf(address indexed account, uint256 indexed tokens);

     
    function consensus(address account, uint256 tokens) private returns (bool) {
        return _votings.voteAndCheck(Helpers.mixId(account, tokens), msg.sender, Helpers.majority(countAdmins()));
    }


     
    function investOnBehalf(address to, uint256 tokens) AdminOnly public {
        if (consensus(to, tokens)) {
            _processPurchase(to, tokens * 1e18);
            emit InvestedOnBehalf(to, tokens * 1e18);
        }
    }
}

 

pragma solidity ^0.5.2;



contract MilestonedCrowdsale is AdminRole, Crowdsale {
    event MilestoneReached(uint256 indexed milestone);

     
    struct Milestone {
        uint256 start;
        uint256 finish;
        bool fired;
    }

    Milestone[] private _milestones;

     
    function _newMilestone(uint256 start, uint256 finish) private {
        require(start < finish);
        _milestones.push(Milestone(start, finish, false));
    }

     
    function initMilestones(uint256[] memory milestones) WhileSetup internal {
        for (uint256 index = 0; index < milestones.length - 1; index++) {
            _newMilestone(milestones[index], milestones[index + 1]);
        }
    }

     
    function _countSurplus(uint256 weiAmount) internal returns (uint256){
        return _getMilestoneOverhead(weiAmount);
    }

     
    function _returnSurplus(uint256 weiAmount) internal {
        super._returnSurplus(weiAmount);

        if (weiAmount > 0) {
            _changeRate(0);
        }
    }

     
    function _getMilestoneOverhead(uint256 weiAmount) private returns (uint256){
        for (uint256 index = 0; index < _milestones.length; index++) {
             
            if (_milestones[index].fired) {
                continue;
            }

            uint256 start = _milestones[index].start;
            uint256 finish = _milestones[index].finish;

            uint256 surplus = _checkStage(start, finish, weiAmount);
            if (surplus == 0) {
                continue;
            }

            _milestones[index].fired = true;
            emit MilestoneReached(finish);

            return surplus;
        }
    }

     
    function _checkStage(uint256 from, uint256 to, uint256 weiAmount) private view returns (uint256) {
        uint256 afterPayment = sold() + _getTokenAmount(weiAmount);
        bool inRange = (sold() >= from) && (sold() < to);

        if (inRange && (afterPayment >= to)) {
            return _getWeiAmount(afterPayment - to) + 1;
        }
    }
}

 

pragma solidity ^0.5.2;






contract UpdatableRateCrowdsale is AdminRole, Crowdsale {
    using Votings for Votings.Voting;

     
    Votings.Voting private _votings;

     
    function consensus(uint256 rate) private returns (bool) {
        return _votings.voteAndCheck(Helpers.idFromUint256(rate), msg.sender, Helpers.majority(countAdmins()));
    }

     
    function changeRate(uint256 rate) AdminOnly public {
        if (consensus(rate)) {
            _changeRate(rate);
        }
    }
}

 

pragma solidity ^0.5.2;



 
contract MintedCrowdsale is Crowdsale {
     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
         
        require(ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
    }
}

 

pragma solidity ^0.5.2;



contract SoftcappedCrowdsale is AdminRole, Crowdsale {
     
    uint256 private _goal;

     
     
    uint256 private _minimalPay = 0;

     
    constructor (uint256 goal) public {
        require(goal > 0);
        _goal = goal;
    }

     
    function goal() public view returns (uint256) {
        return _goal;
    }

     
    function minimalPay() public view returns (uint256) {
        return goalReached() ? 0 : _minimalPay;
    }

     
    function setMinimalPay(uint256 weiAmount) WhileSetup internal {
        _minimalPay = weiAmount;
    }

     
    function goalReached() public view returns (bool) {
        return sold() >= _goal;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);

        if (!goalReached() && _minimalPay != 0) {
            require(weiAmount >= _minimalPay);
        }
    }

}

 

pragma solidity ^0.5.2;



 
contract TimedCrowdsale is SoftcappedCrowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _softcapDeadline;
    uint256 private _closingTime;

     
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

     
    modifier onlyWhileOpen {
        require(!hasClosed());
        _;
    }

     
    constructor (uint256 openingTime, uint256 softcapDeadline, uint256 closingTime) public {
         
         
        require(softcapDeadline > openingTime);
        require(closingTime > softcapDeadline);

        _openingTime = openingTime;
        _softcapDeadline = softcapDeadline;
        _closingTime = closingTime;
    }

     
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function softcapDeadline() public view returns (uint256) {
        return _softcapDeadline;
    }

     
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }


     
    function hasClosed() public view returns (bool) {
         
        return ((block.timestamp > _softcapDeadline) && !goalReached()) ||
        ((block.timestamp > _closingTime) && goalReached());
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }


}

 

pragma solidity ^0.5.2;




 
contract FinalizableCrowdsale is AdminRole, TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor () internal {
        _finalized = false;
    }

     
    function finalized() public view returns (bool) {
        return _finalized;
    }

     
    function finalize() AdminOnly public {
        require(!_finalized);
        require(hasClosed() || goalReached());

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

     
    function _finalization() internal {
         
    }
}

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;



  
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

 

pragma solidity ^0.5.2;


 
contract ConditionalEscrow is Escrow {
     
    function withdrawalAllowed(address payee) public view returns (bool);

    function withdraw(address payable payee) public {
        require(withdrawalAllowed(payee));
        super.withdraw(payee);
    }
}

 

pragma solidity ^0.5.2;



 
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

     
    function beneficiaryWithdraw() public onlyPrimary {
        _beneficiary.transfer(address(this).balance);
    }

     
    function customWithdraw(uint256 etherAmount, address payable account) public onlyPrimary {
        account.transfer(etherAmount);
    }

     
    function withdrawalAllowed(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}

 

pragma solidity ^0.5.2;






 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;
    using Votings for Votings.Voting;

    event FundsWithdraw(uint256 indexed etherAmount, address indexed account);

     
    Votings.Voting private _votings;

     
    RefundEscrow private _escrow;

     
    constructor () public {
        _escrow = new RefundEscrow(wallet());
    }

     
    function claimRefund(address payable refundee) public {
        require(finalized());
        require(!goalReached());

        _escrow.withdraw(refundee);
    }

    function beneficiaryWithdraw(uint256 etherAmount, address payable account) AdminOnly public {
        if (goalReached() && consensus(etherAmount, address(account))) {
            _escrow.customWithdraw(etherAmount * 1e18, account);
            emit FundsWithdraw(etherAmount * 1e18, address(account));
        }
    }

     
    function _finalization() internal {
        if (goalReached()) {
            _escrow.close();
            _escrow.beneficiaryWithdraw();
        } else {
            uint256 day = 86400;
            require(block.timestamp > softcapDeadline() + day);
            _escrow.enableRefunds();
        }

        super._finalization();
    }

     
    function _forwardFunds(uint256 weiAmount) internal {
        _escrow.deposit.value(weiAmount)(msg.sender);
    }

     
    function consensus(uint256 etherAmount, address account) private returns (bool) {
        return _votings.voteAndCheck(
            Helpers.mixId(account, etherAmount),
            msg.sender,
            Helpers.majority(countAdmins())
        );
    }
}

 

pragma solidity ^0.5.2;



 
contract PostDeliveryCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

     
    mapping(address => uint256) private _balances;

     
    address[] private _backers;

     
    function withdrawTokens(address beneficiary) public {
        require(goalReached());
        uint256 amount = _balances[beneficiary];
        require(amount > 0);
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function backers() public view returns (address[] memory) {
        return _backers;
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        if (!goalReached()) {
            _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
            _backers.push(beneficiary);
            _addSold(tokenAmount);
            return;
        }
        super._processPurchase(beneficiary, tokenAmount);
    }
}

 

pragma solidity ^0.5.2;




 
contract RefundablePostDeliveryCrowdsale is RefundableCrowdsale, PostDeliveryCrowdsale {
    function withdrawTokens(address beneficiary) public {
        require(goalReached());
        super.withdrawTokens(beneficiary);
    }
}

 

pragma solidity ^0.5.2;







 

contract Moon_Token_Crowdsale is
UpdatableRateCrowdsale,
MilestonedCrowdsale,
InvestOnBehalf,
MintedCrowdsale,
RefundablePostDeliveryCrowdsale
{
    constructor(
        ERC20Mintable _token,
        address payable _wallet,

        uint256 _rate,
        uint256 _supply,
        uint256 _softcap,

        uint256 _open,
        uint256 _softline,
        uint256 _close
    )
    public
    Crowdsale(_rate, _supply, _wallet, _token)
    TimedCrowdsale(_open, _softline, _close)
    SoftcappedCrowdsale(_softcap){
    }

     
    function finishSetup(
        uint256 _minimalPay,
        uint256[] memory milestones,
        address[] memory admins
    ) WhileSetup public {
        setMinimalPay(_minimalPay);
        initMilestones(milestones);
        initAdmins(admins);
    }
}