 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    bool private initialised;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised);
        owner = _owner;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function max(uint a, uint b) internal pure returns (uint c) {
        c = a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint c) {
        c = a <= b ? a : b;
    }
}

 
 
 
 
 
 
 


 
 
 
 
contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
 
 
contract BTTSTokenInterface is ERC20Interface {
    uint public constant bttsVersion = 110;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function symbol() public view returns (string);
    function name() public view returns (string);
    function decimals() public view returns (uint8);

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

     
     
     
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;

     
     
     
    enum CheckResult {
        Success,                            
        NotTransferable,                    
        AccountLocked,                      
        SignerMismatch,                     
        InvalidNonce,                       
        InsufficientApprovedTokens,         
        InsufficientApprovedTokensForFees,  
        InsufficientTokens,                 
        InsufficientTokensForFees,          
        OverflowError                       
    }
}

 
 
 
contract PriceFeedInterface {
    function name() public view returns (string);
    function getRate() public view returns (uint _rate, bool _live);
}

 
 
 
contract BonusListInterface {
    function isInBonusList(address account) public view returns (bool);
}


 
 
 
contract FxxxLandRush is Owned, ApproveAndCallFallBack {
    using SafeMath for uint;

    uint private constant TENPOW18 = 10 ** 18;

    BTTSTokenInterface public parcelToken;
    BTTSTokenInterface public gzeToken;
    PriceFeedInterface public ethUsdPriceFeed;
    PriceFeedInterface public gzeEthPriceFeed;
    BonusListInterface public bonusList;

    address public wallet;
    uint public startDate;
    uint public endDate;
    uint public maxParcels;
    uint public parcelUsd;                   
    uint public usdLockAccountThreshold;     
    uint public gzeBonusOffList;             
    uint public gzeBonusOnList;              

    uint public parcelsSold;
    uint public contributedGze;
    uint public contributedEth;
    bool public finalised;

    event WalletUpdated(address indexed oldWallet, address indexed newWallet);
    event StartDateUpdated(uint oldStartDate, uint newStartDate);
    event EndDateUpdated(uint oldEndDate, uint newEndDate);
    event MaxParcelsUpdated(uint oldMaxParcels, uint newMaxParcels);
    event ParcelUsdUpdated(uint oldParcelUsd, uint newParcelUsd);
    event UsdLockAccountThresholdUpdated(uint oldUsdLockAccountThreshold, uint newUsdLockAccountThreshold);
    event GzeBonusOffListUpdated(uint oldGzeBonusOffList, uint newGzeBonusOffList);
    event GzeBonusOnListUpdated(uint oldGzeBonusOnList, uint newGzeBonusOnList);
    event Purchased(address indexed addr, uint parcels, uint gzeToTransfer, uint ethToTransfer, uint parcelsSold, uint contributedGze, uint contributedEth, bool lockAccount);

    constructor(address _parcelToken, address _gzeToken, address _ethUsdPriceFeed, address _gzeEthPriceFeed, address _bonusList, address _wallet, uint _startDate, uint _endDate, uint _maxParcels, uint _parcelUsd, uint _usdLockAccountThreshold, uint _gzeBonusOffList, uint _gzeBonusOnList) public {
        require(_parcelToken != address(0) && _gzeToken != address(0));
        require(_ethUsdPriceFeed != address(0) && _gzeEthPriceFeed != address(0) && _bonusList != address(0));
        require(_wallet != address(0));
        require(_startDate >= now && _endDate > _startDate);
        require(_maxParcels > 0 && _parcelUsd > 0);
        initOwned(msg.sender);
        parcelToken = BTTSTokenInterface(_parcelToken);
        gzeToken = BTTSTokenInterface(_gzeToken);
        ethUsdPriceFeed = PriceFeedInterface(_ethUsdPriceFeed);
        gzeEthPriceFeed = PriceFeedInterface(_gzeEthPriceFeed);
        bonusList = BonusListInterface(_bonusList);
        wallet = _wallet;
        startDate = _startDate;
        endDate = _endDate;
        maxParcels = _maxParcels;
        parcelUsd = _parcelUsd;
        usdLockAccountThreshold = _usdLockAccountThreshold;
        gzeBonusOffList = _gzeBonusOffList;
        gzeBonusOnList = _gzeBonusOnList;
    }
    function setWallet(address _wallet) public onlyOwner {
        require(!finalised);
        require(_wallet != address(0));
        emit WalletUpdated(wallet, _wallet);
        wallet = _wallet;
    }
    function setStartDate(uint _startDate) public onlyOwner {
        require(!finalised);
        require(_startDate >= now);
        emit StartDateUpdated(startDate, _startDate);
        startDate = _startDate;
    }
    function setEndDate(uint _endDate) public onlyOwner {
        require(!finalised);
        require(_endDate > startDate);
        emit EndDateUpdated(endDate, _endDate);
        endDate = _endDate;
    }
    function setMaxParcels(uint _maxParcels) public onlyOwner {
        require(!finalised);
        require(_maxParcels >= parcelsSold);
        emit MaxParcelsUpdated(maxParcels, _maxParcels);
        maxParcels = _maxParcels;
    }
    function setParcelUsd(uint _parcelUsd) public onlyOwner {
        require(!finalised);
        require(_parcelUsd > 0);
        emit ParcelUsdUpdated(parcelUsd, _parcelUsd);
        parcelUsd = _parcelUsd;
    }
    function setUsdLockAccountThreshold(uint _usdLockAccountThreshold) public onlyOwner {
        require(!finalised);
        emit UsdLockAccountThresholdUpdated(usdLockAccountThreshold, _usdLockAccountThreshold);
        usdLockAccountThreshold = _usdLockAccountThreshold;
    }
    function setGzeBonusOffList(uint _gzeBonusOffList) public onlyOwner {
        require(!finalised);
        emit GzeBonusOffListUpdated(gzeBonusOffList, _gzeBonusOffList);
        gzeBonusOffList = _gzeBonusOffList;
    }
    function setGzeBonusOnList(uint _gzeBonusOnList) public onlyOwner {
        require(!finalised);
        emit GzeBonusOnListUpdated(gzeBonusOnList, _gzeBonusOnList);
        gzeBonusOnList = _gzeBonusOnList;
    }

    function symbol() public view returns (string _symbol) {
        _symbol = parcelToken.symbol();
    }
    function name() public view returns (string _name) {
        _name = parcelToken.name();
    }

     
    function ethUsd() public view returns (uint _rate, bool _live) {
        return ethUsdPriceFeed.getRate();
    }
     
    function gzeEth() public view returns (uint _rate, bool _live) {
        return gzeEthPriceFeed.getRate();
    }
     
    function gzeUsd() public view returns (uint _rate, bool _live) {
        uint _ethUsd;
        bool _ethUsdLive;
        (_ethUsd, _ethUsdLive) = ethUsdPriceFeed.getRate();
        uint _gzeEth;
        bool _gzeEthLive;
        (_gzeEth, _gzeEthLive) = gzeEthPriceFeed.getRate();
        if (_ethUsdLive && _gzeEthLive) {
            _live = true;
            _rate = _ethUsd.mul(_gzeEth).div(TENPOW18);
        }
    }
     
    function parcelEth() public view returns (uint _rate, bool _live) {
        uint _ethUsd;
        (_ethUsd, _live) = ethUsd();
        if (_live) {
            _rate = parcelUsd.mul(TENPOW18).div(_ethUsd);
        }
    }
     
    function parcelGzeWithoutBonus() public view returns (uint _rate, bool _live) {
        uint _gzeUsd;
        (_gzeUsd, _live) = gzeUsd();
        if (_live) {
            _rate = parcelUsd.mul(TENPOW18).div(_gzeUsd);
        }
    }
     
    function parcelGzeWithBonusOffList() public view returns (uint _rate, bool _live) {
        uint _parcelGzeWithoutBonus;
        (_parcelGzeWithoutBonus, _live) = parcelGzeWithoutBonus();
        if (_live) {
            _rate = _parcelGzeWithoutBonus.mul(100).div(gzeBonusOffList.add(100));
        }
    }
     
    function parcelGzeWithBonusOnList() public view returns (uint _rate, bool _live) {
        uint _parcelGzeWithoutBonus;
        (_parcelGzeWithoutBonus, _live) = parcelGzeWithoutBonus();
        if (_live) {
            _rate = _parcelGzeWithoutBonus.mul(100).div(gzeBonusOnList.add(100));
        }
    }

     
     
     
    function purchaseWithGze(uint256 tokens) public {
        require(gzeToken.allowance(msg.sender, this) >= tokens);
        receiveApproval(msg.sender, tokens, gzeToken, "");
    }
     
    function receiveApproval(address from, uint256 tokens, address token, bytes  ) public {
        require(now >= startDate && now <= endDate);
        require(token == address(gzeToken));
        uint _parcelGze;
        bool _live;
        if (bonusList.isInBonusList(from)) {
            (_parcelGze, _live) = parcelGzeWithBonusOnList();
        } else {
            (_parcelGze, _live) = parcelGzeWithBonusOffList();
        }
        require(_live);
        uint parcels = tokens.div(_parcelGze);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        uint gzeToTransfer = parcels.mul(_parcelGze);
        contributedGze = contributedGze.add(gzeToTransfer);
        require(ERC20Interface(token).transferFrom(from, wallet, gzeToTransfer));
        bool lock = mintParcelTokens(from, parcels);
        emit Purchased(from, parcels, gzeToTransfer, 0, parcelsSold, contributedGze, contributedEth, lock);
    }
     
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint _parcelEth;
        bool _live;
        (_parcelEth, _live) = parcelEth();
        require(_live);
        uint parcels = msg.value.div(_parcelEth);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        uint ethToTransfer = parcels.mul(_parcelEth);
        contributedEth = contributedEth.add(ethToTransfer);
        uint ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToRefund > 0) {
            msg.sender.transfer(ethToRefund);
        }
        bool lock = mintParcelTokens(msg.sender, parcels);
        emit Purchased(msg.sender, parcels, 0, ethToTransfer, parcelsSold, contributedGze, contributedEth, lock);
    }
     
    function offlinePurchase(address tokenOwner, uint parcels) public onlyOwner {
        require(!finalised);
        if (parcelsSold.add(parcels) >= maxParcels) {
            parcels = maxParcels.sub(parcelsSold);
        }
        bool lock = mintParcelTokens(tokenOwner, parcels);
        emit Purchased(tokenOwner, parcels, 0, 0, parcelsSold, contributedGze, contributedEth, lock);
    }
     
    function mintParcelTokens(address account, uint parcels) internal returns (bool _lock) {
        require(parcels > 0);
        parcelsSold = parcelsSold.add(parcels);
        _lock = parcelToken.balanceOf(account).add(parcelUsd.mul(parcels)) >= usdLockAccountThreshold;
        require(parcelToken.mint(account, parcelUsd.mul(parcels), _lock));
        if (parcelsSold >= maxParcels) {
            parcelToken.disableMinting();
            finalised = true;
        }
    }
     
    function finalise() public onlyOwner {
        require(!finalised);
        require(now > endDate || parcelsSold >= maxParcels);
        parcelToken.disableMinting();
        finalised = true;
    }
}