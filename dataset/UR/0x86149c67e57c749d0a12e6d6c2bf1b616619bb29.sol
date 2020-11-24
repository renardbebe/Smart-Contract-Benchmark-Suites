 

pragma solidity 0.5.11;

library AddressCalc {


    function futureAddressCalc(address payable _origin, uint _nonce) internal pure  returns (address) {

        if(_nonce == 0x00) return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xd6),
         byte(0x94), _origin, byte(0x80)))))));

        if(_nonce <= 0x7f) return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xd6),
         byte(0x94), _origin, byte(uint8(_nonce))))))));

        if(_nonce <= 0xff) return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xd7),
         byte(0x94), _origin, byte(0x81), uint8(_nonce)))))));

        if(_nonce <= 0xffff) return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xd8),
         byte(0x94), _origin, byte(0x82), uint16(_nonce)))))));

        if(_nonce <= 0xffffff) return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xd9),
         byte(0x94), _origin, byte(0x83), uint24(_nonce)))))));

		return address(uint160(uint256((keccak256(abi.encodePacked(byte(0xda), byte(0x94), _origin, byte(0x84), uint32(_nonce)))))));
    }

}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract BNY   {
    using SafeMath for uint256;
    using AddressCalc for address payable;
    event Deposit(
        address indexed _investor,
        uint256 _investmentValue,
        uint256 _ID,
        uint256 _unlocktime,
        string _investmentTerm
    );
    event PassiveDeposit(
        address indexed _investor2,
        uint256 _investmentValue2,
        uint256 _ID2,
        uint256 _unlocktime2,
        uint256 _dailyIncome,
        uint256 _investmentTime
    );
    event Spent(
        address indexed _acclaimer,
        uint256 indexed _amout
    );
    event PassiveSpent(
        address indexed _acclaimer2,
        uint256 indexed _amout2
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    string constant public name = "BANCACY";
    string constant public symbol = "BNY";
    string constant public standard = "BNY Token";
    uint256 constant public decimals = 18 ;
    uint256 private _totalSupply;
    uint256 public totalInvestmentAfterInterest;
    uint256 public investorIndex = 1;
    uint256 public passiveInvestorIndex = 1;
    uint256 constant public interestRate = 16;
    uint256 constant public multiplicationForMidTerm  = 5;
    uint256 constant public multiplicationForLongTerm = 20;
    uint256 public minForPassive = 1200000 * (10 ** uint256(decimals));
    uint256 public tokensForSale = 534600000 * (10 ** uint256(decimals));
    uint256 public tokensSold = 1 * (10 ** uint256(decimals));
    uint256 constant public tokensPerWei = 54000;
  	uint256 constant public Percent = 1000000000;
    uint256 constant internal secondsInDay = 86400;
    uint256 constant internal secondsInWeek = 604800;
    uint256 constant internal secondsInMonth = 2419200;
    uint256 constant internal secondsInQuarter = 7257600;
	uint256 constant internal daysInYear = 365;
    uint256 internal _startSupply = 455400000 * (10 ** uint256(decimals));
    address payable public fundsWallet;
    address public XBNY;
    address public BNY_DATA;

	enum TermData {DEFAULT, ONE, TWO, THREE}

    mapping(uint256 => Investment) private investors;
    mapping(uint256 => PassiveIncome) private passiveInvestors;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    struct Investment {
        address investorAddress;
        uint256 investedAmount;
        uint256 investmentUnlocktime;
        bool spent;
        string term;
    }
    struct PassiveIncome {
        address investorAddress2;
        uint256 investedAmount2;
        uint256 dailyPassiveIncome;
        uint256 investmentTimeStamp;
        uint256 investmentUnlocktime2;
        uint256 day;
        bool spent2;
    }
    constructor (address payable _fundsWallet)  public {
        _totalSupply = _startSupply;
        fundsWallet = _fundsWallet;
        _balances[fundsWallet] = _startSupply;
        _balances[address(1)] = 0;
        emit Transfer(
            address(1),
            fundsWallet,
            _startSupply
        );
        XBNY = _msgSender().futureAddressCalc(1);
        BNY_DATA = _msgSender().futureAddressCalc(2);
    }
    function () external payable{
        require(tokensSold < tokensForSale, "All tokens are sold");
        require(msg.value > 0, "Value must be > 0");
        uint256 eth = msg.value;
        uint256 tokens = eth.mul(tokensPerWei);
        uint256 bounosTokens = getDiscountOnBuy(tokens);
		uint256 totalTokens = bounosTokens.add(tokens);
        require(totalTokens <= (tokensForSale).sub(tokensSold), "All tokens are sold");
        fundsWallet.transfer(msg.value);
        tokensSold = tokensSold.add((totalTokens));
        _totalSupply = _totalSupply.add((totalTokens));
        _balances[_msgSender()] = _balances[_msgSender()].add((totalTokens));
        emit Transfer(
            address(0),
            _msgSender(),
            totalTokens
        );
    }
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }
     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
	 
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
	 
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
	 
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
	 
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	 
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
	 
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
	function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function makeInvestment(uint256 _unlockTime, uint256 _amount, uint term123) external returns (uint256) {
        require(_balances[_msgSender()] >= _amount, "You dont have sufficent amount of tokens");
        require(_amount > 0, "Investment amount should be bigger than 0");
        require(_unlockTime >= secondsInWeek && (_unlockTime.mod(secondsInWeek)) == 0, "Wrong investment time");
         
        uint256 termAfter = (_unlockTime.div(secondsInWeek));
        uint256 currentInvestor = investorIndex;

         
        if((termAfter >= 1) &&
		(termAfter <= 48) &&
		(term123 == uint(TermData.ONE)))
        {
            investorIndex++;
            totalInvestmentAfterInterest = _amount.add(getInterestRate(_amount, termAfter));
            investors[currentInvestor] = Investment(
                _msgSender(),
                totalInvestmentAfterInterest,
                block.timestamp.add(_unlockTime),
                false,
                "short"
            );
            emit Deposit(_msgSender(),
                _amount,
                currentInvestor,
                block.timestamp.add(_unlockTime),
                "SHORT-TERM"
            );
            emit Transfer(
                _msgSender(),
                address(1),
                _amount
            );
            emit Transfer(
                address(1),
                address(1),
                totalInvestmentAfterInterest.sub(_amount)
            );
            _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
            _balances[address(1)] = _balances[address(1)].add(totalInvestmentAfterInterest);
            _totalSupply = _totalSupply.sub(_amount);
            return (currentInvestor);
        }
         
        termAfter = (_unlockTime.div(secondsInMonth));
         
        if((_unlockTime >= secondsInMonth) &&
		(term123 == uint(TermData.TWO)) &&
		(termAfter <= 12 ) &&
		(_unlockTime.mod(secondsInMonth)) == 0) {
            investorIndex++;
            totalInvestmentAfterInterest = _amount.add(getInterestRate(_amount, multiplicationForMidTerm).mul(termAfter));
            investors[currentInvestor] = Investment(
                _msgSender(),
                totalInvestmentAfterInterest,
                block.timestamp.add(_unlockTime),
                false,
                "mid"
            );
            emit Deposit(
                _msgSender(),
                _amount,
                currentInvestor,
                block.timestamp.add(_unlockTime),
                "MID-TERM"
            );
            emit Transfer(
                _msgSender(),
                address(1),
                _amount
            );
            emit Transfer(
                address(1),
                address(1),
                totalInvestmentAfterInterest.sub(_amount)
            );
            _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
            _balances[address(1)] = _balances[address(1)].add(totalInvestmentAfterInterest);
            _totalSupply = _totalSupply.sub(_amount);
            return (currentInvestor);
        }


         
        termAfter = (_unlockTime.div(secondsInQuarter));
         
        if((_unlockTime >= secondsInQuarter) &&
		(term123 == uint(TermData.THREE)) &&
		(termAfter <= 12 ) &&
		(_unlockTime.mod(secondsInQuarter) == 0)) {
            investorIndex++;
            totalInvestmentAfterInterest = _amount.add(getInterestRate(_amount, multiplicationForLongTerm).mul(termAfter));
            investors[currentInvestor] = Investment(
                _msgSender(),
                totalInvestmentAfterInterest,
                block.timestamp.add(_unlockTime),
                false,
                "long"
            );
            emit Deposit(
                _msgSender(),
                _amount,
                currentInvestor,
                block.timestamp.add(_unlockTime),
                "LONG-TERM"
            );
            emit Transfer(
                _msgSender(),
                address(1),
                _amount
            );
            emit Transfer(
                address(1),
                address(1),
                totalInvestmentAfterInterest.sub(_amount)
            );
            _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
            _balances[address(1)] = _balances[address(1)].add(totalInvestmentAfterInterest);
            _totalSupply = _totalSupply.sub(_amount);
            return (currentInvestor);
        }
    }
    function releaseInvestment(uint256 _investmentId) external returns (bool success) {
        require(investors[_investmentId].investorAddress == _msgSender(), "Only the investor can claim the investment");
        require(investors[_investmentId].spent == false, "The investment is already spent");
        require(investors[_investmentId].investmentUnlocktime < block.timestamp, "Unlock time for the investment did not pass");
        investors[_investmentId].spent = true;
        _totalSupply = _totalSupply.add(investors[_investmentId].investedAmount);
        _balances[address(1)] = _balances[address(1)].sub(investors[_investmentId].investedAmount);
        _balances[_msgSender()] = _balances[_msgSender()].add(investors[_investmentId].investedAmount);
        emit Transfer(
            address(1),
            _msgSender(),
            investors[_investmentId].investedAmount
        );
        emit Spent(
            _msgSender(),
            investors[_investmentId].investedAmount
        );
        return true;
    }
    function makePassiveIncomeInvestment(uint256 _amount) external returns (uint256) {
        require(_balances[_msgSender()] >= _amount, "You  have insufficent amount of tokens");
        require(_amount >= minForPassive, "Investment amount should be bigger than 1.2M");
        uint256 interestOnInvestment = getInterestRate(_amount, 75).div(daysInYear);
        uint256 currentInvestor = passiveInvestorIndex;
        passiveInvestorIndex++;
        passiveInvestors[currentInvestor] = PassiveIncome(
            _msgSender(),
            _amount,
            interestOnInvestment,
            block.timestamp,
            block.timestamp.add(secondsInDay * daysInYear),
            1,
            false
        );
        emit Transfer(
            _msgSender(),
            address(1),
            _amount
        );
        emit Transfer(
            address(1),
            address(1),
            interestOnInvestment.mul(daysInYear)
        );
        emit PassiveDeposit(
            _msgSender(),
            _amount,
            currentInvestor,
            block.timestamp.add((secondsInDay * daysInYear)),
            passiveInvestors[currentInvestor].dailyPassiveIncome,
            passiveInvestors[currentInvestor].investmentTimeStamp
        );
        _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
        _balances[address(1)] = _balances[address(1)].add((interestOnInvestment.mul(daysInYear)).add(_amount));
        _totalSupply = _totalSupply.sub(_amount);
        return (currentInvestor);
    }
    function releasePassiveIncome(uint256 _passiveIncomeID) external returns (bool success) {
        require(passiveInvestors[_passiveIncomeID].investorAddress2 == _msgSender(), "Only the investor can claim the investment");
        require(passiveInvestors[_passiveIncomeID].spent2 == false, "The investment is already claimed");
        require(passiveInvestors[_passiveIncomeID].investmentTimeStamp.add((
        secondsInDay * passiveInvestors[_passiveIncomeID].day)) < block.timestamp,
        "Unlock time for the investment did not pass");
        require(passiveInvestors[_passiveIncomeID].day < 366, "The investment is already claimed");
        uint256 totalReward = 0;
        uint256 numberOfDaysHeld = (block.timestamp - passiveInvestors[_passiveIncomeID].investmentTimeStamp) / secondsInDay;
        if(numberOfDaysHeld > daysInYear){
            passiveInvestors[_passiveIncomeID].spent2 = true;
            numberOfDaysHeld = daysInYear;
            totalReward = passiveInvestors[_passiveIncomeID].investedAmount2;
        }
        uint numberOfDaysOwed = numberOfDaysHeld - (passiveInvestors[_passiveIncomeID].day - 1);
        uint totalDailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome * numberOfDaysOwed;
        passiveInvestors[_passiveIncomeID].day = numberOfDaysHeld.add(1);
        totalReward = totalReward.add(totalDailyPassiveIncome);
        if(totalReward > 0){
            _totalSupply = _totalSupply.add(totalReward);
            _balances[address(1)] = _balances[address(1)].sub(totalReward);
            _balances[_msgSender()] = _balances[_msgSender()].add(totalReward);
            emit Transfer(
                address(1),
                _msgSender(),
                totalReward
            );
            emit PassiveSpent(
                _msgSender(),
                totalReward
            );
            return true;
        }
        else{
            revert(
                "There is no total reward earned."
            );
        }
    }
    function BNY_AssetSolidification(address _user, uint256 _value) external returns (bool success) {
        require(_msgSender() == BNY_DATA, "No Permission");
        require(_balances[_user] >= _value, "User have incufficent balance");
        _balances[_user] = _balances[_user].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Transfer(
            _user,
            address(2),
            _value
        );
        return true;
    }
    function BNY_AssetDesolidification(address _user,uint256 _value) external returns (bool success) {
        require(_msgSender() == BNY_DATA, "No Permission");
        _balances[_user] = _balances[_user].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Transfer(
            address(2),
            _user,
            _value
        );
        return true;
    }
    function getBalanceOf(address _user) external view returns (uint256 balance) {
        require(_msgSender() == BNY_DATA, "No Permission");
        return _balances[_user];
    }
    function getPassiveDetails (uint _passiveIncomeID) external view returns (
        address investorAddress2,
        uint256 investedAmount2,
        uint256 dailyPassiveIncome,
        uint256 investmentTimeStamp,
        uint256 investmentUnlocktime2,
        uint256 day,
        bool spent2
    ){
        return(
            passiveInvestors[_passiveIncomeID].investorAddress2,
            passiveInvestors[_passiveIncomeID].investedAmount2,
            passiveInvestors[_passiveIncomeID].dailyPassiveIncome,
            passiveInvestors[_passiveIncomeID].investmentTimeStamp,
            passiveInvestors[_passiveIncomeID].investmentUnlocktime2,
            passiveInvestors[_passiveIncomeID].day,
            passiveInvestors[_passiveIncomeID].spent2
        );
    }
    function getPassiveIncomeDay(uint256 _passiveIncomeID) external view returns (uint256) {
        return(passiveInvestors[_passiveIncomeID].day);
    }
    function getPassiveIncomeStatus(uint256 _passiveIncomeID) external view returns (bool) {
        return (passiveInvestors[_passiveIncomeID].spent2);
    }
    function getPassiveInvestmentTerm(uint256 _passiveIncomeID) external view returns (uint256){
        return (passiveInvestors[_passiveIncomeID].investmentUnlocktime2);
    }
    function getPassiveNumberOfDays (uint _passiveIncomeID) external view returns (uint256){
        return (block.timestamp - passiveInvestors[_passiveIncomeID].investmentTimeStamp) / secondsInDay;
    }
    function getPassiveInvestmentTimeStamp(uint256 _passiveIncomeID) external view returns (uint256){
        return (passiveInvestors[_passiveIncomeID].investmentTimeStamp);
    }
    function getInvestmentStatus(uint256 _ID) external view returns (bool){
        return (investors[_ID].spent);
    }
    function getInvestmentTerm(uint256 _ID) external view returns (uint256){
        return (investors[_ID].investmentUnlocktime);
    }
    function getDiscountOnBuy(uint256 _tokensAmount) public view returns (uint256 discount) {
        uint256 tokensSoldADJ = tokensSold.mul(1000000000);
        uint256 discountPercentage = tokensSoldADJ.div(tokensForSale);
        uint256 adjustedDiscount = (Percent.sub(discountPercentage)).mul(2500);
        uint256 DiscountofTokens = (adjustedDiscount.mul(_tokensAmount));
        return((DiscountofTokens).div(10000000000000));
    }
    function getBlockTimestamp () external view returns (uint blockTimestamp){
        return block.timestamp;
    }
    function getInterestRate(uint256 _investment, uint _term) public view returns (uint256 rate) {
        require(_investment < _totalSupply, "The investment is too large");
        uint256 totalinvestments = _balances[address(1)].mul(Percent);
        uint256 investmentsPercentage = totalinvestments.div(_totalSupply);
        uint256 adjustedinterestrate = (Percent.sub(investmentsPercentage)).mul(interestRate);
        uint256 interestoninvestment = (adjustedinterestrate.mul(_investment)).div(10000000000000);
        return (interestoninvestment.mul(_term));
    }
    function getSimulatedDailyIncome (uint _passiveIncomeID) external view returns (
        uint _numberOfDaysHeld,
        uint _numberOfDaysOwed,
        uint _totalDailyPassiveIncome,
        uint _dailyPassiveIncome,
        uint _totalReward,
        uint _day,
        bool _spent
    ){
        _spent = false;
        _numberOfDaysHeld = (block.timestamp - passiveInvestors[_passiveIncomeID].investmentTimeStamp) / secondsInDay;
        if(_numberOfDaysHeld > daysInYear){
            _numberOfDaysHeld = daysInYear;
            _totalReward = passiveInvestors[_passiveIncomeID].investedAmount2;
            _spent = true;
        }
        _numberOfDaysOwed = _numberOfDaysHeld - (passiveInvestors[_passiveIncomeID].day - 1);
        _totalDailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome * _numberOfDaysOwed;
        _day = _numberOfDaysHeld.add(1);
        _totalReward = _totalReward.add(_totalDailyPassiveIncome);
        _dailyPassiveIncome = passiveInvestors[_passiveIncomeID].dailyPassiveIncome;
        return (
            _numberOfDaysHeld,
            _numberOfDaysOwed,
            _totalDailyPassiveIncome,
            _dailyPassiveIncome,
            _totalReward,
            _day,
            _spent
        );
    }
}