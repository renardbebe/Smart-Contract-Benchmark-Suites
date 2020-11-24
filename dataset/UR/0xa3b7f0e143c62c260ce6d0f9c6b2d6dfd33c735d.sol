 

pragma solidity 0.4.24;

 
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


 
contract Escrow is Ownable {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private deposits;

     
    function deposit(address _payee) public onlyOwner payable {
        uint256 amount = msg.value;
        deposits[_payee] = deposits[_payee].add(amount);

        emit Deposited(_payee, amount);
    }

     
    function withdraw(address _payee) public onlyOwner returns(uint256) {
        uint256 payment = deposits[_payee];

        assert(address(this).balance >= payment);

        deposits[_payee] = 0;

        _payee.transfer(payment);

        emit Withdrawn(_payee, payment);
        return payment;
    }

     
    function beneficiaryWithdraw(address _wallet) public onlyOwner {
        uint256 _amount = address(this).balance;
        
        _wallet.transfer(_amount);

        emit Withdrawn(_wallet, _amount);
    }

     
    function depositsOf(address _payee) public view returns(uint256) {
        return deposits[_payee];
    }
}

 
contract PullPayment {
    Escrow private escrow;

    constructor() public {
        escrow = new Escrow();
    }

     
    function payments(address _dest) public view returns(uint256) {
        return escrow.depositsOf(_dest);
    }

     
    function _withdrawPayments(address _payee) internal returns(uint256) {
        uint256 payment = escrow.withdraw(_payee);

        return payment;
    }

     
    function _asyncTransfer(address _dest, uint256 _amount) internal {
        escrow.deposit.value(_amount)(_dest);
    }

     
    function _withdrawFunds(address _wallet) internal {
        escrow.beneficiaryWithdraw(_wallet);
    }
}

 
contract VestedCrowdsale {
    using SafeMath for uint256;

    mapping (address => uint256) public withdrawn;
    mapping (address => uint256) public contributions;
    mapping (address => uint256) public contributionsRound;
    uint256 public vestedTokens;

     
    function getWithdrawableAmount(address _beneficiary) public view returns(uint256) {
        uint256 step = _getVestingStep(_beneficiary);
        uint256 valueByStep = _getValueByStep(_beneficiary);
        uint256 result = step.mul(valueByStep).sub(withdrawn[_beneficiary]);

        return result;
    }

     
    function _getVestingStep(address _beneficiary) internal view returns(uint8) {
        require(contributions[_beneficiary] != 0);
        require(contributionsRound[_beneficiary] > 0 && contributionsRound[_beneficiary] < 4);

        uint256 march31 = 1554019200;
        uint256 april30 = 1556611200;
        uint256 may31 = 1559289600;
        uint256 june30 = 1561881600;
        uint256 july31 = 1564560000;
        uint256 sept30 = 1569830400;
        uint256 contributionRound = contributionsRound[_beneficiary];

         
        if (contributionRound == 1) {
            if (block.timestamp < march31) {
                return 0;
            }
            if (block.timestamp < june30) {
                return 1;
            }
            if (block.timestamp < sept30) {
                return 2;
            }

            return 3;
        }
         
        if (contributionRound == 2) {
            if (block.timestamp < april30) {
                return 0;
            }
            if (block.timestamp < july31) {
                return 1;
            }

            return 2;
        }
         
        if (contributionRound == 3) {
            if (block.timestamp < may31) {
                return 0;
            }

            return 1;
        }
    }

     
    function _getValueByStep(address _beneficiary) internal view returns(uint256) {
        require(contributions[_beneficiary] != 0);
        require(contributionsRound[_beneficiary] > 0 && contributionsRound[_beneficiary] < 4);

        uint256 contributionRound = contributionsRound[_beneficiary];
        uint256 amount;
        uint256 rate;

        if (contributionRound == 1) {
            rate = 416700;
            amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
            return amount;
        } else if (contributionRound == 2) {
            rate = 312500;
            amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
            return amount;
        }

        rate = 250000;
        amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
        return amount;
    }
}

 
contract Whitelist is Ownable {
     
    mapping(address => bool) public whitelist;

    event AddedBeneficiary(address indexed _beneficiary);
    event RemovedBeneficiary(address indexed _beneficiary);

     
    function addAddressToWhitelist(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;

            emit AddedBeneficiary(_beneficiaries[i]);
        }
    }

     
    function addToWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = true;

        emit AddedBeneficiary(_beneficiary);
    }

     
    function removeFromWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = false;

        emit RemovedBeneficiary(_beneficiary);
    }
}

 
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

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 
contract DSLACrowdsale is VestedCrowdsale, Whitelist, Pausable, PullPayment {
     
    struct IcoRound {
        uint256 rate;
        uint256 individualFloor;
        uint256 individualCap;
        uint256 softCap;
        uint256 hardCap;
    }

     
    mapping (uint256 => IcoRound) public icoRounds;
     
    ERC20Burnable private _token;
     
    address private _wallet;
     
    uint256 private totalContributionAmount;
     
    uint256 public constant TOKENSFORSALE = 5000000000000000000000000000;
     
    uint256 public currentIcoRound;
     
    uint256 public distributedTokens;
     
    uint256 public weiRaisedFromOtherCurrencies;
     
    bool public isRefunding = false;
     
    bool public isFinalized = false;
     
    uint256 public refundDeadline;

     
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(address wallet, ERC20Burnable token) public {
        require(wallet != address(0) && token != address(0));

        icoRounds[1] = IcoRound(
            416700,
            3 ether,
            600 ether,
            0,
            1200 ether
        );

        icoRounds[2] = IcoRound(
            312500,
            12 ether,
            5000 ether,
            0,
            6000 ether
        );

        icoRounds[3] = IcoRound(
            250000,
            3 ether,
            30 ether,
            7200 ether,
            17200 ether
        );

        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _contributor) public payable {
        require(whitelist[_contributor]);

        uint256 contributionAmount = msg.value;

        _preValidatePurchase(_contributor, contributionAmount, currentIcoRound);

        totalContributionAmount = totalContributionAmount.add(contributionAmount);

        uint tokenAmount = _handlePurchase(contributionAmount, currentIcoRound, _contributor);

        emit TokensPurchased(msg.sender, _contributor, contributionAmount, tokenAmount);

        _forwardFunds();
    }

     
    function goToNextRound() public onlyOwner returns(bool) {
        require(currentIcoRound >= 0 && currentIcoRound < 3);

        currentIcoRound = currentIcoRound + 1;

        return true;
    }

     
    function addPrivateSaleContributors(address _contributor, uint256 _contributionAmount)
    public onlyOwner
    {
        uint privateSaleRound = 1;
        _preValidatePurchase(_contributor, _contributionAmount, privateSaleRound);

        totalContributionAmount = totalContributionAmount.add(_contributionAmount);

        addToWhitelist(_contributor);

        _handlePurchase(_contributionAmount, privateSaleRound, _contributor);
    }

     
    function addOtherCurrencyContributors(address _contributor, uint256 _contributionAmount, uint256 _round)
    public onlyOwner
    {
        _preValidatePurchase(_contributor, _contributionAmount, _round);

        weiRaisedFromOtherCurrencies = weiRaisedFromOtherCurrencies.add(_contributionAmount);

        addToWhitelist(_contributor);

        _handlePurchase(_contributionAmount, _round, _contributor);
    }

     
    function closeRefunding() public returns(bool) {
        require(isRefunding);
        require(block.timestamp > refundDeadline);

        isRefunding = false;

        _withdrawFunds(wallet());

        return true;
    }

     
    function closeCrowdsale() public onlyOwner returns(bool) {
        require(currentIcoRound > 0 && currentIcoRound < 4);

        currentIcoRound = 4;

        return true;
    }

     
    function finalizeCrowdsale(bool _burn) public onlyOwner returns(bool) {
        require(currentIcoRound == 4 && !isRefunding);

        if (raisedFunds() < icoRounds[3].softCap) {
            isRefunding = true;
            refundDeadline = block.timestamp + 4 weeks;

            return true;
        }

        require(!isFinalized);

        _withdrawFunds(wallet());
        isFinalized = true;

        if (_burn) {
            _burnUnsoldTokens();
        } else {
            _withdrawUnsoldTokens();
        }

        return  true;
    }

     
    function claimRefund() public {
        require(isRefunding);
        require(block.timestamp <= refundDeadline);
        require(payments(msg.sender) > 0);

        uint256 payment = _withdrawPayments(msg.sender);

        totalContributionAmount = totalContributionAmount.sub(payment);
    }

     
    function claimTokens() public {
        require(getWithdrawableAmount(msg.sender) != 0);

        uint256 amount = getWithdrawableAmount(msg.sender);
        withdrawn[msg.sender] = withdrawn[msg.sender].add(amount);

        _deliverTokens(msg.sender, amount);
    }

     
    function token() public view returns(ERC20Burnable) {
        return _token;
    }

     
    function wallet() public view returns(address) {
        return _wallet;
    }

     
    function raisedFunds() public view returns(uint256) {
        return totalContributionAmount.add(weiRaisedFromOtherCurrencies);
    }

     
     
     
     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
    internal
    {
        _token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _forwardFunds()
    internal
    {
        if (currentIcoRound == 2 || currentIcoRound == 3) {
            _asyncTransfer(msg.sender, msg.value);
        } else {
            _wallet.transfer(msg.value);
        }
    }

     
    function _getTokensToDeliver(uint _tokenAmount, uint _round)
    internal pure returns(uint)
    {
        require(_round > 0 && _round < 4);
        uint deliverPercentage = _round.mul(25);

        return _tokenAmount.mul(deliverPercentage).div(100);
    }

     
    function _handlePurchase(uint _contributionAmount, uint _round, address _contributor)
    internal returns(uint) {
        uint256 soldTokens = distributedTokens.add(vestedTokens);
        uint256 tokenAmount = _getTokenAmount(_contributionAmount, _round);

        require(tokenAmount.add(soldTokens) <= TOKENSFORSALE);

        contributions[_contributor] = contributions[_contributor].add(_contributionAmount);
        contributionsRound[_contributor] = _round;

        uint tokensToDeliver = _getTokensToDeliver(tokenAmount, _round);
        uint tokensToVest = tokenAmount.sub(tokensToDeliver);

        distributedTokens = distributedTokens.add(tokensToDeliver);
        vestedTokens = vestedTokens.add(tokensToVest);

        _deliverTokens(_contributor, tokensToDeliver);

        return tokenAmount;
    }

     
    function _preValidatePurchase(address _contributor, uint256 _contributionAmount, uint _round)
    internal view
    {
        require(_contributor != address(0));
        require(currentIcoRound > 0 && currentIcoRound < 4);
        require(_round > 0 && _round < 4);
        require(contributions[_contributor] == 0);
        require(_contributionAmount >= icoRounds[_round].individualFloor);
        require(_contributionAmount < icoRounds[_round].individualCap);
        require(_doesNotExceedHardCap(_contributionAmount, _round));
    }

     
    function _getTokenAmount(uint256 _contributionAmount, uint256 _round)
    internal view returns(uint256)
    {
        uint256 _rate = icoRounds[_round].rate;
        return _contributionAmount.mul(_rate);
    }

     
    function _doesNotExceedHardCap(uint _contributionAmount, uint _round)
    internal view returns(bool)
    {
        uint roundHardCap = icoRounds[_round].hardCap;
        return totalContributionAmount.add(_contributionAmount) <= roundHardCap;
    }

     
    function _burnUnsoldTokens()
    internal
    {
        uint256 tokensToBurn = TOKENSFORSALE.sub(vestedTokens).sub(distributedTokens);

        _token.burn(tokensToBurn);
    }

     
    function _withdrawUnsoldTokens()
    internal {
        uint256 tokensToWithdraw = TOKENSFORSALE.sub(vestedTokens).sub(distributedTokens);

        _token.transfer(_wallet, tokensToWithdraw);
    }
}