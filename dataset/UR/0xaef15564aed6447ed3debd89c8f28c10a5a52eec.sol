 

pragma solidity ^0.4.15;

contract Permittable {
    mapping(address => bool) permitted;

    function Permittable() public {
        permitted[msg.sender] = true;
    }

    modifier onlyPermitted() {
        require(permitted[msg.sender]);
        _;
    }

    function permit(address _address, bool _isAllowed) public onlyPermitted {
        permitted[_address] = _isAllowed;
    }

    function isPermitted(address _address) public view returns (bool) {
        return permitted[_address];
    }
}

contract Destructable is Permittable {
    function kill() public onlyPermitted {
        selfdestruct(msg.sender);
    }
}

contract Withdrawable is Permittable {
    function withdraw(address _to, uint256 _amount) public onlyPermitted {
        require(_to != address(0));

        if (_amount == 0)
            _amount = this.balance;

        _to.transfer(_amount);
    }
}

contract ERC20Token {

     
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

     
    event Approval(address indexed _owner, address indexed _recipient, uint256 _amount);

    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
    function approve(address _recipient, uint256 _amount) public returns (bool success);
    function allowance(address _owner, address _recipient) public constant returns (uint256 remaining);
}

contract TokenStorage is Permittable, Destructable, Withdrawable {
    struct Megabox {
        address owner;
        uint256 totalSupply;
        uint256 timestamp;
    }

    mapping(address => uint256) private balances;
    mapping(string => uint256) private settings;
    mapping(uint256 => Megabox) private megaboxes;
    uint256 megaboxIndex = 0;

    function _start() public onlyPermitted {
         
        uint decimalPlaces = 8;
        setSetting("decimalPlaces", decimalPlaces);

         
        setSetting("multiplier", 10 ** decimalPlaces);

         
        setSetting("exhaustingNumber", 2 * 10**decimalPlaces);

         
        setSetting("tokenPrice", 15283860872157044);

         
        setSetting("percentage", 1000);

         
        setSetting("transferFee", 10);

         
        setSetting("purchaseFee", 0);

         
        setSetting("purchaseCap", 0);

         
        setSetting("purchaseTimeout", 0);

         
        setSetting("icoTimestamp", now);

         
        setSetting("redemptionTimeout", 365 * 24 * 60 * 60);

         
        setSetting("redemptionFee", 0);

         
        setSetting("feeReturnAddress", uint(address(0x0d026A63a88A0FEc2344044e656D6B63684FBeA1)));

         
        setSetting("deadTokensAddress", uint(address(0x4DcB8F5b22557672B35Ef48F8C2b71f8F54c251F)));

         
        setSetting("totalSupply", 100 * 1000 * 1000 * (10 ** decimalPlaces));

        setSetting("newMegaboxThreshold", 1 * 10**decimalPlaces);
    }

    function getBalance(address _address) public view onlyPermitted returns(uint256) {
        return balances[_address];
    }

    function setBalance(address _address, uint256 _amount) public onlyPermitted returns (uint256) {
        balances[_address] = _amount;
        return balances[_address];
    }

    function transfer(address _from, address _to, uint256 _amount) public onlyPermitted returns (uint256) {
        require(balances[_from] >= _amount);

        decreaseBalance(_from, _amount);
        increaseBalance(_to, _amount);
        return _amount;
    }

    function decreaseBalance(address _address, uint256 _amount) public onlyPermitted returns (uint256) {
        require(balances[_address] >= _amount);

        balances[_address] -= _amount;
        return _amount;
    }

    function increaseBalance(address _address, uint256 _amount) public onlyPermitted returns (uint256) {
        balances[_address] += _amount;
        return _amount;
    }

    function getSetting(string _name) public view onlyPermitted returns(uint256) {
        return settings[_name];
    }

    function getSettingAddress(string _name) public view onlyPermitted returns(address) {
        return address(getSetting(_name));
    }

    function setSetting(string _name, uint256 _value) public onlyPermitted returns (uint256) {
        settings[_name] = _value;
        return settings[_name];
    }

    function newMegabox(address _owner, uint256 _tokens, uint256 _timestamp) public onlyPermitted {
        uint newMegaboxIndex = megaboxIndex++;
        megaboxes[newMegaboxIndex] = Megabox({owner: _owner, totalSupply: _tokens, timestamp: _timestamp});

        setSetting("totalSupply", getSetting("totalSupply") + _tokens);

        uint256 balance = balances[_owner] + _tokens;
        setBalance(_owner, balance);
    }

    function getMegabox(uint256 index) public view onlyPermitted returns (address, uint256, uint256) {
        return (megaboxes[index].owner, megaboxes[index].totalSupply, megaboxes[index].timestamp);
    }

    function getMegaboxIndex() public view onlyPermitted returns (uint256) {
        return megaboxIndex;
    }
}

contract TokenValidator is Permittable, Destructable {
    TokenStorage store;
    mapping(address => uint256) datesOfPurchase;

    function _setStore(address _address) public onlyPermitted {
        store = TokenStorage(_address);
    }

    function getTransferFee(address _owner, address _address, uint256 _amount) public view returns(uint256) {
        return (_address == _owner) ? 0 : (_amount * store.getSetting("transferFee") / store.getSetting("percentage"));
    }

    function validateAndGetTransferFee(address _owner, address _from, address  , uint256 _amount) public view returns(uint256) {
        uint256 _fee = getTransferFee(_owner, _from, _amount);

        require(_amount > 0);
        require((_amount + _fee) > 0);
        require(store.getBalance(_from) >= (_amount + _fee));

        return _fee;
    }

    function validateResetDeadTokens(uint256 _amount) public view returns(address) {
        address deadTokensAddress = store.getSettingAddress("deadTokensAddress");
        uint256 deadTokens = store.getBalance(deadTokensAddress);

        require(_amount > 0);
        require(_amount <= deadTokens);

        return deadTokensAddress;
    }

    function validateStart(address _owner, address _store) public view {
        require(_store != address(0));
        require(_store == address(store));
        require(store.getBalance(_owner) == 0);
    }

    function validateAndGetPurchaseTokens(address _owner, address _address, uint256 _moneyAmount) public view returns (uint256) {
        uint256 _tokens = _moneyAmount * store.getSetting("multiplier") / store.getSetting("tokenPrice");
        uint256 _purchaseTimeout = store.getSetting("purchaseTimeout");
        uint256 _purchaseCap = store.getSetting("purchaseCap");

        require((_purchaseTimeout <= 0) || (block.timestamp - datesOfPurchase[_address] > _purchaseTimeout));
        require(_tokens > 0);
        require(store.getBalance(_owner) >= _tokens);
        require((_purchaseCap <= 0) || (_tokens <= _purchaseCap));

        return _tokens;
    }

    function updateDateOfPurchase(address _address, uint256 timestamp) public onlyPermitted {
        datesOfPurchase[_address] = timestamp;
    }

    function validateAndGetRedeemFee(address  , address _address, uint256 _tokens) public view returns (uint256) {
        uint256 _icoTimestamp = store.getSetting("icoTimestamp");
        uint256 _redemptionTimeout = store.getSetting("redemptionTimeout");
        uint256 _fee = _tokens * store.getSetting("redemptionFee") / store.getSetting("percentage");

        require((_redemptionTimeout <= 0) || (block.timestamp > _icoTimestamp + _redemptionTimeout));
        require(_tokens > 0);
        require((_tokens + _fee) >= 0);
        require(store.getBalance(_address) >= (_tokens + _fee));

        return _fee;
    }

    function validateStartMegabox(address _owner, uint256 _tokens) public view {
        uint256 _totalSupply = store.getSetting("totalSupply");
        uint256 _newMegaboxThreshold = store.getSetting("newMegaboxThreshold");
        uint256 _ownerBalance = store.getBalance(_owner);

        require(_ownerBalance <= _newMegaboxThreshold);
        require(_tokens > 0);
        require((_totalSupply + _tokens) > _totalSupply);
    }

    function canPurchase(address _owner, address _address, uint256 _tokens) public view returns(bool, bool, bool, bool) {
        uint256 _purchaseTimeout = store.getSetting("purchaseTimeout");
        uint256 _fee = _tokens * store.getSetting("purchaseFee") / store.getSetting("percentage");

        bool purchaseTimeoutPassed = ((_purchaseTimeout <= 0) || (block.timestamp - datesOfPurchase[_address] > _purchaseTimeout));
        bool tokensNumberPassed = (_tokens > 0);
        bool ownerBalancePassed = (store.getBalance(_owner) >= (_tokens + _fee));
        bool purchaseCapPassed = (store.getSetting("purchaseCap") <= 0) || (_tokens < store.getSetting("purchaseCap"));

        return (purchaseTimeoutPassed, ownerBalancePassed, tokensNumberPassed, purchaseCapPassed);
    }

    function canTransfer(address _owner, address _from, address  , uint256 _amount) public view returns (bool, bool) {
        uint256 _fee = getTransferFee(_owner, _from, _amount);

        bool transferPositivePassed = (_amount + _fee) > 0;
        bool ownerBalancePassed = store.getBalance(_from) >= (_amount + _fee);

        return (transferPositivePassed, ownerBalancePassed);
    }
}

contract TokenFacade is Permittable, Destructable, Withdrawable, ERC20Token {
    TokenStorage private store;
    TokenValidator validator;

    address private owner;

     
    uint256 public infoAboveSpot = 400;
    string public infoTier = "Tier 1";
    string public infoTokenSilverRatio = "1 : 1";
     

    event TokenSold(address _from, uint256 _amount);                             
    event TokenPurchased(address _address, uint256 _amount, uint256 _tokens);    
    event TokenPoolExhausting(uint256 _amount);                                  
    event FeeApplied(string _name, address _address, uint256 _amount);

    mapping(address => mapping (address => uint256)) allowed;

    function TokenFacade() public {
        owner = msg.sender;
    }

     
    function () public payable {
        purchase();
    }

    function totalSupply() public constant returns (uint256) {
        return store.getSetting("totalSupply");
    }

    function balanceOf(address _address) public constant returns (uint256) {
        return store.getBalance(_address);
    }

    string public constant symbol = "SLVT";
    string public constant name = "SilverToken";
    uint8 public constant decimals = 8;

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool) {
        uint256 _fee = validator.validateAndGetTransferFee(owner, msg.sender, _to, _amount);

        store.transfer(msg.sender, _to, _amount);

        if (_fee > 0)
            store.transfer(msg.sender, store.getSettingAddress("feeReturnAddress"), _fee);

        Transfer(msg.sender, _to, _amount);

        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(allowed[_from][_to] >= _amount);

        uint256 _fee = validator.validateAndGetTransferFee(owner, _from, _to, _amount);

        store.transfer(_from, _to, _amount);

        if (_fee > 0)
            store.transfer(_from, store.getSettingAddress("feeReturnAddress"), _fee);

        allowed[_from][_to] -= _amount;

        Transfer(_from, _to, _amount);

        return true;
    }

     
     
     
     
    function approve(address _recipient, uint256 _amount) public returns (bool) {
        return __approve_impl(msg.sender, _recipient, _amount);
    }

     
     
     
     
    function allowance(address _from, address _recipient) public constant returns (uint256) {
        return allowed[_from][_recipient];
    }

     
    function purchase() public payable {
        __purchase_impl(msg.sender, msg.value);
    }

     
     
    function redeem(uint256 _tokens) public {
        __redeem_impl(msg.sender, _tokens);
    }

     
     
    function getTokensInAction() public view returns (uint256) {
        address deadTokensAddress = store.getSettingAddress("deadTokensAddress");
        return store.getBalance(owner) - store.getBalance(deadTokensAddress);
    }

     
     
    function getTokensPrice(uint256 _amount, bool withFee) public constant returns (uint256) {
        uint256 tokenPrice = store.getSetting("tokenPrice");
        uint256 result = _amount * tokenPrice / 10**uint256(decimals);

        if (withFee) {
            result = result + result * store.getSetting("purchaseFee") / store.getSetting("percentage");
        }

        return result;
    }

    function resetDeadTokens(uint256 _amount) public onlyPermitted returns (bool) {
        address deadTokensAddress = validator.validateResetDeadTokens(_amount);
        store.transfer(deadTokensAddress, owner, _amount);
    }

    function canPurchase(address _address, uint256 _tokensAmount) public view returns(bool, bool, bool, bool) {
        return validator.canPurchase(owner, _address, _tokensAmount);
    }

    function canTransfer(address _from, address _to, uint256 _amount) public view returns(bool, bool) {
        return validator.canTransfer(owner, _from, _to, _amount);
    }

    function setInfoAboveSpot(uint256 newInfoAboveSpot) public onlyPermitted {
        infoAboveSpot = newInfoAboveSpot;
    }

    function setInfoTier(string newInfoTier) public onlyPermitted {
        infoTier = newInfoTier;
    }

    function setInfoTokenSilverRatio(string newInfoTokenSilverRatio) public onlyPermitted {
        infoTokenSilverRatio = newInfoTokenSilverRatio;
    }

    function getSetting(string _name) public view returns (uint256) {
        return store.getSetting(_name);
    }

    function getMegabox(uint256 index) public view onlyPermitted returns (address, uint256, uint256) {
        return store.getMegabox(index);
    }

    function getMegaboxIndex() public view onlyPermitted returns (uint256) {
        return store.getMegaboxIndex();
    }

     

    function _approve(address _from, address _recipient, uint256 _amount) public onlyPermitted returns (bool) {
        return __approve_impl(_from, _recipient, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) public onlyPermitted returns (bool) {
        validator.validateAndGetTransferFee(owner, _from, _to, _amount);

        store.transfer(_from, _to, _amount);

        Transfer(_from, _to, _amount);

        return true;
    }

    function _purchase(address _to, uint256 _amount) public onlyPermitted {
        __purchase_impl(_to, _amount);
    }

    function _redeem(address _from, uint256 _tokens) public onlyPermitted {
        __redeem_impl(_from, _tokens);
    }

    function _start() public onlyPermitted {
        validator.validateStart(owner, store);

        store.setBalance(owner, store.getSetting("totalSupply"));
        store.setSetting("icoTimestamp", block.timestamp);
    }

    function _setStore(address _address) public onlyPermitted {
        store = TokenStorage(_address);
    }

    function _setValidator(address _address) public onlyPermitted {
        validator = TokenValidator(_address);
    }

    function _setSetting(string _name, uint256 _value) public onlyPermitted {
        store.setSetting(_name, _value);
    }

    function _startMegabox(uint256 _tokens) public onlyPermitted {
        validator.validateStartMegabox(owner, _tokens);
        store.newMegabox(owner, _tokens, now);
    }

     
     
     

    function __approve_impl(address _sender, address _recipient, uint256 _amount) private returns (bool) {
        allowed[_sender][_recipient] = _amount;
        Approval(_sender, _recipient, _amount);
        return true;
    }

    function __purchase_impl(address _to, uint256 _amount) private {
        uint256 _amountWithoutFee = _amount * store.getSetting("percentage") / (store.getSetting("purchaseFee") + store.getSetting("percentage"));
        uint256 _fee = _amountWithoutFee * store.getSetting("purchaseFee") / store.getSetting("percentage");
        uint256 _ownerBalance = store.getBalance(owner);
        address _feeReturnAddress = store.getSettingAddress("feeReturnAddress");
        uint256 _tokens = validator.validateAndGetPurchaseTokens(owner, msg.sender, _amountWithoutFee);

        store.increaseBalance(_to, _tokens);
        store.decreaseBalance(owner, _tokens);

        if (_fee > 0)
            _feeReturnAddress.transfer(_fee);

        validator.updateDateOfPurchase(_to, now);

        if (_ownerBalance < store.getSetting("exhaustingNumber")) {
            TokenPoolExhausting(_ownerBalance);
        }
        TokenPurchased(_to, msg.value, _tokens);
        Transfer(owner, _to, _tokens);
    }

    function __redeem_impl(address _from, uint256 _tokens) private {
        address deadTokensAddress = store.getSettingAddress("deadTokensAddress");
        address feeReturnAddress = store.getSettingAddress("feeReturnAddress");
        uint256 _fee = validator.validateAndGetRedeemFee(owner, _from, _tokens);

        store.transfer(_from, deadTokensAddress, _tokens);
        store.transfer(_from, feeReturnAddress, _fee);

        TokenSold(_from, _tokens);
    }
}