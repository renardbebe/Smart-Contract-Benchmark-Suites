 

pragma solidity ^0.4.25;


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
        return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
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


 
contract CurrencyExchangeRate is Ownable {

    struct Currency {
        uint256 exRateToEther;  
        uint8 exRateDecimals;   
    }

    Currency[] public currencies;

    event CurrencyExchangeRateAdded(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    event CurrencyExchangeRateSet(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    constructor() public {
         
        currencies.push(
            Currency ({
                exRateToEther: 1,
                exRateDecimals: 0
            })
        );
         
        currencies.push(
            Currency ({
                exRateToEther: 30000,
                exRateDecimals: 2
            })
        );
    }

    function addCurrencyExchangeRate(
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateAdded(
            msg.sender, currencies.length, _exRateToEther, _exRateDecimals);
        currencies.push(
            Currency ({
                exRateToEther: _exRateToEther,
                exRateDecimals: _exRateDecimals
            })
        );
    }

    function setCurrencyExchangeRate(
        uint256 _currencyIndex,
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateSet(
            msg.sender, _currencyIndex, _exRateToEther, _exRateDecimals);
        currencies[_currencyIndex].exRateToEther = _exRateToEther;
        currencies[_currencyIndex].exRateDecimals = _exRateDecimals;
    }
}


 
contract KYC {
    
     
    function expireOf(address _who) external view returns (uint256);

     
    function kycLevelOf(address _who) external view returns (uint8);

     
    function nationalitiesOf(address _who) external view returns (uint256);

     
    function setKYC(
        address _who, uint256 _expiresAt, uint8 _level, uint256 _nationalities) 
        external;

    event KYCSet (
        address indexed _setter,
        address indexed _who,
        uint256 _expiresAt,
        uint8 _level,
        uint256 _nationalities
    );
}


 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract EtherVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    address public wallet;
    State public state;

    event Closed(address indexed commissionWallet, uint256 commission);
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address _wallet) public {
        require(
            _wallet != address(0),
            "Failed to create Ether vault due to wallet address is 0x0."
        );
        wallet = _wallet;
        state = State.Active;
    }

    function deposit() public onlyOwner payable {
        require(
            state == State.Active,
            "Failed to deposit Ether due to state is not Active."
        );
    }

    function close(address _commissionWallet, uint256 _commission) public onlyOwner {
        require(
            state == State.Active,
            "Failed to close due to state is not Active."
        );
        state = State.Closed;
        emit Closed(_commissionWallet, _commission);
        _commissionWallet.transfer(address(this).balance.mul(_commission).div(100));
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() public onlyOwner {
        require(
            state == State.Active,
            "Failed to enable refunds due to state is not Active."
        );
        emit RefundsEnabled();
        state = State.Refunding;        
    }

    function refund(address investor, uint256 depositedValue) public onlyOwner {
        require(
            state == State.Refunding,
            "Failed to refund due to state is not Refunding."
        );
        emit Refunded(investor, depositedValue);
        investor.transfer(depositedValue);        
    }
}



 
contract IcoRocketFuel is Ownable {
    using SafeMath for uint256;

     
    enum States {Ready, Active, Paused, Refunding, Closed}
    States public state = States.Ready;

     
     
    ERC20 public token = ERC20(0x0e27b0ca1f890d37737dd5cde9de22431255f524);

     
     
    address public crowdsaleOwner = 0xf75589cac3b23f24de65fe5a3cd07966728071a3;

     
     
    address public commissionWallet = 0xf75589cac3b23f24de65fe5a3cd07966728071a3;

     
     
     
     
    uint256 public baseExRate = 20;    
    uint8 public baseExRateDecimals = 0;

     
     
     
     
    CurrencyExchangeRate public exRate = CurrencyExchangeRate(0x44802e3d6fb67bd8ee7b24033ee04b1290692fd9);
     
     
     
    uint256 public currency = 1;

     
    uint256 public raised = 0;
     
    uint256 public cap = 25000000 * (10**18);
     
    uint256 public goal = 0;
     
    uint256 public minInvest = 50000 * (10**18);
    
     
    uint256 public closingTime = 1548979200;
     
    bool public earlyClosure = true;

     
    uint8 public commission = 10;

     
     
     
     
    KYC public kyc = KYC(0x8df3064451f840285993e2a4cfc0ec56b267d288);

     
     
     
     
     
     
     
     
     
    uint256 public countryBlacklist = 27606985387965724171868518586879082855975017189942647717541493312847872;

     
     
     
     
    uint8 public kycLevel = 100;

     
     
    bool public legalPersonSkipsCountryCheck = true;

     
     
    mapping(address => uint256) public deposits;
     
    EtherVault public vault;
    
     
     
    mapping(address => uint256) public invests;
     
     
    mapping(address => uint256) public tokenUnits;
     
     
    uint256 public totalTokenUnits = 0;

     
    struct BonusTier {
        uint256 investSize;  
        uint256 bonus;       
    }
     
    BonusTier[] public bonusTiers;

    event StateSet(
        address indexed setter, 
        States oldState, 
        States newState
    );

    event CrowdsaleStarted(
        address indexed icoTeam
    );

    event TokenBought(
        address indexed buyer, 
        uint256 valueWei, 
        uint256 valueCurrency
    );

    event TokensRefunded(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event Finalized(
        address indexed icoTeam
    );

    event SurplusTokensRefunded(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event CrowdsaleStopped(
        address indexed owner
    );

    event TokenClaimed(
        address indexed beneficiary,
        uint256 valueTokenUnit
    );

    event RefundClaimed(
        address indexed beneficiary,
        uint256 valueWei
    );

    modifier onlyCrowdsaleOwner() {
        require(
            msg.sender == crowdsaleOwner,
            "Failed to call function due to permission denied."
        );
        _;
    }

    modifier inState(States _state) {
        require(
            state == _state,
            "Failed to call function due to crowdsale is not in right state."
        );
        _;
    }

    constructor() public {
         
        bonusTiers.push(
            BonusTier({
                investSize: 400000 * (10**18),
                bonus: 50
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 200000 * (10**18),
                bonus: 40
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 100000 * (10**18),
                bonus: 30
            })
        );
        bonusTiers.push(
            BonusTier({
                investSize: 50000 * (10**18),
                bonus: 20
            })
        );
    }

    function setAddress(
        address _token,
        address _crowdsaleOwner,
        address _commissionWallet,
        address _exRate,
        address _kyc
    ) external onlyOwner inState(States.Ready){
        token = ERC20(_token);
        crowdsaleOwner = _crowdsaleOwner;
        commissionWallet = _commissionWallet;
        exRate = CurrencyExchangeRate(_exRate);
        kyc = KYC(_kyc);
    }

    function setSpecialOffer(
        uint256 _currency,
        uint256 _cap,
        uint256 _goal,
        uint256 _minInvest,
        uint256 _closingTime
    ) external onlyOwner inState(States.Ready) {
        currency = _currency;
        cap = _cap;
        goal = _goal;
        minInvest = _minInvest;
        closingTime = _closingTime;
    }

    function setInvestRestriction(
        uint256 _countryBlacklist,
        uint8 _kycLevel,
        bool _legalPersonSkipsCountryCheck
    ) external onlyOwner inState(States.Ready) {
        countryBlacklist = _countryBlacklist;
        kycLevel = _kycLevel;
        legalPersonSkipsCountryCheck = _legalPersonSkipsCountryCheck;
    }

    function setState(uint256 _state) external onlyOwner {
        require(
            uint256(state) < uint256(States.Refunding),
            "Failed to set state due to crowdsale was finalized."
        );
        require(
             
            uint256(States.Active) == _state || uint256(States.Paused) == _state,
            "Failed to set state due to invalid index."
        );
        emit StateSet(msg.sender, state, States(_state));
        state = States(_state);
    }

     
    function _getBonus(uint256 _investSize, uint256 _tokenUnits) 
        private view returns (uint256) 
    {
        for (uint256 _i = 0; _i < bonusTiers.length; _i++) {
            if (_investSize >= bonusTiers[_i].investSize) {
                return _tokenUnits.mul(bonusTiers[_i].bonus).div(100);
            }
        }
        return 0;
    }

     
    function startCrowdsale()
        external
        onlyCrowdsaleOwner
        inState(States.Ready)
    {
        emit CrowdsaleStarted(msg.sender);
        vault = new EtherVault(msg.sender);
        state = States.Active;
    }

     
    function buyToken()
        external
        inState(States.Active)
        payable
    {
         
         
        if (kycLevel > 0) {
            require(
                 
                block.timestamp < kyc.expireOf(msg.sender),
                "Failed to buy token due to KYC was expired."
            );
        }

        require(
            kycLevel <= kyc.kycLevelOf(msg.sender),
            "Failed to buy token due to require higher KYC level."
        );

        require(
            countryBlacklist & kyc.nationalitiesOf(msg.sender) == 0 || (
                kyc.kycLevelOf(msg.sender) >= 200 && legalPersonSkipsCountryCheck
            ),
            "Failed to buy token due to country investment restriction."
        );

         
        (uint256 _exRate, uint8 _exRateDecimals) = exRate.currencies(currency);

         
        uint256 _investSize = (msg.value)
            .mul(_exRate).div(10**uint256(_exRateDecimals));

        require(
            _investSize >= minInvest,
            "Failed to buy token due to less than minimum investment."
        );

        require(
            raised.add(_investSize) <= cap,
            "Failed to buy token due to exceed cap."
        );

        require(
             
            block.timestamp < closingTime,
            "Failed to buy token due to crowdsale is closed."
        );

         
        invests[msg.sender] = invests[msg.sender].add(_investSize);
         
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
         
        raised = raised.add(_investSize);

         
        uint256 _previousTokenUnits = tokenUnits[msg.sender];

         
        uint256 _tokenUnits = invests[msg.sender]
            .mul(baseExRate)
            .div(10**uint256(baseExRateDecimals));

         
        uint256 _tokenUnitsWithBonus = _tokenUnits.add(
            _getBonus(invests[msg.sender], _tokenUnits));

         
        tokenUnits[msg.sender] = _tokenUnitsWithBonus;

         
        totalTokenUnits = totalTokenUnits
            .sub(_previousTokenUnits)
            .add(_tokenUnitsWithBonus);

        emit TokenBought(msg.sender, msg.value, _investSize);

         
        vault.deposit.value(msg.value)();
    }

     
    function _refundTokens()
        private
        inState(States.Refunding)
    {
        uint256 _value = token.balanceOf(address(this));
        emit TokensRefunded(crowdsaleOwner, _value);
        if (_value > 0) {         
             
            token.transfer(crowdsaleOwner, _value);
        }
    }

     
    function finalize()
        external
        inState(States.Active)        
        onlyCrowdsaleOwner
    {
        require(
             
            earlyClosure || block.timestamp >= closingTime,                   
            "Failed to finalize due to crowdsale is opening."
        );

        emit Finalized(msg.sender);

        if (raised >= goal && token.balanceOf(address(this)) >= totalTokenUnits) {
             
            state = States.Closed;

             
            uint256 _balance = token.balanceOf(address(this));
            uint256 _surplus = _balance.sub(totalTokenUnits);
            emit SurplusTokensRefunded(crowdsaleOwner, _surplus);
            if (_surplus > 0) {
                 
                token.transfer(crowdsaleOwner, _surplus);
            }
             
            vault.close(commissionWallet, commission);
        } else {
            state = States.Refunding;
            _refundTokens();
            vault.enableRefunds();
        }
    }

     
    function stopCrowdsale()  
        external
        onlyOwner
        inState(States.Paused)
    {
        emit CrowdsaleStopped(msg.sender);
        state = States.Refunding;
        _refundTokens();
        vault.enableRefunds();
    }

     
    function claimToken()
        external 
        inState(States.Closed)
    {
        require(
            tokenUnits[msg.sender] > 0,
            "Failed to claim token due to token unit is 0."
        );
        uint256 _value = tokenUnits[msg.sender];
        tokenUnits[msg.sender] = 0;
        emit TokenClaimed(msg.sender, _value);
        token.transfer(msg.sender, _value);
    }

     
    function claimRefund()
        external
        inState(States.Refunding)
    {
        require(
            deposits[msg.sender] > 0,
            "Failed to claim refund due to deposit is 0."
        );

        uint256 _value = deposits[msg.sender];
        deposits[msg.sender] = 0;
        emit RefundClaimed(msg.sender, _value);
        vault.refund(msg.sender, _value);
    }
}