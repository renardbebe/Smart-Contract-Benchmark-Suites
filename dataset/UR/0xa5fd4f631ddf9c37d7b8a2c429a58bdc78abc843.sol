 

pragma solidity ^0.4.18;

 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


 
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 _allowance);
    function transfer(address _to, uint256 _value) public returns (bool _succes);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _succes);
    function approve(address _spender, uint256 _value) public returns (bool _succes);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract StandardToken is ERC20, SafeMath {
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed; 
    
    function balanceOf(address _owner) public constant returns (uint256){
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256){
        return allowed[_owner][_spender];
    }
    
     
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }
    
     
    function safeTransfer(address _from, address _to, uint256 _value) internal {
             
            require(_to != 0x0);
             
            require(_to != address(this));
             
            balances[_from] = safeSub(balances[_from], _value);
             
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
        safeTransfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];
        
         
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        safeTransfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}


 
contract ExtendedERC20 is StandardToken {
    
     
    function increaseApproval(address _spender, uint256 _addedValue) onlyPayloadSize(2) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) onlyPayloadSize(2) public returns (bool) {
        uint256 currentValue = allowed[msg.sender][_spender];
        require(currentValue > 0);
        if (_subtractedValue > currentValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(currentValue, _subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _extraData);
        return true;
    }
}


 
contract UpgradeAgent {

    uint256 public originalSupply;

     
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    function upgradeFrom(address _from, uint256 _value) public;
}


 
contract UpgradeableToken is StandardToken {

     
    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

     
    uint256 public totalUpgraded;
    
     
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

     
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

     
    event UpgradeAgentSet(address agent);

     
    function UpgradeableToken(address _upgradeMaster) public {
        upgradeMaster = _upgradeMaster;
    }

     
    function upgrade(uint256 value) public {

        UpgradeState state = getUpgradeState();
         
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

         
        require(value != 0);

        balances[msg.sender] = safeSub(balances[msg.sender], value);

         
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);

         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function setUpgradeAgent(address agent) external {

        require(canUpgrade());
        require(agent != 0x0);
         
        require(msg.sender == upgradeMaster);
         
        require(getUpgradeState() != UpgradeState.Upgrading);

        upgradeAgent = UpgradeAgent(agent);

         
        require(upgradeAgent.isUpgradeAgent());
         
        require(upgradeAgent.originalSupply() == totalSupply);

        UpgradeAgentSet(upgradeAgent);
    }

     
    function getUpgradeState() public constant returns (UpgradeState) {
        if(!canUpgrade()) return UpgradeState.NotAllowed;
        else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
        else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else return UpgradeState.Upgrading;
    }

     
    function setUpgradeMaster(address master) public {
        require(master != 0x0);
        require(msg.sender == upgradeMaster);
        upgradeMaster = master;
    }

     
    function canUpgrade() public pure returns (bool) {
        return true;
    }
}


 
contract Ownable {
    address public ownerOne;
    address public ownerTwo;

     
    function Ownable() public {
        ownerOne = msg.sender;
        ownerTwo = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == ownerOne || msg.sender == ownerTwo);
        _;
    }

     
    function transferOwnership(address newOwner, bool replaceOwnerOne, bool replaceOwnerTwo) onlyOwner public {
        require(newOwner != 0x0);
        require(replaceOwnerOne || replaceOwnerTwo);
        if(replaceOwnerOne) ownerOne = newOwner;
        if(replaceOwnerTwo) ownerTwo = newOwner;
    }
}


 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        Unpause();
        return true;
    }
}


 
contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
         
        super.transfer(_to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
         
        super.transferFrom(_from, _to, _value);
        return true;
    }
}


 
contract PurchasableToken is StandardToken, Pausable {
    event PurchaseUnlocked();
    event PurchaseLocked();
    event UpdatedExchangeRate(uint256 newRate);
    
    bool public purchasable = false;
     
    uint256 public minimumWeiAmount;
    address public vendorWallet;
    uint256 public exchangeRate;  
    
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
     
    modifier isPurchasable {
        require(purchasable && exchangeRate > 0 && minimumWeiAmount > 0);
        _;
    }
    
     
    function lockPurchase() onlyOwner public returns (bool) {
        require(purchasable == true);
        purchasable = false;
        PurchaseLocked();
        return true;
    }
    
     
    function unlockPurchase() onlyOwner public returns (bool) {
        require(purchasable == false);
        purchasable = true;
        PurchaseUnlocked();
        return true;
    }

     
    function setExchangeRate(uint256 newExchangeRate) onlyOwner public returns (bool) {
        require(newExchangeRate > 0);
        exchangeRate = newExchangeRate;
        UpdatedExchangeRate(newExchangeRate);
        return true;
    }
    
     
    function setMinimumWeiAmount(uint256 newMinimumWeiAmount) onlyOwner public returns (bool) {
        require(newMinimumWeiAmount > 0);
        minimumWeiAmount = newMinimumWeiAmount;
        return true;
    }
    
     
    function setVendorWallet(address newVendorWallet) onlyOwner public returns (bool) {
        require(newVendorWallet != 0x0);
        vendorWallet = newVendorWallet;
        return true;
    }
    
     
    function setPurchaseValues( uint256 newExchangeRate, 
                                uint256 newMinimumWeiAmount, 
                                address newVendorWallet,
                                bool releasePurchase) onlyOwner public returns (bool) {
        setExchangeRate(newExchangeRate);
        setMinimumWeiAmount(newMinimumWeiAmount);
        setVendorWallet(newVendorWallet);
         
         
        if (releasePurchase && !purchasable) unlockPurchase();
        return true;
    }
    
     
    function buyToken(address beneficiary) payable isPurchasable whenNotPaused public returns (uint256) {
        require(beneficiary != address(0));
        require(beneficiary != address(this));
        uint256 weiAmount = msg.value;
        require(weiAmount >= minimumWeiAmount);
        uint256 tokenAmount = safeMul(weiAmount, exchangeRate);
        tokenAmount = safeDiv(tokenAmount, 1 ether);
        uint256 _allowance = allowed[vendorWallet][this];
         
        allowed[vendorWallet][this] = safeSub(_allowance, tokenAmount);
        balances[beneficiary] = safeAdd(balances[beneficiary], tokenAmount);
        balances[vendorWallet] = safeSub(balances[vendorWallet], tokenAmount);
        vendorWallet.transfer(weiAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
        return tokenAmount; 
    }
    
    function () payable public {
        buyToken(msg.sender);
    }
}


 
contract CrowdsaleToken is PausableToken {
    
     
    mapping (address => bool) icoAgents;
     
    bool public crowdsaleLock = true;

     
    modifier onlyIcoAgent {
        require(isIcoAgent(msg.sender));
        _;
    }
    
     
    modifier canTransfer(address _sender) {
        require(!crowdsaleLock || isIcoAgent(_sender));
        _;
    }
    
     
    function CrowdsaleToken(address _icoAgent) public {
        icoAgents[_icoAgent] = true;
    }
    
     
    function releaseTokenTransfer() onlyIcoAgent public returns (bool) {
        crowdsaleLock = false;
        return true;
    }
    
     
    function setIcoAgent(address _icoAgent, bool _allowTransfer) onlyOwner public returns (bool) {
        icoAgents[_icoAgent] = _allowTransfer;
        return true; 
    }
    
     
    function isIcoAgent(address _address) public view returns (bool) {
        return icoAgents[_address];
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool) {
         
        return super.transferFrom(_from, _to, _value);
    }
}


 
contract CanSendFromContract is Ownable {
    
     
    function sendToken(address beneficiary, address _token) onlyOwner public {
        ERC20 token = ERC20(_token);
        uint256 amount = token.balanceOf(this);
        require(amount>0);
        token.transfer(beneficiary, amount);
    }
    
     
    function sendEther(address beneficiary, uint256 weiAmount) onlyOwner public {
        beneficiary.transfer(weiAmount);
    }
}


 
contract IPCToken is ExtendedERC20, UpgradeableToken, PurchasableToken, CrowdsaleToken, CanSendFromContract {

     
    string public name = "International PayReward Coin";
    string public symbol = "IPC";
    uint8 public decimals = 12;
     
     
    uint256 public cr = 264000000 * (10 ** uint256(decimals));
     
    uint256 public rew = 110000000 * (10 ** uint256(decimals));
     
    uint256 public dev = 66000000 * (10 ** uint256(decimals));
     
    uint256 public totalSupply = cr + dev + rew;    

    event UpdatedTokenInformation(string newName, string newSymbol);
   
     
    function IPCToken (
        address addressOfCrBen, 
        address addressOfRew,
        address addressOfDev
        ) public UpgradeableToken(msg.sender) CrowdsaleToken(addressOfCrBen) {
         
        balances[addressOfCrBen] = cr;
        balances[addressOfRew] = rew;
        balances[addressOfDev] = dev;
    }
    
     
    function setTokenInformation(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
        
        UpdatedTokenInformation(name, symbol);
    }
}