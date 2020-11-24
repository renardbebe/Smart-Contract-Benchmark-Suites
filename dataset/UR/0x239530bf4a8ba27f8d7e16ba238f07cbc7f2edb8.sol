 

pragma solidity 0.4.25;
 


 
interface P3D {
    function buy(address) external payable returns(uint256);
    function transfer(address, uint256) external returns(bool);
    function myTokens() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function myDividends(bool) external view returns(uint256);
    function withdraw() external;
    function calculateTokensReceived(uint256) external view returns(uint256);
    function stakingRequirement() external view returns(uint256);
}

 
interface usingP5D {
    function tokenCallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

 
interface controllingP5D {
    function approvalCallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract P5D {

     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator() {
        require(administrators[msg.sender] || msg.sender == _dev);
        _;
    }

     
     
     
    modifier purchaseFilter(address _sender, uint256 _amountETH) {

        require(!isContract(_sender) || canAcceptTokens_[_sender]);
        
        if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }

         
         
        if (onlyAmbassadors && ((totalAmbassadorQuotaSpent_ + _amountETH) <= ambassadorQuota_)) {
            require(
                 
                ambassadors_[_sender] == true &&

                 
                (ambassadorAccumulatedQuota_[_sender] + _amountETH) <= ambassadorMaxPurchase_
            );

             
            ambassadorAccumulatedQuota_[_sender] = SafeMath.add(ambassadorAccumulatedQuota_[_sender], _amountETH);
            totalAmbassadorQuotaSpent_ = SafeMath.add(totalAmbassadorQuotaSpent_, _amountETH);

             
            _;
        } else {
            require(!onlyAmbassadors);
            _;
        }

    }

     
    event onTokenPurchase(
        address indexed _customerAddress,
        uint256 _incomingP3D,
        uint256 _tokensMinted,
        address indexed _referredBy
    );

    event onTokenSell(
        address indexed _customerAddress,
        uint256 _tokensBurned,
        uint256 _P3D_received
    );

    event onReinvestment(
        address indexed _customerAddress,
        uint256 _P3D_reinvested,
        uint256 _tokensMinted
    );

    event onSubdivsReinvestment(
        address indexed _customerAddress,
        uint256 _ETH_reinvested,
        uint256 _tokensMinted
    );

    event onWithdraw(
        address indexed _customerAddress,
        uint256 _P3D_withdrawn
    );

    event onSubdivsWithdraw(
        address indexed _customerAddress,
        uint256 _ETH_withdrawn
    );

    event onNameRegistration(
        address indexed _customerAddress,
        string _registeredName
    );

     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokens
    );

    event Approval(
        address indexed _tokenOwner,
        address indexed _spender,
        uint256 _tokens
    );


     
    string public name = "PoWH5D";
    string public symbol = "P5D";
    uint256 constant public decimals = 18;
    uint256 constant internal buyDividendFee_ = 10;  
    uint256 constant internal buyDividendFee2_ = 20;  
    uint256 constant internal sellDividendFee_ = 2;  
    uint256 constant internal sellDividendFee2_ = 10;  
    uint256 internal tokenPriceInitial_;  
    uint256 constant internal tokenPriceIncremental_ = 1e8;  
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 1e22;  
    uint256 constant internal initialBuyLimitPerTx_ = 1 ether;
    uint256 constant internal initialBuyLimitCap_ = 10 ether;
    uint256 internal totalInputETH_ = 0;


     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 12 ether;
    uint256 internal totalAmbassadorQuotaSpent_ = 0;
    address internal _dev;


    uint256 public ACTIVATION_TIME;


    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal dividendsStored_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(address => bool) public administrators;

     
    bool public onlyAmbassadors = true;

     
    mapping(address => bool) public canAcceptTokens_;

     
    mapping(address => mapping (address => uint256)) public allowed;

     
    P3D internal _P3D;

     
    struct P3D_dividends {
        uint256 balance;
        uint256 lastDividendPoints;
    }
    mapping(address => P3D_dividends) internal divsMap_;
    uint256 internal totalDividendPoints_;
    uint256 internal lastContractBalance_;

     
    struct NameRegistry {
        uint256 activeIndex;
        bytes32[] registeredNames;
    }
    mapping(address => NameRegistry) internal customerNameMap_;
    mapping(bytes32 => address) internal globalNameMap_;
    uint256 constant internal nameRegistrationFee = 0.01 ether;


     
     
    constructor(uint256 _activationTime, address _P3D_address) public {

        _dev = msg.sender;

        ACTIVATION_TIME = _activationTime;

        totalDividendPoints_ = 1;  

        _P3D = P3D(_P3D_address);

         
         
         
         
         
        uint256 _P3D_received;
        (, _P3D_received) = calculateTokensReceived(ambassadorQuota_);
        tokenPriceInitial_ = tokenPriceIncremental_ * _P3D_received / 1e18;

         
        administrators[_dev] = true;
        
         
        ambassadors_[_dev] = true;
    }

  
    function getSupply() public view returns (uint256) {
       
        return totalSupply();
    }
    
    function getExitFee() public view returns (uint256) {
        uint tsupply = getSupply();
        if (tsupply <= 25e22) { 
            return sellDividendFee2_;  
        } else if (tsupply > 25e22 && tsupply <= 5e23) {
            return (uint8) (sellDividendFee2_  - 1);  
        } else if (tsupply > 5e23 && tsupply <= 75e22) {
            return (uint8) (sellDividendFee2_  - 2);  
        } else if (tsupply > 75e22 && tsupply <= 1e24) {
            return (uint8) (sellDividendFee2_  - 3);  
        } else if (tsupply > 1e24 && tsupply <= 125e22) {
            return (uint8) (sellDividendFee2_  - 4);  
        } else if (tsupply > 125e22 && tsupply <= 15e24) {
            return (uint8) (sellDividendFee2_  - 5);  
        } else if (tsupply > 15e23 && tsupply <= 2e24) {
            return (uint8) ( sellDividendFee2_ - 6);  
        } else if (tsupply > 2e24 && tsupply <= 3e24) {
            return (uint8) (sellDividendFee2_  - 7);  
        } else {
            return sellDividendFee_;  
        }
    }
    
    function getEntryFee() public view returns (uint256) {
        uint tsupply = getSupply();
        if (tsupply <= 100000e18) { 
            return buyDividendFee2_;  
        } else if (tsupply > 1e23 && tsupply <= 1e23) {
            return (uint8) (buyDividendFee2_  - 1);  
        } else if (tsupply > 2e23 && tsupply <= 3e23) {
            return (uint8) (buyDividendFee2_  - 2);  
        } else if (tsupply > 3e23 && tsupply <= 4e23) {
            return (uint8) (buyDividendFee2_  - 3);  
        } else if (tsupply > 4e23 && tsupply <= 5e23) {
            return (uint8) (buyDividendFee2_  - 4);  
        } else if (tsupply > 5e23 && tsupply <= 1e24) {
            return (uint8) (buyDividendFee2_  - 5);  
        } else if (tsupply > 1e24 && tsupply <= 2e24) {
            return (uint8) (buyDividendFee2_  - 6);  
        } else if (tsupply > 2e24 && tsupply <= 3e24) {
            return (uint8) (buyDividendFee2_  - 7);  
        } else if (tsupply > 3e24 && tsupply <= 4e24) {
            return (uint8) (buyDividendFee2_  - 8);  
        } else if (tsupply > 4e24 && tsupply <= 5e24) {
            return (uint8) (buyDividendFee2_  - 9);  
        } else {
            return buyDividendFee_;  
        }
    }
    
    
    

     
    function buy(address _referredBy)
        payable
        public
        returns(uint256)
    {
        return purchaseInternal(msg.sender, msg.value, _referredBy);
    }

     
    function buyWithNameRef(string memory _nameOfReferrer)
        payable
        public
        returns(uint256)
    {
        return purchaseInternal(msg.sender, msg.value, ownerOfName(_nameOfReferrer));
    }

     
    function()
        payable
        public
    {
        if (msg.sender != address(_P3D)) {
            purchaseInternal(msg.sender, msg.value, address(0x0));
        }

         
         
         
         
         
         
         
         
         
         
    }

     
    function donate()
        payable
        public
    {
         
         
         
         
         
         
         
    }

     
    function registerName(string memory _name)
        payable
        public
    {
        address _customerAddress = msg.sender;
        require(!onlyAmbassadors || ambassadors_[_customerAddress]);

        require(bytes(_name).length > 0);
        require(msg.value >= nameRegistrationFee);
        uint256 excess = SafeMath.sub(msg.value, nameRegistrationFee);

        bytes32 bytesName = stringToBytes32(_name);
        require(globalNameMap_[bytesName] == address(0x0));

        NameRegistry storage customerNamesInfo = customerNameMap_[_customerAddress];
        customerNamesInfo.registeredNames.push(bytesName);
        customerNamesInfo.activeIndex = customerNamesInfo.registeredNames.length - 1;

        globalNameMap_[bytesName] = _customerAddress;

        if (excess > 0) {
            _customerAddress.transfer(excess);
        }

         
        emit onNameRegistration(_customerAddress, _name);

         
         
         
    }

     
    function changeActiveNameTo(string memory _name)
        public
    {
        address _customerAddress = msg.sender;
        require(_customerAddress == ownerOfName(_name));

        bytes32 bytesName = stringToBytes32(_name);
        NameRegistry storage customerNamesInfo = customerNameMap_[_customerAddress];

        uint256 newActiveIndex = 0;
        for (uint256 i = 0; i < customerNamesInfo.registeredNames.length; i++) {
            if (bytesName == customerNamesInfo.registeredNames[i]) {
                newActiveIndex = i;
                break;
            }
        }

        customerNamesInfo.activeIndex = newActiveIndex;
    }

     
    function changeActiveNameIndexTo(uint256 _newActiveIndex)
        public
    {
        address _customerAddress = msg.sender;
        NameRegistry storage customerNamesInfo = customerNameMap_[_customerAddress];

        require(_newActiveIndex < customerNamesInfo.registeredNames.length);
        customerNamesInfo.activeIndex = _newActiveIndex;
    }

     
    function reinvest(bool)
        public
    {
         
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        uint256 reinvestableDividends = dividendsStored_[_customerAddress];
        reinvestAmount(reinvestableDividends);
    }

     
    function reinvestAmount(uint256 _amountOfP3D)
        public
    {
         
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        if (_amountOfP3D > 0 && _amountOfP3D <= dividendsStored_[_customerAddress]) {
            dividendsStored_[_customerAddress] = SafeMath.sub(dividendsStored_[_customerAddress], _amountOfP3D);

             
            uint256 _tokens = purchaseTokens(_customerAddress, _amountOfP3D, address(0x0));

             
            emit onReinvestment(_customerAddress, _amountOfP3D, _tokens);
        }
    }

     
    function reinvestSubdivs(bool)
        public
    {
         
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        uint256 reinvestableSubdividends = divsMap_[_customerAddress].balance;
        reinvestSubdivsAmount(reinvestableSubdividends);
    }

     
    function reinvestSubdivsAmount(uint256 _amountOfETH)
        public
    {
         
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        if (_amountOfETH > 0 && _amountOfETH <= divsMap_[_customerAddress].balance) {
            divsMap_[_customerAddress].balance = SafeMath.sub(divsMap_[_customerAddress].balance, _amountOfETH);
            lastContractBalance_ = SafeMath.sub(lastContractBalance_, _amountOfETH);

             
            uint256 _tokens = purchaseInternal(_customerAddress, _amountOfETH, address(0x0));

             
            emit onSubdivsReinvestment(_customerAddress, _amountOfETH, _tokens);
        }
    }

     
    function exit(bool)
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

         
        withdraw(true);
        withdrawSubdivs(true);
    }

     
    function withdraw(bool)
        public
    {
         
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        uint256 withdrawableDividends = dividendsStored_[_customerAddress];
        withdrawAmount(withdrawableDividends);
    }

     
    function withdrawAmount(uint256 _amountOfP3D)
        public
    {
         
        address _customerAddress = msg.sender;
        withdrawInternal(_customerAddress);

        if (_amountOfP3D > 0 && _amountOfP3D <= dividendsStored_[_customerAddress]) {
            dividendsStored_[_customerAddress] = SafeMath.sub(dividendsStored_[_customerAddress], _amountOfP3D);
            
             
            require(_P3D.transfer(_customerAddress, _amountOfP3D));
             
             
             

             
            emit onWithdraw(_customerAddress, _amountOfP3D);
        }
    }

     
    function withdrawSubdivs(bool)
        public
    {
         
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        uint256 withdrawableSubdividends = divsMap_[_customerAddress].balance;
        withdrawSubdivsAmount(withdrawableSubdividends);
    }

     
    function withdrawSubdivsAmount(uint256 _amountOfETH)
        public
    {
         
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

        if (_amountOfETH > 0 && _amountOfETH <= divsMap_[_customerAddress].balance) {
            divsMap_[_customerAddress].balance = SafeMath.sub(divsMap_[_customerAddress].balance, _amountOfETH);
            lastContractBalance_ = SafeMath.sub(lastContractBalance_, _amountOfETH);

             
            _customerAddress.transfer(_amountOfETH);

             
            emit onSubdivsWithdraw(_customerAddress, _amountOfETH);
        }
    }

     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
        updateSubdivsFor(_customerAddress);

         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _P3D_amount = tokensToP3D_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_amount, getExitFee()), 100);
        uint256 _taxedP3D = SafeMath.sub(_P3D_amount, _dividends);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256)(profitPerShare_ * _tokens + (_taxedP3D * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        emit onTokenSell(_customerAddress, _tokens, _taxedP3D);
        emit Transfer(_customerAddress, address(0x0), _tokens);
    }

     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        address _customerAddress = msg.sender;
        return transferInternal(_customerAddress, _toAddress, _amountOfTokens);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _data)
        external
        returns(bool)
    {
        require(canAcceptTokens_[_to]);  
        require(transfer(_to, _value));  

        if (isContract(_to)) {
            usingP5D receiver = usingP5D(_to);
            require(receiver.tokenCallback(msg.sender, _value, _data));
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amountOfTokens)
        public
        returns(bool)
    {
        require(allowed[_from][msg.sender] >= _amountOfTokens);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _amountOfTokens);

        return transferInternal(_from, _to, _amountOfTokens);
    }

     
    function approve(address _spender, uint256 _tokens)
        public
        returns(bool)
    {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

     
    function approveAndCall(address _to, uint256 _value, bytes _data)
        external
        returns(bool)
    {
        require(approve(_to, _value));  

        if (isContract(_to)) {
            controllingP5D receiver = controllingP5D(_to);
            require(receiver.approvalCallback(msg.sender, _value, _data));
        }

        return true;
    }


     
     
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

     
    function setAmbassador(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        ambassadors_[_identifier] = _status;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }

     
    function setCanAcceptTokens(address _address)
        onlyAdministrator()
        public
    {
        require(isContract(_address));
        canAcceptTokens_[_address] = true;  
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


     
     
    function totalBalance()
        public
        view
        returns(uint256)
    {
        return _P3D.myTokens();
    }

     
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return (_includeReferralBonus ? dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress) : dividendsOf(_customerAddress));
    }

     
    function myStoredDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return storedDividendsOf(_customerAddress);
    }

     
    function mySubdividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return subdividendsOf(_customerAddress);
    }

     
    function balanceOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (uint256)((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function referralDividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return referralBalance_[_customerAddress];
    }

     
    function storedDividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return dividendsStored_[_customerAddress] + dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress);
    }

     
    function subdividendsOwing(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (divsMap_[_customerAddress].lastDividendPoints == 0 ? 0 : (balanceOf(_customerAddress) * (totalDividendPoints_ - divsMap_[_customerAddress].lastDividendPoints)) / magnitude);
    }

     
    function subdividendsOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return SafeMath.add(divsMap_[_customerAddress].balance, subdividendsOwing(_customerAddress));
    }

     
    function allowance(address _tokenOwner, address _spender) 
        public
        view
        returns(uint256)
    {
        return allowed[_tokenOwner][_spender];
    }

     
    function namesOf(address _customerAddress)
        public
        view
        returns(uint256 activeIndex, string activeName, bytes32[] customerNames)
    {
        NameRegistry memory customerNamesInfo = customerNameMap_[_customerAddress];

        uint256 length = customerNamesInfo.registeredNames.length;
        customerNames = new bytes32[](length);

        for (uint256 i = 0; i < length; i++) {
            customerNames[i] = customerNamesInfo.registeredNames[i];
        }

        activeIndex = customerNamesInfo.activeIndex;
        activeName = activeNameOf(_customerAddress);
    }

     
    function ownerOfName(string memory _name)
        public
        view
        returns(address)
    {
        if (bytes(_name).length > 0) {
            bytes32 bytesName = stringToBytes32(_name);
            return globalNameMap_[bytesName];
        } else {
            return address(0x0);
        }
    }

     
    function activeNameOf(address _customerAddress)
        public
        view
        returns(string)
    {
        NameRegistry memory customerNamesInfo = customerNameMap_[_customerAddress];
        if (customerNamesInfo.registeredNames.length > 0) {
            bytes32 activeBytesName = customerNamesInfo.registeredNames[customerNamesInfo.activeIndex];
            return bytes32ToString(activeBytesName);
        } else {
            return "";
        }
    }

     
    function sellPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _P3D_received = tokensToP3D_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, getExitFee()), 100);
            uint256 _taxedP3D = SafeMath.sub(_P3D_received, _dividends);

            return _taxedP3D;
        }
    }
    
    


     
     
    function buyPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _P3D_received = tokensToP3D_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, getEntryFee()), 100);
            uint256 _taxedP3D =  SafeMath.add(_P3D_received, _dividends);
            
            return _taxedP3D;
        }
    }
    

     
    function calculateTokensReceived(uint256 _amountOfETH)
        public
        view
        returns(uint256 _P3D_received, uint256 _P5D_received)
    {
        uint256 P3D_received = _P3D.calculateTokensReceived(_amountOfETH);
        uint256 _dividends = SafeMath.div(SafeMath.mul(P3D_received, getEntryFee()), 100);
        uint256 _taxedP3D = SafeMath.sub(P3D_received, _dividends);
        uint256 _amountOfTokens = P3DtoTokens_(_taxedP3D);
        
        return (P3D_received, _amountOfTokens);
    }

     
    function calculateAmountReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _P3D_received = tokensToP3D_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_P3D_received, getExitFee()), 100);
        uint256 _taxedP3D = SafeMath.sub(_P3D_received, _dividends);
        
        return _taxedP3D;
    }

     
    function P3D_address()
        public
        view
        returns(address)
    {
        return address(_P3D);
    }

     
    function fetchAllDataForCustomer(address _customerAddress)
        public
        view
        returns(uint256 _totalSupply, uint256 _totalBalance, uint256 _buyPrice, uint256 _sellPrice, uint256 _activationTime,
                uint256 _customerTokens, uint256 _customerUnclaimedDividends, uint256 _customerStoredDividends, uint256 _customerSubdividends)
    {
        _totalSupply = totalSupply();
        _totalBalance = totalBalance();
        _buyPrice = buyPrice();
        _sellPrice = sellPrice();
        _activationTime = ACTIVATION_TIME;
        _customerTokens = balanceOf(_customerAddress);
        _customerUnclaimedDividends = dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress);
        _customerStoredDividends = storedDividendsOf(_customerAddress);
        _customerSubdividends = subdividendsOf(_customerAddress);
    }


     

     
     
     
     
     
    function updateSubdivsFor(address _customerAddress)
        internal
    {   
         
        if (_P3D.myDividends(true) > 0) {
            _P3D.withdraw();
        }

         
        uint256 contractBalance = address(this).balance;
        if (contractBalance > lastContractBalance_ && totalSupply() != 0) {
            uint256 additionalDivsFromP3D = SafeMath.sub(contractBalance, lastContractBalance_);
            totalDividendPoints_ = SafeMath.add(totalDividendPoints_, SafeMath.div(SafeMath.mul(additionalDivsFromP3D, magnitude), totalSupply()));
            lastContractBalance_ = contractBalance;
        }

         
        if (divsMap_[_customerAddress].lastDividendPoints == 0) {
            divsMap_[_customerAddress].lastDividendPoints = totalDividendPoints_;
        }

         
        uint256 owing = subdividendsOwing(_customerAddress);
        if (owing > 0) {
            divsMap_[_customerAddress].balance = SafeMath.add(divsMap_[_customerAddress].balance, owing);
            divsMap_[_customerAddress].lastDividendPoints = totalDividendPoints_;
        }
    }

    function withdrawInternal(address _customerAddress)
        internal
    {
         
         
        uint256 _dividends = dividendsOf(_customerAddress);  

         
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        dividendsStored_[_customerAddress] = SafeMath.add(dividendsStored_[_customerAddress], _dividends);
    }

    function transferInternal(address _customerAddress, address _toAddress, uint256 _amountOfTokens)
        internal
        returns(bool)
    {
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        updateSubdivsFor(_customerAddress);
        updateSubdivsFor(_toAddress);

         
        if ((dividendsOf(_customerAddress) + referralDividendsOf(_customerAddress)) > 0) withdrawInternal(_customerAddress);

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _amountOfTokens);

         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
    }

    function purchaseInternal(address _sender, uint256 _incomingEthereum, address _referredBy)
        purchaseFilter(_sender, _incomingEthereum)
        internal
        returns(uint256)
    {

        uint256 purchaseAmount = _incomingEthereum;
        uint256 excess = 0;
        if (totalInputETH_ <= initialBuyLimitCap_) {  
            if (purchaseAmount > initialBuyLimitPerTx_) {  
                purchaseAmount = initialBuyLimitPerTx_;
                excess = SafeMath.sub(_incomingEthereum, purchaseAmount);
            }
            totalInputETH_ = SafeMath.add(totalInputETH_, purchaseAmount);
        }

         
        if (excess > 0) {
             _sender.transfer(excess);
        }

         
         
         
         
        uint256 tmpBalanceBefore = _P3D.myTokens();
        _P3D.buy.value(purchaseAmount)(_referredBy);
        uint256 purchasedP3D = SafeMath.sub(_P3D.myTokens(), tmpBalanceBefore);

        return purchaseTokens(_sender, purchasedP3D, _referredBy);
    }


    function purchaseTokens(address _sender, uint256 _incomingP3D, address _referredBy)
        internal
        returns(uint256)
    {
        updateSubdivsFor(_sender);

         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingP3D, getEntryFee()), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedP3D = SafeMath.sub(_incomingP3D, _undividedDividends);
        uint256 _amountOfTokens = P3DtoTokens_(_taxedP3D);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

         
        if (
             
            _referredBy != address(0x0) &&

             
            _referredBy != _sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if(tokenSupply_ > 0){

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[_sender] = SafeMath.add(tokenBalanceLedger_[_sender], _amountOfTokens);

         
         
        payoutsTo_[_sender] += (int256)((profitPerShare_ * _amountOfTokens) - _fee);

         
        emit onTokenPurchase(_sender, _incomingP3D, _amountOfTokens, _referredBy);
        emit Transfer(address(0x0), _sender, _amountOfTokens);

        return _amountOfTokens;
    }

     
    function P3DtoTokens_(uint256 _P3D_received)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                 
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2 * (tokenPriceIncremental_ * 1e18)*(_P3D_received * 1e18))
                            +
                            (((tokenPriceIncremental_)**2) * (tokenSupply_**2))
                            +
                            (2 * (tokenPriceIncremental_) * _tokenPriceInitial * tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)
        ) - (tokenSupply_);

        return _tokensReceived;
    }

     
    function tokensToP3D_(uint256 _P5D_tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_P5D_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _P3D_received =
        (
             
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                        ) - tokenPriceIncremental_
                    ) * (tokens_ - 1e18)
                ), (tokenPriceIncremental_ * ((tokens_**2 - tokens_) / 1e18)) / 2
            )
        / 1e18);

        return _P3D_received;
    }


     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
    function isContract(address _addr)
        internal
        constant
        returns(bool)
    {
         
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

     
    function stringToBytes32(string memory _s)
        internal
        pure
        returns(bytes32 result)
    {
        bytes memory tmpEmptyStringTest = bytes(_s);
        if (tmpEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly { result := mload(add(_s, 32)) }
    }

     
    function bytes32ToString(bytes32 _b)
        internal
        pure
        returns(string)
    {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 i = 0; i < 32; i++) {
            byte char = byte(bytes32(uint(_b) * 2 ** (8 * i)));
            if (char != 0) {
                bytesString[charCount++] = char;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (i = 0; i < charCount; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
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


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 