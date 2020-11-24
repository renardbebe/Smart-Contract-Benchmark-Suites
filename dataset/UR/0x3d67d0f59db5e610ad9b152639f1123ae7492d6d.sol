 

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

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

 

pragma solidity ^0.5.11;




contract CCP is Ownable {

   using SafeMath for uint256;

     

    event Staking(address indexed borrower, address tokenAddress, uint256 stakingAmount);
    event RefundStakings(address indexed borrower, address tokenAddress, uint256 refundAmount);
    event NewCredit(address indexed borrower, uint256 creditID, uint creditAmount);
    event NewCreditRule(address indexed lender, uint256 creditRuleID);
    event Payment(address indexed borrower, uint256 creditID, uint256 paidAmount);
    event LogSlashing(address indexed borrower, address tokenAddress, uint256 slashingAmount);
    event MinStakingChanged(address tokenAddress, uint256 timestamp, uint256 stakingAmount);


     
    struct CreditRule {
        address lenderAddress;
        uint256 startDate;
        uint256 endDate;
        uint256 validityPeriod;
        uint256 maxAmount;
        uint32 interestRate;
        uint32 lateRate;
        uint32 term;
        uint16 minAllowedScore;
    }

    struct Credit{
        address borrowerAddress;
        uint256 creditRuleID;
        uint256 timestamp;
        uint256 amount;
    }

     

     
    address public creditController;

     
    mapping(address => uint256) public minStakings;

     
    mapping(uint256 => CreditRule) public creditRules;

     
    mapping(uint256 => Credit) public credits;

     
     
    mapping(address => mapping(address => uint256)) public borrowerStakes;

     
     
    mapping(address => uint256) public slashsAndRefunds;

     
    modifier onlyCreditController(){
        require(msg.sender == creditController, "Only colendi can execute this transaction");
        _;
    }

    function stakeWithERC20(address borrower, address tokenAddress, uint amount) public {
        require(minStakings[tokenAddress] > 0, "Only eligible Erc20 token are allowed for staking");
        require(amount>0 && (amount >= minStakings[tokenAddress] || borrowerStakes[tokenAddress][borrower] > 0),
        "Requested amount is less than minimum");
        require(ERC20(tokenAddress).transferFrom(borrower,address(this), amount), "Not enough approved ERC20");
        borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].add(amount);
        emit Staking(borrower, tokenAddress, amount);
    }

     
    function stakeWithETH(address borrower) public payable {
        require(minStakings[address(0)] > 0 && ( msg.value >= minStakings[address(0)] || borrowerStakes[address(0)][borrower] > 0),
        "Can not stake less than minimum amount");
        borrowerStakes[address(0)][borrower] = borrowerStakes[address(0)][borrower].add(msg.value);
        emit Staking(borrower, address(0), msg.value);
    }


    function refundStakings (address borrower, address tokenAddress, uint amount) external onlyCreditController {
        require(borrowerStakes[tokenAddress][borrower] >= amount, "Borrower does not have these amount of stakings");
        if(tokenAddress == address(0)) {
            address(uint160(borrower)).transfer(amount);
            borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        }
        else{
            require(ERC20(tokenAddress).transfer(borrower, amount), "Not enough approved ERC20");
            borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        }
        emit RefundStakings(borrower, tokenAddress, amount);
    }

    function createCredit( address _borrower, uint256 _amount, uint256 _creditID, uint256 _creditRuleID, uint256 _timestamp)
    external onlyCreditController {
        require(credits[_creditID].borrowerAddress == address(0), "The credit has already been issued");
        require(creditRules[_creditRuleID].lenderAddress != address(0), "There is no such credit rule defined");
        Credit memory credit = Credit(
            {borrowerAddress: _borrower,
            creditRuleID : _creditRuleID,
            timestamp : _timestamp,
            amount : _amount
            });
        credits[_creditID] = credit;
        emit NewCredit(_borrower, _creditID, _amount);
    }

    function createCreditRule(
        address _lender,
        uint256 _creditRuleID,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _validityPeriod,
        uint256 _maxAmount,
        uint32 _interestRate,
        uint32 _lateRate,
        uint32 _term,
        uint16 _minAllowedScore)
    external onlyCreditController  {
        CreditRule memory creditRule = CreditRule({
            lenderAddress: _lender,
            startDate: _startDate,
            endDate: _endDate,
            validityPeriod: _validityPeriod,
            maxAmount:_maxAmount,
            interestRate: _interestRate,
            lateRate: _lateRate,
            term: _term,
            minAllowedScore: _minAllowedScore
        });
        require(creditRules[_creditRuleID].lenderAddress == address(0), "The credit rule has already been issued");

        creditRules[_creditRuleID] = creditRule;
        emit NewCreditRule(_lender, _creditRuleID);
    }

    function payBack( address _borrower, uint256 _creditID) public payable {
        require(credits[_creditID].borrowerAddress == _borrower, "No matching credit with provided address");
        slashsAndRefunds[address(0)] = slashsAndRefunds[address(0)].add(msg.value);
        emit Payment(_borrower, _creditID, msg.value);
    }

    function setMinimumStaking(address tokenAddress, uint256 _minStaking) external onlyCreditController {
        minStakings[tokenAddress] = _minStaking;
        emit MinStakingChanged(tokenAddress, now,  _minStaking);
    }

    function slashBorrower(address borrower, address tokenAddress, uint256 amount) external onlyCreditController {
        slashsAndRefunds[tokenAddress] = slashsAndRefunds[tokenAddress].add(amount);
        borrowerStakes[tokenAddress][borrower] = borrowerStakes[tokenAddress][borrower].sub(amount);
        emit LogSlashing(borrower, tokenAddress, amount);
    }

    function transferTokenFunds(address tokenAddress) external onlyCreditController {
        require(ERC20(tokenAddress).transfer(msg.sender, slashsAndRefunds[tokenAddress]), "Failed ERC20 transfer");
        slashsAndRefunds[tokenAddress] = 0;
    }

    function transferETHFunds() external onlyCreditController {
        address(uint160(msg.sender)).transfer(slashsAndRefunds[address(0)]);
        slashsAndRefunds[address(0)] = 0;
    }

    function transferColendiController(address _colendiController) public onlyOwner{
        creditController = _colendiController;
    }

}