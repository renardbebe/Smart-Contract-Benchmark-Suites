 

 
 

pragma solidity 0.4.19;


 
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}


 
contract CryptoTorchToken is ERC20, Ownable {
    using SafeMath for uint256;

     
     
     
     
    event onWithdraw(
        address indexed to,
        uint256 amount
    );
    event onMint(
        address indexed to,
        uint256 pricePaid,
        uint256 tokensMinted,
        address indexed referredBy
    );
    event onBurn(
        address indexed from,
        uint256 tokensBurned,
        uint256 amountEarned
    );

     
     
     
     
    string internal name_ = "Cryptolympic Torch-Run Kilometers";
    string internal symbol_ = "KMS";
    uint256 constant internal dividendFee_ = 5;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 50e18;

     
     
     
     
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    address internal tokenController_;
    address internal donationsReceiver_;
    mapping (address => uint256) internal tokenBalanceLedger_;  
    mapping (address => uint256) internal referralBalance_;
    mapping (address => uint256) internal profitsReceived_;
    mapping (address => int256) internal payoutsTo_;

     
     
     
     
     
     
     
    modifier onlyTokenController() {
        require(tokenController_ != address(0) && msg.sender == tokenController_);
        _;
    }

     
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyProfitHolders() {
        require(myDividends(true) > 0);
        _;
    }

     
     
     
     
     
    function CryptoTorchToken() public {}

     
    function setTokenController(address _controller) public onlyOwner {
        tokenController_ = _controller;
    }

     
    function setDonationsReceiver(address _receiver) public onlyOwner {
        donationsReceiver_ = _receiver;
    }

     
    function() payable public {
        if (msg.value > 0 && donationsReceiver_ != 0x0) {
            donationsReceiver_.transfer(msg.value);  
        }
    }

     
    function sell(uint256 _amountOfTokens) public onlyTokenHolders {
        sell_(msg.sender, _amountOfTokens);
    }

     
    function sellFor(address _for, uint256 _amountOfTokens) public onlyTokenController {
        sell_(_for, _amountOfTokens);
    }

     
    function withdraw() public onlyProfitHolders {
        withdraw_(msg.sender);
    }

     
    function withdrawFor(address _for) public onlyTokenController {
        withdraw_(_for);
    }

     
    function mint(address _to, uint256 _amountPaid, address _referredBy) public onlyTokenController payable returns(uint256) {
        require(_amountPaid == msg.value);
        return mintTokens_(_to, _amountPaid, _referredBy);
    }

     
    function transfer(address _to, uint256 _value) public onlyTokenHolders returns(bool) {
        return transferFor_(msg.sender, _to, _value);
    }

     
     
     
     
     
    function setName(string _name) public onlyOwner {
        name_ = _name;
    }

     
    function setSymbol(string _symbol) public onlyOwner {
        symbol_ = _symbol;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens) public onlyOwner {
        stakingRequirement = _amountOfTokens;
    }

     
     
     
     
     
    function contractBalance() public view returns (uint256) {
        return this.balance;
    }

     
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function decimals() public pure returns (uint256) {
        return 18;
    }

     
    function myTokens() public view returns(uint256) {
        address _playerAddress = msg.sender;
        return balanceOf(_playerAddress);
    }

     
    function myDividends(bool _includeBonus) public view returns(uint256) {
        address _playerAddress = msg.sender;
        return _includeBonus ? dividendsOf(_playerAddress) + referralBalance_[_playerAddress] : dividendsOf(_playerAddress);
    }

     
    function myProfitsReceived() public view returns (uint256) {
        address _playerAddress = msg.sender;
        return profitsOf(_playerAddress);
    }

     
    function balanceOf(address _playerAddress) public view returns(uint256) {
        return tokenBalanceLedger_[_playerAddress];
    }

     
    function dividendsOf(address _playerAddress) public view returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_playerAddress]) - payoutsTo_[_playerAddress]) / magnitude;
    }

     
    function profitsOf(address _playerAddress) public view returns(uint256) {
        return profitsReceived_[_playerAddress];
    }

     
    function referralBalanceOf(address _playerAddress) public view returns(uint256) {
        return referralBalance_[_playerAddress];
    }

     
    function sellPrice() public view returns(uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ether = tokensToEther_(1e18);
            uint256 _dividends = SafeMath.div(_ether, dividendFee_);
            uint256 _taxedEther = SafeMath.sub(_ether, _dividends);
            return _taxedEther;
        }
    }

     
    function buyPrice() public view returns(uint256) {
         
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ether = tokensToEther_(1e18);
            uint256 _dividends = SafeMath.div(_ether, dividendFee_);
            uint256 _taxedEther = SafeMath.add(_ether, _dividends);
            return _taxedEther;
        }
    }

     
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256) {
        uint256 _dividends = _etherToSpend.div(dividendFee_);
        uint256 _taxedEther = _etherToSpend.sub(_dividends);
        uint256 _amountOfTokens = etherToTokens_(_taxedEther);
        return _amountOfTokens;
    }

     
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ether = tokensToEther_(_tokensToSell);
        uint256 _dividends = _ether.div(dividendFee_);
        uint256 _taxedEther = _ether.sub(_dividends);
        return _taxedEther;
    }

     
     
     
     

     
    function sell_(address _recipient, uint256 _amountOfTokens) internal {
        require(_amountOfTokens <= tokenBalanceLedger_[_recipient]);

        uint256 _tokens = _amountOfTokens;
        uint256 _ether = tokensToEther_(_tokens);
        uint256 _dividends = SafeMath.div(_ether, dividendFee_);
        uint256 _taxedEther = SafeMath.sub(_ether, _dividends);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_recipient] = SafeMath.sub(tokenBalanceLedger_[_recipient], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEther * magnitude));
        payoutsTo_[_recipient] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        onBurn(_recipient, _tokens, _taxedEther);
    }

     
    function withdraw_(address _recipient) internal {
        require(_recipient != address(0));

         
        uint256 _dividends = getDividendsOf_(_recipient, false);

         
        payoutsTo_[_recipient] += (int256)(_dividends * magnitude);

         
        _dividends += referralBalance_[_recipient];
        referralBalance_[_recipient] = 0;

         
        onWithdraw(_recipient, _dividends);

         
        profitsReceived_[_recipient] = profitsReceived_[_recipient].add(_dividends);
        _recipient.transfer(_dividends);

         
        if (tokenSupply_ == 0 && this.balance > 0) {
            owner.transfer(this.balance);
        }
    }

     
    function mintTokens_(address _to, uint256 _amountPaid, address _referredBy) internal returns(uint256) {
        require(_to != address(this) && _to != tokenController_);

        uint256 _undividedDividends = SafeMath.div(_amountPaid, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 10);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEther = SafeMath.sub(_amountPaid, _undividedDividends);
        uint256 _amountOfTokens = etherToTokens_(_taxedEther);
        uint256 _fee = _dividends * magnitude;

         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

         
        if (_referredBy != address(0) && _referredBy != _to && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_to] = SafeMath.add(tokenBalanceLedger_[_to], _amountOfTokens);

         
        int256 _updatedPayouts = (int256)((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_to] += _updatedPayouts;

         
        onMint(_to, _amountPaid, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

     
    function transferFor_(address _from, address _to, uint256 _amountOfTokens) internal returns(bool) {
        require(_to != address(0));
        require(tokenBalanceLedger_[_from] >= _amountOfTokens && tokenBalanceLedger_[_to] + _amountOfTokens >= tokenBalanceLedger_[_to]);

         
        require(_amountOfTokens <= tokenBalanceLedger_[_from]);

         
        if (getDividendsOf_(_from, true) > 0) {
            withdraw_(_from);
        }

         
         
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEther_(_tokenFee);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from], _amountOfTokens);
        tokenBalanceLedger_[_to] = SafeMath.add(tokenBalanceLedger_[_to], _taxedTokens);

         
        payoutsTo_[_from] -= (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_to] += (int256)(profitPerShare_ * _taxedTokens);

         
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

         
        Transfer(_from, _to, _taxedTokens);

         
        return true;
    }

     
    function getDividendsOf_(address _recipient, bool _includeBonus) internal view returns(uint256) {
        return _includeBonus ? dividendsOf(_recipient) + referralBalance_[_recipient] : dividendsOf(_recipient);
    }

     
    function etherToTokens_(uint256 _ether) internal view returns(uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
        (
        (
         
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial**2)
            +
            (2*(tokenPriceIncremental_ * 1e18)*(_ether * 1e18))
            +
            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
            +
            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
        )
            ), _tokenPriceInitial
        )
        )/(tokenPriceIncremental_)
        )-(tokenSupply_);

        return _tokensReceived;
    }

     
    function tokensToEther_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
         
        SafeMath.sub(
            (
            (
            (
            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
            )-tokenPriceIncremental_
            )*(tokens_ - 1e18)
            ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
        )
        /1e18);
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