 

pragma solidity ^0.4.23;

contract God {
     
     
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyProfitsHolders() {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event onInjectEtherFromIco(uint _incomingEthereum, uint _dividends, uint profitPerShare_);

    event onInjectEtherToDividend(address sender, uint _incomingEthereum, uint profitPerShare_);

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



     
    string public name = "God";
    string public symbol = "God";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;

     
    uint256 public stakingRequirement = 100e18;

    uint constant internal  MIN_TOKEN_TRANSFER = 1e10;


     
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    mapping(address => mapping(address => uint256)) internal allowed;

     
    address internal owner;
    mapping(address => bool) public administrators;

    address bankAddress;
    mapping(address => bool) public contractAddresses;

    int internal contractPayout = 0;

    bool internal isProjectBonus = true;
    uint internal projectBonus = 0;
    uint internal projectBonusRate = 10;   

     
    constructor()
    public
    {
         
        owner = msg.sender;
        administrators[owner] = true;
    }

     
    function buy(address _referredBy)
    public
    payable
    returns (uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }

     
    function()
    public
    payable
    {
        purchaseTokens(msg.value, 0x0);
    }

    function injectEtherFromIco()
    public
    payable
    {
        uint _incomingEthereum = msg.value;
        require(_incomingEthereum > 0);
        uint256 _dividends = SafeMath.div(_incomingEthereum, dividendFee_);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_dividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }
        profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
        emit onInjectEtherFromIco(_incomingEthereum, _dividends, profitPerShare_);
    }

    function injectEtherToDividend()
    public
    payable
    {
        uint _incomingEthereum = msg.value;
        require(_incomingEthereum > 0);
        profitPerShare_ += (_incomingEthereum * magnitude / (tokenSupply_));
        emit onInjectEtherToDividend(msg.sender, _incomingEthereum, profitPerShare_);
    }

    function injectEther()
    public
    payable
    {}

     
    function reinvest()
    onlyProfitsHolders()
    public
    {
         
        uint256 _dividends = myDividends(false);
         

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

         
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit()
    public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

         
        withdraw();
    }

     
    function withdraw()
    onlyProfitsHolders()
    public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
         

         
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        emit onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens)
    onlyTokenHolders()
    public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_dividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens)
    onlyTokenHolders()
    public
    returns (bool)
    {
        address _customerAddress = msg.sender;
        require(_amountOfTokens >= MIN_TOKEN_TRANSFER
        && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        bytes memory empty;
        transferFromInternal(_customerAddress, _toAddress, _amountOfTokens, empty);
        return true;
    }

    function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
    internal
    {
        require(_toAddress != address(0x0));
        uint fromLength;
        uint toLength;
        assembly {
            fromLength := extcodesize(_from)
            toLength := extcodesize(_toAddress)
        }

        if (fromLength > 0 && toLength <= 0) {
             
            contractAddresses[_from] = true;
            contractPayout -= (int) (_amountOfTokens);
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        } else if (fromLength <= 0 && toLength > 0) {
             
            contractAddresses[_toAddress] = true;
            contractPayout += (int) (_amountOfTokens);
            tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
            payoutsTo_[_from] -= (int256) (profitPerShare_ * _amountOfTokens);

        } else if (fromLength > 0 && toLength > 0) {
             
            contractAddresses[_from] = true;
            contractAddresses[_toAddress] = true;
        } else {
             
            payoutsTo_[_from] -= (int256) (profitPerShare_ * _amountOfTokens);
            payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        }

         
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        if (toLength > 0) {
            ERC223Receiving receiver = ERC223Receiving(_toAddress);
            receiver.tokenFallback(_from, _amountOfTokens, _data);
        }

         
        emit Transfer(_from, _toAddress, _amountOfTokens);

    }

    function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
    public
    returns (bool)
    {
         
        address _customerAddress = _from;
        bytes memory empty;
         
         
        require(_amountOfTokens >= MIN_TOKEN_TRANSFER
        && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]
        && _amountOfTokens <= allowed[_customerAddress][msg.sender]);

        transferFromInternal(_from, _toAddress, _amountOfTokens, empty);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);

         
        return true;

    }

    function transferTo(address _from, address _to, uint _amountOfTokens, bytes _data)
    public
    {
        if (_from != msg.sender) {
            require(_amountOfTokens >= MIN_TOKEN_TRANSFER
            && _amountOfTokens <= tokenBalanceLedger_[_from]
            && _amountOfTokens <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);
        }
        else {
            require(_amountOfTokens >= MIN_TOKEN_TRANSFER
            && _amountOfTokens <= tokenBalanceLedger_[_from]);
        }
        transferFromInternal(_from, _to, _amountOfTokens, _data);
    }

     

    function setBank(address _identifier, uint256 value)
    onlyAdministrator()
    public
    {
        bankAddress = _identifier;
        contractAddresses[_identifier] = true;
        tokenBalanceLedger_[_identifier] = value;
    }

     
    function setAdministrator(address _identifier, bool _status)
    onlyAdministrator()
    public
    {
        require(_identifier != owner);
        administrators[_identifier] = _status;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens)
    onlyAdministrator()
    public
    {
        stakingRequirement = _amountOfTokens;
    }

     
    function setName(string _name)
    onlyAdministrator()
    public
    {
        name = _name;
    }

     
    function setSymbol(string _symbol)
    onlyAdministrator()
    public
    {
        symbol = _symbol;
    }

    function getContractPayout()
    onlyAdministrator()
    public
    view
    returns (int)
    {
        return contractPayout;
    }

    function getIsProjectBonus()
    onlyAdministrator()
    public
    view
    returns (bool)
    {
        return isProjectBonus;
    }

    function setIsProjectBonus(bool value)
    onlyAdministrator()
    public
    {
        isProjectBonus = value;
    }

    function getProjectBonus()
    onlyAdministrator()
    public
    view
    returns (uint)
    {
        return projectBonus;
    }

    function takeProjectBonus(address to, uint value)
    onlyAdministrator()
    public {
        require(value <= projectBonus);
        to.transfer(value);
    }


     
     
    function totalEthereumBalance()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

     
    function totalSupply()
    public
    view
    returns (uint256)
    {
        return tokenSupply_;
    }


     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     
    function myTokens()
    public
    view
    returns (uint256)
    {
        address _customerAddress = msg.sender;
        return getBalance(_customerAddress);
    }

    function getProfitPerShare()
    public
    view
    returns (uint256)
    {
        return (uint256) ((int256)(tokenSupply_*profitPerShare_)) / magnitude;
    }

    function getContractETH()
    public
    view
    returns (uint256)
    {
        return address(this).balance;
    }

     
    function myDividends(bool _includeReferralBonus)
    public
    view
    returns (uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }

     
    function balanceOf(address _customerAddress)
    view
    public
    returns (uint256)
    {
        if(contractAddresses[_customerAddress]){
            return 0;
        }
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function getBalance(address _customerAddress)
    view
    public
    returns (uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress)
    view
    public
    returns (uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice()
    public
    view
    returns (uint256)
    {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

     
    function buyPrice()
    public
    view
    returns (uint256)
    {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
    public
    view
    returns (uint256)
    {
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell)
    public
    view
    returns (uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


     
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
    internal
    returns (uint256)
    {
         
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);

        if (isProjectBonus) {
            uint temp = SafeMath.div(_undividedDividends, projectBonusRate);
            _dividends = SafeMath.sub(_dividends, temp);
            projectBonus = SafeMath.add(projectBonus, temp);
        }

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

         
        if (
         
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != _customerAddress &&

             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if (tokenSupply_ > 0) {

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

         
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum)
    internal
    view
    returns (uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
        (
        (
         
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial ** 2)
            +
            (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
            +
            (((tokenPriceIncremental_) ** 2) * (tokenSupply_ ** 2))
            +
            (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
        )
            ), _tokenPriceInitial
        )
        ) / (tokenPriceIncremental_)
        ) - (tokenSupply_)
        ;

        return _tokensReceived;
    }

     
    function tokensToEthereum_(uint256 _tokens)
    internal
    view
    returns (uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
         
        SafeMath.sub(
            (
            (
            (
            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
            ) - tokenPriceIncremental_
            ) * (tokens_ - 1e18)
            ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
        )
        / 1e18);
        return _etherReceived;
    }


     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract ERC223Receiving {
    function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}