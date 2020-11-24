 

pragma solidity ^0.4.25;

 


contract ETHedgeToken {

    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }
    
     
     
    modifier onlyOwner{
        require(msg.sender == owner_, "Only owner can do this!");
        _;
    }
    
    event onPayDividends(
        uint256 incomingDividends,
        string sourceDescription,
        address indexed customerAddress,
        uint timestamp
);

    event onBurn(
        uint256 DividentsFromNulled,
        address indexed customerAddress,
        address indexed senderAddress,
        uint timestamp
);

    event onNewRefferal(
        address indexed userAddress,
        address indexed refferedByAddress,
        uint timestamp
);

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
);

 
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
);

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
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

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
);

    string public name = "ETH hedge token";
    string public symbol = "EHT";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 22;
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal exitFee_ = 3;
    uint8 constant internal refferalFee_ = 15;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 50e18;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => address) internal refferals_;
     
    mapping(address => mapping (address => uint256)) allowed_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
     
    address private owner_=msg.sender;
    mapping(address => uint256) internal lastupdate_;
     
    uint private constant timePassive_ = 365 days;
     
     
    uint8 constant internal entryFeeCapital_ = 15;
     
    uint8 constant internal entryFeeReward_ = 2;
    address public capital_=msg.sender;
    address private adminReward_=msg.sender;
    uint256 public capitalAmount_;
    uint256 public AdminRewardAmount_;
    
    
     
    function transferOwnership(address _newOwner) public onlyOwner{
        require(_newOwner != address(0));
        owner_ = _newOwner;
    }
    
     
    function changeOuts(address _newCapital, address _newReward) public onlyOwner{
         
        require(_newCapital != address(0) && _newReward != 0x0);
        capital_ = _newCapital;
        adminReward_ = _newReward;
    }

     
    function payDividends(string _sourceDesc) public payable {
        payDivsValue(msg.value,_sourceDesc);
    }

     
    function payDivsValue(uint256 _amountOfDivs,string _sourceDesc) internal {
        address _customerAddress = msg.sender;
        uint256 _dividends = _amountOfDivs;
        if (tokenSupply_ > 0) {
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
        }
        emit onPayDividends(_dividends,_sourceDesc,_customerAddress,now);
    }

     
    function burn(address _checkForInactive) public {
        address _customerAddress = _checkForInactive;
        require(lastupdate_[_customerAddress]!=0 && now >= SafeMath.add(lastupdate_[_customerAddress],timePassive_), "This account cant be nulled!");
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        
        uint256 _dividends = dividendsOf(_customerAddress);
        _dividends += referralBalance_[_customerAddress];
        payDivsValue(_dividends,'Burn coins');

        delete tokenBalanceLedger_[_customerAddress];
        delete referralBalance_[_customerAddress];
        delete payoutsTo_[_customerAddress];
        delete lastupdate_[_customerAddress];
        emit onBurn(_dividends,_customerAddress,msg.sender,now);
    }
  
     
    function takeCapital() public{
        require(capitalAmount_>0 && AdminRewardAmount_>0, "No fundz, sorry!");
        capital_.transfer(capitalAmount_);  
        adminReward_.transfer(AdminRewardAmount_);  
        capitalAmount_=0;
        AdminRewardAmount_=0;
    }
    
      
     
     
     
     
     
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed_[_from][msg.sender];
        require(tokenBalanceLedger_[_from] >= _value && allowance >= _value);
        tokenBalanceLedger_[_to] =SafeMath.add(tokenBalanceLedger_[_to],_value);
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from],_value);
        allowed_[_from][msg.sender] = SafeMath.sub(allowed_[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed_[_owner][_spender];
    }
     
    
    function buy(address _referredBy) public payable returns (uint256) {
        purchaseTokens(msg.value, _referredBy);
    }

    function() payable public {
        if (msg.value == 1e10) {
            reinvest();
        }
        else if (msg.value == 2e10) {
            withdraw();
        }
        else if (msg.value == 3e10) {
            exit();
        }
        else {
            purchaseTokens(msg.value, 0x0);
        }
    }

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        lastupdate_[_customerAddress] = now;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address _customerAddress = msg.sender;
        lastupdate_[_customerAddress] = now;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        lastupdate_[_customerAddress] = now;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        address _customerAddress = msg.sender;
        lastupdate_[_customerAddress] = now;
        if (_amountOfTokens>stakingRequirement) {
            lastupdate_[_toAddress] = now;
        }
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }


    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function refferedBy(address _customerAddress) public view returns (address) {
        return refferals_[_customerAddress];
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        lastupdate_[_customerAddress] = now;

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_-entryFeeCapital_-entryFeeReward_), 100);
        uint256 _capitalTrade = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFeeCapital_), 100);
        uint256 _adminReward = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFeeReward_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends),_capitalTrade),_adminReward);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

 
        if (
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement &&
            refferals_[_customerAddress] == 0x0
        ) {
            refferals_[_customerAddress] = _referredBy;
            emit onNewRefferal(_customerAddress,_referredBy, now);
        }

 
        if (
            refferals_[_customerAddress] != 0x0 &&
            tokenBalanceLedger_[refferals_[_customerAddress]] >= stakingRequirement
        ) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        capitalAmount_=SafeMath.add(capitalAmount_,_capitalTrade);
        AdminRewardAmount_=SafeMath.add(AdminRewardAmount_,_adminReward);
        if (capitalAmount_>1e17){  
            takeCapital();
        }

        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
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
                                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (tokenSupply_);

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
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

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


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