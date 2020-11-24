 

pragma solidity 0.4.19;


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract ElyERC20 is StandardToken, Ownable {
     
    uint256 public creationBlock;

    uint8 public decimals;

    string public name;

    string public symbol;

    string public standard;

    bool public locked;

     
    function ElyERC20(
        uint256 _totalSupply,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    ) public {
        standard = 'ERC20 0.1';
        locked = _locked;
        totalSupply_ = _totalSupply;

        if (_transferAllSupplyToOwner) {
            balances[msg.sender] = totalSupply_;
        } else {
            balances[this] = totalSupply_;
        }
        name = _tokenName;
         
        symbol = _tokenSymbol;
         
        decimals = _decimalUnits;
         
        creationBlock = block.number;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(locked == false);
        return super.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        if (locked) {
            return false;
        }
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (locked) {
            return false;
        }

        return super.transferFrom(_from, _to, _value);
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

 
contract MintingERC20 is ElyERC20 {

    using SafeMath for uint256;

     
    mapping (address => bool) public minters;

    uint256 public maxSupply;

     
    modifier onlyMinters () {
        require(true == minters[msg.sender]);
        _;
    }

    function MintingERC20(
        uint256 _initialSupply,
        uint256 _maxSupply,
        string _tokenName,
        uint8 _decimals,
        string _symbol,
        bool _transferAllSupplyToOwner,
        bool _locked
    )
        public ElyERC20(_initialSupply, _tokenName, _decimals, _symbol, _transferAllSupplyToOwner, _locked)
    {
        standard = 'MintingERC20 0.1';
        minters[msg.sender] = true;
        maxSupply = _maxSupply;
    }

    function addMinter(address _newMinter) public onlyOwner {
        minters[_newMinter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        minters[_minter] = false;
    }

    function mint(address _addr, uint256 _amount) public onlyMinters returns (uint256) {
        if (true == locked) {
            return uint256(0);
        }

        if (_amount == uint256(0)) {
            return uint256(0);
        }

        if (totalSupply_.add(_amount) > maxSupply) {
            return uint256(0);
        }

        totalSupply_ = totalSupply_.add(_amount);
        balances[_addr] = balances[_addr].add(_amount);
        Transfer(address(0), _addr, _amount);

        return _amount;
    }

}

contract ElyToken is MintingERC20 {

    SellableToken public ico;
    SellableToken public privateSale;
    LockupContract public lockupContract;

    address public bountyAddress;

    bool public transferFrozen = true;

    modifier onlySellable() {
        require(msg.sender == address(ico) || msg.sender == address(privateSale));
        _;
    }

    event Burn(address indexed burner, uint256 value);

    function ElyToken(
        address _bountyAddress,
        bool _locked
    )
        public MintingERC20(0, maxSupply, 'Elycoin', 18, 'ELY', false, _locked)
    {
        require(_bountyAddress != address(0));
        bountyAddress = _bountyAddress;
        standard = 'ELY 0.1';
        maxSupply = uint(1000000000).mul(uint(10) ** decimals);
        uint256 bountyAmount = uint(10000000).mul(uint(10) ** decimals);
        require(bountyAmount == super.mint(bountyAddress, bountyAmount));
    }

    function setICO(address _ico) public onlyOwner {
        require(_ico != address(0));
        ico = SellableToken(_ico);
    }

    function setPrivateSale(address _privateSale) public onlyOwner {
        require(_privateSale != address(0));
        privateSale = SellableToken(_privateSale);
    }

    function setLockupContract(address _lockupContract) public onlyOwner {
        require(_lockupContract != address(0));
        lockupContract = LockupContract(_lockupContract);
    }

    function setLocked(bool _locked) public onlyOwner {
        locked = _locked;
    }

    function freezing(bool _transferFrozen) public onlyOwner {
        if (address(ico) != address(0) && !ico.isActive() && block.timestamp >= ico.startTime()) {
            transferFrozen = _transferFrozen;
        }
    }

    function mint(address _addr, uint256 _amount) public onlyMinters returns (uint256) {
        if (msg.sender == owner) {
            require(address(ico) != address(0));
            if (!ico.isActive()) {
                return super.mint(_addr, _amount);
            }
            return uint256(0);
        }
        return super.mint(_addr, _amount);
    }

    function transferAllowed(address _address, uint256 _amount) public view returns (bool) {
        return !transferFrozen && lockupContract.isTransferAllowed(_address, _amount);
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(msg.sender == bountyAddress || transferAllowed(msg.sender, _value));
        if (msg.sender == bountyAddress) {
            lockupContract.log(_to, _value);
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_from == bountyAddress || transferAllowed(_from, _value));
        if (_from == bountyAddress) {
            lockupContract.log(_to, _value);
        }
        return super.transferFrom(_from, _to, _value);
    }

    function burnTokens(uint256 _amount) public onlySellable {
        if (totalSupply_.add(_amount) > maxSupply) {
            Burn(address(this), maxSupply.sub(totalSupply_));
            totalSupply_ = maxSupply;
        } else {
            totalSupply_ = totalSupply_.add(_amount);
            Burn(address(this), _amount);
        }
    }

    function burnInvestorTokens(address _address, uint256 _amount) public constant onlySellable returns (uint256) {
        require(balances[_address] >= _amount);
        balances[_address] = balances[_address].sub(_amount);
        Burn(_address, _amount);
        Transfer(_address, address(0), _amount);

        return _amount;
    }

}

contract Multivest is Ownable {

    using SafeMath for uint256;

     
    mapping (address => bool) public allowedMultivests;

     
    event MultivestSet(address multivest);

    event MultivestUnset(address multivest);

    event Contribution(address holder, uint256 value, uint256 tokens);

    modifier onlyAllowedMultivests(address _addresss) {
        require(allowedMultivests[_addresss] == true);
        _;
    }

     
    function Multivest() public {}

    function setAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = true;
        MultivestSet(_address);
    }

    function unsetAllowedMultivest(address _address) public onlyOwner {
        allowedMultivests[_address] = false;
        MultivestUnset(_address);
    }

    function multivestBuy(address _address, uint256 _value) public onlyAllowedMultivests(msg.sender) {
        require(buy(_address, _value) == true);
    }

    function multivestBuy(
        address _address,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable onlyAllowedMultivests(verify(keccak256(msg.sender), _v, _r, _s)) {
        require(_address == msg.sender && buy(msg.sender, msg.value) == true);
    }

    function verify(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = '\x19Ethereum Signed Message:\n32';

        return ecrecover(keccak256(prefix, _hash), _v, _r, _s);
    }

    function buy(address _address, uint256 _value) internal returns (bool);

}

contract SellableToken is Multivest {

    ElyToken public token;

    uint256 public constant DECIMALS = 18;

    uint256 public minPurchase = 1000000; 

    uint256 public softCap = 300000000000; 
    uint256 public hardCap = 1500000000000; 

    uint256 public compensationAmount = 5100000000; 
    uint256 public compensatedAmount;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public maxTokenSupply;

    uint256 public soldTokens;

    uint256 public collectedEthers;

    uint256 public priceUpdateAt;

    address public etherHolder;

    address public compensationAddress;

    uint256 public collectedUSD;

    uint256 public etherPriceInUSD;  

    mapping (address => uint256) public etherBalances;

    mapping (address => bool) public whitelist;

    Tier[] public tiers;

    struct Tier {
        uint256 maxAmount;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    event WhitelistSet(address indexed contributorAddress, bool isWhitelisted);

    event Refund(address _holder, uint256 _ethers, uint256 _tokens);

    function SellableToken(
        address _token,
        address _etherHolder,
        address _compensationAddress,
        uint256 _etherPriceInUSD,
        uint256 _maxTokenSupply
    )
        public Multivest()
    {
        require(_token != address(0));
        token = ElyToken(_token);

        require(_etherHolder != address(0) && _compensationAddress != address(0));
        etherHolder = _etherHolder;
        compensationAddress = _compensationAddress;
        require((_maxTokenSupply == uint256(0)) || (_maxTokenSupply <= token.maxSupply()));

        etherPriceInUSD = _etherPriceInUSD;
        maxTokenSupply = _maxTokenSupply;

        priceUpdateAt = block.timestamp;
    }

    function() public payable {
        require(true == whitelist[msg.sender] && buy(msg.sender, msg.value) == true);
    }

    function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0));
        token = ElyToken(_token);
    }

    function isActive() public view returns (bool) {
        if (maxTokenSupply > uint256(0) && soldTokens == maxTokenSupply) {
            return false;
        }

        return withinPeriod();
    }

    function withinPeriod() public view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function setEtherHolder(address _etherHolder) public onlyOwner {
        if (_etherHolder != address(0)) {
            etherHolder = _etherHolder;
        }
    }

    function updateWhitelist(address _address, bool isWhitelisted) public onlyOwner {
        whitelist[_address] = isWhitelisted;
        WhitelistSet(_address, isWhitelisted);
    }

    function mint(address _address, uint256 _tokenAmount) public onlyOwner returns (uint256) {
        return mintInternal(_address, _tokenAmount);
    }

    function setEtherPriceInUSD(string _price) public onlyOwner {
        setEtherInUSDInternal(_price);
    }

    function setEtherInUSD(string _price) public onlyAllowedMultivests(msg.sender) {
        setEtherInUSDInternal(_price);
    }

     
     
     
    function setEtherInUSDInternal(string _price) internal {
        bytes memory bytePrice = bytes(_price);
        uint256 dot = bytePrice.length.sub(uint256(6));

         
        require(0x2e == uint(bytePrice[dot]));

        uint256 newPrice = uint256(10 ** 23).div(parseInt(_price, 5));

        require(newPrice > 0);

        etherPriceInUSD = parseInt(_price, 5);

        priceUpdateAt = block.timestamp;
    }

    function mintInternal(address _address, uint256 _tokenAmount) internal returns (uint256) {
        uint256 mintedAmount = token.mint(_address, _tokenAmount);

        require(mintedAmount == _tokenAmount);

        mintedAmount = mintedAmount.add(token.mint(compensationAddress, _tokenAmount.mul(5).div(1000)));

        soldTokens = soldTokens.add(_tokenAmount);
        if (maxTokenSupply > 0) {
            require(maxTokenSupply >= soldTokens);
        }

        return _tokenAmount;
    }

    function transferEthersInternal() internal {
        if (collectedUSD >= softCap) {
            if (compensatedAmount < compensationAmount) {
                uint256 amount = uint256(1 ether).mul(compensationAmount.sub(compensatedAmount)).div(etherPriceInUSD);
                compensatedAmount = compensationAmount;
                compensationAddress.transfer(amount);
            }

            etherHolder.transfer(this.balance);
        }
    }

    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mintt = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mintt *= 10;
                mintt += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mintt *= 10 ** _b;
        return mintt;
    }

}

contract ICO is SellableToken {

    SellableToken public privateSale;
    LockupContract public lockupContract;

    uint8 public constant PRE_ICO_TIER = 0;
    uint8 public constant ICO_TIER_FIRST = 1;
    uint8 public constant ICO_TIER_TWO = 2;
    uint8 public constant ICO_TIER_LAST = 3;

    Stats public preICOStats;

    uint256 public lockupThreshold = 10000000000;

    mapping(address => uint256) public icoBalances;
    mapping(address => uint256) public icoLockedBalance;

    struct Stats {
        uint256 soldTokens;
        uint256 collectedUSD;
        uint256 collectedEthers;
        bool burned;
    }

    function ICO(
        address _token,
        address _etherHolder,
        address _compensationAddress,
        uint256 _etherPriceInUSD,  
        uint256 _maxTokenSupply
    ) public SellableToken(
        _token,
        _etherHolder,
        _compensationAddress,
        _etherPriceInUSD,
        _maxTokenSupply
    ) {
        tiers.push(
            Tier(
                uint256(40000000).mul(uint256(10) ** DECIMALS),
                uint256(6000),
                1526886000,
                1528095599
            )
        ); 
        tiers.push(
            Tier(
                uint256(150000000).mul(uint256(10) ** DECIMALS),
                uint256(8000),
                1528095600,
                1528700399
            )
        ); 
        tiers.push(
            Tier(
                uint256(150000000).mul(uint256(10) ** DECIMALS),
                uint256(10000),
                1528700400,
                1529305199
            )
        ); 
        tiers.push(
            Tier(
                uint256(150000000).mul(uint256(10) ** DECIMALS),
                uint256(12000),
                1529305200,
                1529909999
            )
        ); 

        startTime = 1528095600;
        endTime = 1529909999;
    }

    function setPrivateSale(address _privateSale) public onlyOwner {
        if (_privateSale != address(0)) {
            privateSale = SellableToken(_privateSale);
        }
    }

    function setLockupContract(address _lockupContract) public onlyOwner {
        require(_lockupContract != address(0));
        lockupContract = LockupContract(_lockupContract);
    }

    function changePreICODates(uint256 _start, uint256 _end) public onlyOwner {
        if (_start != 0 && _start < _end) {
            Tier storage preICOTier = tiers[PRE_ICO_TIER];
            preICOTier.startTime = _start;
            preICOTier.endTime = _end;
        }
    }

    function changeICODates(uint8 _tierId, uint256 _start, uint256 _end) public onlyOwner {
        if (_start != 0 && _start < _end && _tierId < tiers.length) {
            Tier storage icoTier = tiers[_tierId];
            icoTier.startTime = _start;
            icoTier.endTime = _end;
            if (_tierId == ICO_TIER_FIRST) {
                startTime = _start;
            } else if (_tierId == ICO_TIER_LAST) {
                endTime = _end;
            }
        }
    }

    function burnUnsoldTokens() public onlyOwner {
        if (block.timestamp >= tiers[PRE_ICO_TIER].endTime && preICOStats.burned == false) {
            token.burnTokens(tiers[PRE_ICO_TIER].maxAmount.sub(preICOStats.soldTokens));
            preICOStats.burned = true;
        }
        if (block.timestamp >= endTime && maxTokenSupply > soldTokens) {
            token.burnTokens(maxTokenSupply.sub(soldTokens));
            maxTokenSupply = soldTokens;
        }
    }

    function transferEthers() public onlyOwner {
        super.transferEthersInternal();
    }

    function transferCompensationEthers() public {
        if (msg.sender == compensationAddress) {
            super.transferEthersInternal();
        }
    }

    function getActiveTier() public view returns (uint8) {
        for (uint8 i = 0; i < tiers.length; i++) {
            if (block.timestamp >= tiers[i].startTime && block.timestamp <= tiers[i].endTime) {
                return i;
            }
        }

        return uint8(tiers.length);
    }

    function calculateTokensAmount(uint256 _value, bool _isEther) public view returns (
        uint256 tokenAmount,
        uint256 currencyAmount
    ) {
        uint8 activeTier = getActiveTier();

        if (activeTier == tiers.length) {
            if (endTime < block.timestamp) {
                return (0, 0);
            }
            if (startTime > block.timestamp) {
                activeTier = PRE_ICO_TIER;
            }
        }

        if (_isEther) {
            currencyAmount = _value.mul(etherPriceInUSD);
            tokenAmount = currencyAmount.div(tiers[activeTier].price);
            if (currencyAmount < minPurchase.mul(1 ether)) {
                return (0, 0);
            }
            currencyAmount = currencyAmount.div(1 ether);
        } else {
            if (_value < minPurchase) {
                return (0, 0);
            }
            currencyAmount = uint256(1 ether).mul(_value).div(etherPriceInUSD);
            tokenAmount = _value.mul(uint256(10) ** DECIMALS).div(tiers[activeTier].price);
        }
    }

    function calculateEthersAmount(uint256 _amount) public view returns (uint256 ethersAmount) {
        uint8 activeTier = getActiveTier();

        if (activeTier == tiers.length) {
            if (endTime < block.timestamp) {
                return 0;
            }
            if (startTime > block.timestamp) {
                activeTier = PRE_ICO_TIER;
            }
        }

        if (_amount == 0 || _amount.mul(tiers[activeTier].price) < minPurchase) {
            return 0;
        }

        ethersAmount = _amount.mul(tiers[activeTier].price).div(etherPriceInUSD);
    }

    function getMinEthersInvestment() public view returns (uint256) {
        return uint256(1 ether).mul(minPurchase).div(etherPriceInUSD);
    }

    function getStats() public view returns (
        uint256 start,
        uint256 end,
        uint256 sold,
        uint256 totalSoldTokens,
        uint256 maxSupply,
        uint256 min,
        uint256 soft,
        uint256 hard,
        uint256 tokensPerEth,
        uint256[16] tiersData
    ) {
        start = startTime;
        end = endTime;
        sold = soldTokens;
        totalSoldTokens = soldTokens.add(preICOStats.soldTokens);
        if (address(privateSale) != address(0)) {
            totalSoldTokens = totalSoldTokens.add(privateSale.soldTokens());
        }
        maxSupply = maxTokenSupply;
        min = minPurchase;
        soft = softCap;
        hard = hardCap;
        uint256 usd;
        (tokensPerEth, usd) = calculateTokensAmount(1 ether, true);
        uint256 j = 0;
        for (uint256 i = 0; i < tiers.length; i++) {
            tiersData[j++] = uint256(tiers[i].maxAmount);
            tiersData[j++] = uint256(tiers[i].price);
            tiersData[j++] = uint256(tiers[i].startTime);
            tiersData[j++] = uint256(tiers[i].endTime);
        }
    }

    function isRefundPossible() public view returns (bool) {
        if (getActiveTier() != tiers.length || block.timestamp < startTime || collectedUSD >= softCap) {
            return false;
        }
        return true;
    }

    function refund() public returns (bool) {
        uint256 balance = etherBalances[msg.sender];
        if (!isRefundPossible() || balance == 0) {
            return false;
        }

        uint256 burnedAmount = token.burnInvestorTokens(msg.sender, icoBalances[msg.sender]);
        if (burnedAmount == 0) {
            return false;
        }
        if (icoLockedBalance[msg.sender] > 0) {
            lockupContract.decreaseAfterBurn(msg.sender, icoLockedBalance[msg.sender]);
        }
        Refund(msg.sender, balance, burnedAmount);
        etherBalances[msg.sender] = 0;
        msg.sender.transfer(balance);

        return true;
    }

    function mintPreICO(
        address _address,
        uint256 _tokenAmount,
        uint256 _ethAmount,
        uint256 _usdAmount
    ) internal returns (uint256) {
        uint256 mintedAmount = token.mint(_address, _tokenAmount);

        require(mintedAmount == _tokenAmount);

        preICOStats.soldTokens = preICOStats.soldTokens.add(_tokenAmount);
        preICOStats.collectedEthers = preICOStats.collectedEthers.add(_ethAmount);
        preICOStats.collectedUSD = preICOStats.collectedUSD.add(_usdAmount);

        require(tiers[PRE_ICO_TIER].maxAmount >= preICOStats.soldTokens);

        if (preICOStats.collectedUSD <= compensationAmount) {
            compensatedAmount = compensatedAmount.add(_usdAmount);
            compensationAddress.transfer(this.balance);
        }

        return _tokenAmount;
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0 || _address == address(0)) {
            return false;
        }
        uint8 activeTier = getActiveTier();
        if (activeTier == tiers.length) {
            return false;
        }

        uint256 tokenAmount;
        uint256 usdAmount;
        uint256 mintedAmount;

        (tokenAmount, usdAmount) = calculateTokensAmount(_value, true);
        require(usdAmount > 0 && tokenAmount > 0);

        if (usdAmount >= lockupThreshold) {
            lockupContract.logLargeContribution(_address, tokenAmount);
            icoLockedBalance[_address] = icoLockedBalance[_address].add(tokenAmount);
        }

        if (activeTier == PRE_ICO_TIER) {
            mintedAmount = mintPreICO(_address, tokenAmount, _value, usdAmount);
        } else {
            mintedAmount = mintInternal(_address, tokenAmount);

            collectedEthers = collectedEthers.add(_value);
            collectedUSD = collectedUSD.add(usdAmount);

            require(hardCap >= collectedUSD);

            etherBalances[_address] = etherBalances[_address].add(_value);
            icoBalances[_address] = icoBalances[_address].add(tokenAmount);
        }

        Contribution(_address, _value, tokenAmount);

        return true;
    }

}

contract PrivateSale is SellableToken {

    uint256 public price = 4000; 

    function PrivateSale(
        address _token,
        address _etherHolder,
        address _compensationAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _etherPriceInUSD,  
        uint256 _maxTokenSupply
    ) public SellableToken(
        _token,
        _etherHolder,
        _compensationAddress,
        _etherPriceInUSD,
        _maxTokenSupply
    ) {
        require(_startTime > 0 && _endTime > _startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

    function changeSalePeriod(uint256 _start, uint256 _end) public onlyOwner {
        if (_start != 0 && _start < _end) {
            startTime = _start;
            endTime = _end;
        }
    }

    function burnUnsoldTokens() public onlyOwner {
        if (block.timestamp >= endTime && maxTokenSupply > soldTokens) {
            token.burnTokens(maxTokenSupply.sub(soldTokens));
            maxTokenSupply = soldTokens;
        }
    }

    function calculateTokensAmount(uint256 _value) public view returns (uint256 tokenAmount, uint256 usdAmount) {
        if (_value == 0) {
            return (0, 0);
        }

        usdAmount = _value.mul(etherPriceInUSD);
        if (usdAmount < minPurchase.mul(1 ether)) {
            return (0, 0);
        }
        tokenAmount = usdAmount.div(price);

        usdAmount = usdAmount.div(1 ether);
    }

    function calculateEthersAmount(uint256 _amount) public view returns (uint256 ethersAmount) {
        if (_amount == 0 || _amount.mul(price) < minPurchase.mul(1 ether)) {
            return 0;
        }

        ethersAmount = _amount.mul(price).div(etherPriceInUSD);
    }

    function getMinEthersInvestment() public view returns (uint256) {
        return uint256(1 ether).mul(minPurchase).div(etherPriceInUSD);
    }

    function getStats() public view returns (
        uint256 start,
        uint256 end,
        uint256 sold,
        uint256 maxSupply,
        uint256 min,
        uint256 soft,
        uint256 hard,
        uint256 priceAmount,
        uint256 tokensPerEth
    ) {
        start = startTime;
        end = endTime;
        sold = soldTokens;
        maxSupply = maxTokenSupply;
        min = minPurchase;
        soft = softCap;
        hard = hardCap;
        priceAmount = price;
        uint256 usd;
        (tokensPerEth, usd) = calculateTokensAmount(1 ether);
    }

    function buy(address _address, uint256 _value) internal returns (bool) {
        if (_value == 0) {
            return false;
        }
        require(_address != address(0) && withinPeriod());

        uint256 tokenAmount;
        uint256 usdAmount;

        (tokenAmount, usdAmount) = calculateTokensAmount(_value);

        uint256 mintedAmount = token.mint(_address, tokenAmount);
        soldTokens = soldTokens.add(tokenAmount);
        require(mintedAmount == tokenAmount && maxTokenSupply >= soldTokens && usdAmount > 0 && mintedAmount > 0);

        collectedEthers = collectedEthers.add(_value);
        collectedUSD = collectedUSD.add(usdAmount);

        Contribution(_address, _value, tokenAmount);

        etherHolder.transfer(this.balance);
        return true;
    }

}

contract Referral is Multivest {

    ElyToken public token;
    LockupContract public lockupContract;

    uint256 public constant DECIMALS = 18;

    uint256 public totalSupply = 10000000 * 10 ** DECIMALS;

    address public tokenHolder;

    mapping (address => bool) public claimed;

     
    function Referral(
        address _token,
        address _tokenHolder
    ) public Multivest() {
        require(_token != address(0) && _tokenHolder != address(0));
        token = ElyToken(_token);
        tokenHolder = _tokenHolder;
    }

    function setTokenContract(address _token) public onlyOwner {
        if (_token != address(0)) {
            token = ElyToken(_token);
        }
    }

    function setLockupContract(address _lockupContract) public onlyOwner {
        require(_lockupContract != address(0));
        lockupContract = LockupContract(_lockupContract);
    }

    function setTokenHolder(address _tokenHolder) public onlyOwner {
        if (_tokenHolder != address(0)) {
            tokenHolder = _tokenHolder;
        }
    }

    function multivestMint(
        address _address,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public onlyAllowedMultivests(verify(keccak256(msg.sender, _amount), _v, _r, _s)) {
        _amount = _amount.mul(10 ** DECIMALS);
        require(
            claimed[_address] == false &&
            _address == msg.sender &&
            _amount > 0 &&
            _amount <= totalSupply &&
            _amount == token.mint(_address, _amount)
        );

        totalSupply = totalSupply.sub(_amount);
        claimed[_address] = true;
        lockupContract.log(_address, _amount);
    }

    function claimUnsoldTokens() public {
        if (msg.sender == tokenHolder && totalSupply > 0) {
            require(totalSupply == token.mint(msg.sender, totalSupply));
            totalSupply = 0;
        }
    }

    function buy(address _address, uint256 value) internal returns (bool) {
        _address = _address;
        value = value;
        return true;
    }
}

contract LockupContract is Ownable {

    ElyToken public token;
    SellableToken public ico;
    Referral public referral;

    using SafeMath for uint256;

    uint256 public lockPeriod = 2 weeks;
    uint256 public contributionLockPeriod = uint256(1 years).div(2);

    mapping (address => uint256) public lockedAmount;
    mapping (address => uint256) public lockedContributions;

    function LockupContract(
        address _token,
        address _ico,
        address _referral
    ) public {
        require(_token != address(0) && _ico != address(0) && _referral != address(0));
        token = ElyToken(_token);
        ico = SellableToken(_ico);
        referral = Referral(_referral);
    }

    function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0));
        token = ElyToken(_token);
    }

    function setICO(address _ico) public onlyOwner {
        require(_ico != address(0));
        ico = SellableToken(_ico);
    }

    function setRefferal(address _referral) public onlyOwner {
        require(_referral != address(0));
        referral = Referral(_referral);
    }

    function setLockPeriod(uint256 _period) public onlyOwner {
        lockPeriod = _period;
    }

    function setContributionLockPeriod(uint256 _period) public onlyOwner {
        contributionLockPeriod = _period;
    }

    function log(address _address, uint256 _amount) public {
        if (msg.sender == address(referral) || msg.sender == address(token)) {
            lockedAmount[_address] = lockedAmount[_address].add(_amount);
        }
    }

    function decreaseAfterBurn(address _address, uint256 _amount) public {
        if (msg.sender == address(ico)) {
            lockedContributions[_address] = lockedContributions[_address].sub(_amount);
        }
    }

    function logLargeContribution(address _address, uint256 _amount) public {
        if (msg.sender == address(ico)) {
            lockedContributions[_address] = lockedContributions[_address].add(_amount);
        }
    }

    function isTransferAllowed(address _address, uint256 _value) public view returns (bool) {
        if (ico.endTime().add(lockPeriod) < block.timestamp) {
            return checkLargeContributionsLock(_address, _value);
        }
        if (token.balanceOf(_address).sub(lockedAmount[_address]) >= _value) {
            return checkLargeContributionsLock(_address, _value);
        }

        return false;
    }

    function checkLargeContributionsLock(address _address, uint256 _value) public view returns (bool) {
        if (ico.endTime().add(contributionLockPeriod) < block.timestamp) {
            return true;
        }
        if (token.balanceOf(_address).sub(lockedContributions[_address]) >= _value) {
            return true;
        }

        return false;
    }

}

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

contract PeriodicTokenVesting is TokenVesting {
    uint256 public periods;

    function PeriodicTokenVesting(
        address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _periods, bool _revocable
    )
    public TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable)
    {
        periods = _periods;
    }

     
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration * periods) || revoked[token]) {
            return totalBalance;
        } else {

            uint256 periodTokens = totalBalance.div(periods);

            uint256 periodsOver = now.sub(start).div(duration) + 1;

            if (periodsOver >= periods) {
                return totalBalance;
            }

            return periodTokens.mul(periodsOver);
        }
    }
}

contract ElyAllocation is Ownable {

    using SafeERC20 for ERC20Basic;
    using SafeMath for uint256;

    uint256 public icoEndTime;

    address[] public vestings;

    event VestingCreated(
        address _vesting,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _periods,
        bool _revocable
    );

    event VestingRevoked(address _vesting);

    function setICOEndTime(uint256 _icoEndTime) public onlyOwner {
        icoEndTime = _icoEndTime;
    }

    function vestingMint(PeriodicTokenVesting _vesting, MintingERC20 _token, uint256 _amount) public onlyOwner {
        require(_amount > 0 && _token.mint(address(_vesting), _amount) == _amount);
    }

    function createVesting(
        address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _periods, bool _revocable
    ) public onlyOwner returns (PeriodicTokenVesting) {
        PeriodicTokenVesting vesting = new PeriodicTokenVesting(
            _beneficiary, _start, _cliff, _duration, _periods, _revocable
        );

        vestings.push(vesting);

        VestingCreated(vesting, _beneficiary, _start, _cliff, _duration, _periods, _revocable);

        return vesting;
    }

    function revokeVesting(PeriodicTokenVesting _vesting, MintingERC20 token) public onlyOwner() {
        _vesting.revoke(token);

        VestingRevoked(_vesting);
    }
}