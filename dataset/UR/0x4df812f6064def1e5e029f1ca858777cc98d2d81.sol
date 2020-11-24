 

contract ERC20TokenInterface {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract XaurumProxyERC20 is ERC20TokenInterface {

    bool public xaurumProxyWorking;

    XaurumToken xaurumTokenReference; 

    address proxyCurrator;
    address owner;
    address dev;

     
    string public standard = 'XaurumERCProxy';
    string public name = 'Xaurum';
    string public symbol = 'XAUR';
    uint8 public decimals = 8;


    modifier isWorking(){
        if (xaurumProxyWorking && !xaurumTokenReference.lockdown()){
            _
        }
    }

    function XaurumProxyERC20(){
        dev = msg.sender;
        xaurumProxyWorking = true;
    }

    function setTokenReference(address _xaurumTokenAress) returns (bool){
        if (msg.sender == proxyCurrator){
            xaurumTokenReference = XaurumToken(_xaurumTokenAress);
            return true;
        }
        return false;
    }

    function EnableDisableTokenProxy() returns (bool){
        if (msg.sender == proxyCurrator){        
            xaurumProxyWorking = !xaurumProxyWorking;
            return true;
        }
        return false;
    }

    function setProxyCurrator(address _newCurratorAdress) returns (bool){
        if (msg.sender == owner || msg.sender == dev){        
            proxyCurrator = _newCurratorAdress;
            return true;
        }
        return false;
    }

    function setOwner(address _newOwnerAdress) returns (bool){
        if ( msg.sender == dev ){        
            owner = _newOwnerAdress;
            return true;
        }
        return false;
    }

    function totalSupply() constant returns (uint256 supply) {
        return xaurumTokenReference.totalSupply();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return xaurumTokenReference.balanceOf(_owner);
    }

    function transfer(address _to, uint256 _value) isWorking returns (bool success) {
        bool answerStatus;
        address sentFrom;
        address sentTo;
        uint256 sentToAmount;
        address burningAddress;
        uint256 burningAmount;

        (answerStatus, sentFrom, sentTo, sentToAmount, burningAddress, burningAmount) = xaurumTokenReference.transferViaProxy(msg.sender, _to, _value);
        if(answerStatus){
            Transfer(sentFrom, sentTo, sentToAmount);
            Transfer(sentFrom, burningAddress, burningAmount);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) isWorking returns (bool success) {
        bool answerStatus;
        address sentFrom;
        address sentTo;
        uint256 sentToAmount;
        address burningAddress;
        uint256 burningAmount;

        (answerStatus, sentFrom, sentTo, sentToAmount, burningAddress, burningAmount) = xaurumTokenReference.transferFromViaProxy(msg.sender, _from, _to, _value);
        if(answerStatus){
            Transfer(sentFrom, sentTo, sentToAmount);
            Transfer(sentFrom, burningAddress, burningAmount);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint256 _value) isWorking returns (bool success) {
        if (xaurumTokenReference.approveFromProxy(msg.sender, _spender, _value)){
            Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return xaurumTokenReference.allowanceFromProxy(msg.sender, _owner, _spender);
    } 
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract XaurumToken {
    
     
    string public standard = 'Xaurum v1.0';
    string public name = 'Xaurum';
    string public symbol = 'XAUR';
    uint8 public decimals = 8;

    uint256 public totalSupply = 0;
    uint256 public totalGoldSupply = 0;
    bool public lockdown = false;
    uint256 numberOfCoinages;

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint) lockedAccounts;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address from, uint256 value, BurningType burningType);
    event Melt(uint256 xaurAmount, uint256 goldAmount);
    event Coinage(uint256 coinageId, uint256 usdAmount, uint256 xaurAmount, uint256 goldAmount, uint256 totalGoldSupply, uint256 totalSupply);

     
    enum BurningType { TxtFee, AllyDonation, ServiceFee }

    
    XaurumMeltingContract public meltingContract;
    function setMeltingContract(address _meltingContractAddress){
        if (msg.sender == owner || msg.sender == dev){
            meltingContract = XaurumMeltingContract(_meltingContractAddress);
        }
    }

    XaurumDataContract public dataContract;
    function setDataContract(address _dataContractAddress){
        if (msg.sender == owner || msg.sender == dev){
            dataContract = XaurumDataContract(_dataContractAddress);
        }
    }

    XaurumCoinageContract public coinageContract;
    function setCoinageContract(address _coinageContractAddress){
        if (msg.sender == owner || msg.sender == dev){
            coinageContract = XaurumCoinageContract(_coinageContractAddress);
        }
    }

    XaurmProxyContract public proxyContract;
    function setProxyContract(address _proxyContractAddress){
        if (msg.sender == owner || msg.sender == dev){
            proxyContract = XaurmProxyContract(_proxyContractAddress);
        }
    }

    XaurumAlliesContract public alliesContract;
    function setAlliesContract(address _alliesContractAddress){
        if (msg.sender == owner || msg.sender == dev){
            alliesContract = XaurumAlliesContract(_alliesContractAddress);
        }
    }
    
    
    

     
    address public owner;
    function setOwner(address _newOwnerAdress) returns (bool){
        if ( msg.sender == dev ){        
            owner = _newOwnerAdress;
            return true;
        }
        return false;
    }

    address public dev;

     
    address xaurForGasCurrator;
    function setXauForGasCurrator(address _curratorAddress){
        if (msg.sender == owner || msg.sender == dev){
            xaurForGasCurrator = _curratorAddress;
        }
    }

     
    address public burningAdress;

     
    function XaurumToken(address _burningAddress) { 
        burningAdress = _burningAddress;
        lockdown = false;
        dev = msg.sender;
       
        
         
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] += 5999319593600000;
         totalSupply += 5999319593600000;
         totalGoldSupply += 1696620000000;
         Coinage(numberOfCoinages, 0, 5999319593600000, 1696620000000, totalGoldSupply, totalSupply);      
		

         
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] += 1588947591000000;
         totalSupply += 1588947591000000;
         totalGoldSupply += 1106042126000;
         Coinage(numberOfCoinages, 60611110000000, 1588947591000000, 1106042126000, totalGoldSupply, totalSupply);
        		
		
         
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] += 151127191000000;
         totalSupply += 151127191000000;
         totalGoldSupply += 110134338200;
         Coinage(numberOfCoinages, 6035361000000, 151127191000000, 110134338200, totalGoldSupply, totalSupply);
        
		
		    
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] += 63789854418800;
         totalSupply += 63789854418800;
         totalGoldSupply +=  46701000000;
         Coinage(numberOfCoinages, 2559215000000, 63789854418800, 46701000000, totalGoldSupply, totalSupply);
        

		    
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] +=  393015011191000;
         totalSupply += 393015011191000;
         totalGoldSupply +=  290692000000;
         Coinage(numberOfCoinages, 15929931000000, 393015011191000, 290692000000, totalGoldSupply, totalSupply);
        

		    
         numberOfCoinages += 1;
         balances[0x097B7b672fe0dc3eF61f53B954B3DCC86382e7B9] +=  49394793870000;
         totalSupply += 49394793870000;
         totalGoldSupply +=  36891368614;
         Coinage(numberOfCoinages, 2021647000000, 49394793870000, 36891368614, totalGoldSupply, totalSupply);
    }
    
    function freezeCoin(){
        if (msg.sender == owner || msg.sender == dev){
            lockdown = !lockdown;
        }
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) returns (bool status) {
        uint256 goldFee = dataContract.goldFee();

        if (balances[msg.sender] >= _amount &&                                   
            balances[_to] + _amount > balances[_to] &&                           
            _amount > goldFee &&                                                 
            !lockdown &&                                                         
            lockedAccounts[msg.sender] <= block.number) {                        
            balances[msg.sender] -= _amount;                                     
            balances[_to] += (_amount - goldFee );                               
            Transfer(msg.sender, _to, (_amount - goldFee ));                     
            doBurn(msg.sender, goldFee, BurningType.TxtFee);                     
            return true;
        } else {
            return false;
        }
    }
    
     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool status) {
        uint256 goldFee = dataContract.goldFee();

        if (balances[_from] >= _amount &&                                   
            balances[_to] + _amount > balances[_to] &&                           
            _amount > goldFee &&                                                 
            !lockdown &&                                                         
            lockedAccounts[_from] <= block.number) {                        
            if (_amount > allowed[_from][msg.sender]){                           
                return false;
            }
            balances[_from] -= _amount;                                     
            balances[_to] += (_amount - goldFee);                                
            Transfer(_from, _to, (_amount - goldFee));                      
            doBurn(_from, goldFee, BurningType.TxtFee);                    
            allowed[_from][msg.sender] -= _amount;                               
            return true;
        } else {
            return false;
        }
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

     function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    function transferViaProxy(address _source, address _to, uint256 _amount) returns (bool status, address sendFrom, address sentTo, uint256 sentToAmount, address burnAddress, uint256 burnAmount){
        if (!proxyContract.isProxyLegit(msg.sender)){                                         
            return (false, 0, 0, 0, 0, 0);
        }

        uint256 goldFee = dataContract.goldFee();

        if (balances[_source] >= _amount &&                                      
            balances[_to] + _amount > balances[_to] &&                           
            _amount > goldFee &&                                                 
            !lockdown &&                                                         
            lockedAccounts[_source] <= block.number) {                           
            
            balances[_source] -= _amount;                                        
            balances[_to] += (_amount - goldFee );                               
            Transfer(_source, _to, ( _amount - goldFee ));                     
            doBurn(_source, goldFee, BurningType.TxtFee);                          
        
            return (true, _source, _to, (_amount - goldFee), burningAdress, goldFee);
        } else {
            return (false, 0, 0, 0, 0, 0);
        }
    }
    
     
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (bool status, address sendFrom, address sentTo, uint256 sentToAmount, address burnAddress, uint256 burnAmount) {
        if (!proxyContract.isProxyLegit(msg.sender)){                                             
            return (false, 0, 0, 0, 0, 0);
        }

        uint256 goldFee = dataContract.goldFee();

        if (balances[_from] >= _amount &&                                        
            balances[_to] + _amount > balances[_to] &&                           
            _amount > goldFee &&                                                 
            !lockdown &&                                                         
            lockedAccounts[_from] <= block.number) {                             

            if (_amount > allowed[_from][_source]){                              
                return (false, 0, 0, 0, 0, 0); 
            }               

            balances[_from] -= _amount;                                          
            balances[_to] += ( _amount - goldFee );                              
            Transfer(_from, _to, ( _amount - goldFee ));                         
            doBurn(_from, goldFee, BurningType.TxtFee);
            allowed[_from][_source] -= _amount;                                  
            return (true, _from, _to, (_amount - goldFee), burningAdress, goldFee);
        } else {
            return (false, 0, 0, 0, 0, 0);
        }
    }
    
     function approveFromProxy(address _source, address _spender, uint256 _value) returns (bool success) {
        if (!proxyContract.isProxyLegit(msg.sender)){                                         
            return false;
        }
        allowed[_source][_spender] = _value;
        Approval(_source, _spender, _value);
        return true;
    }

    function allowanceFromProxy(address _source, address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     
    
     
    function lockAccount(uint _block) returns (bool answer){
        if (lockedAccounts[msg.sender] < block.number + _block){
            lockedAccounts[msg.sender] = block.number + _block;
            return true;
        }
        return false;
    }

    function isAccountLocked(address _accountAddress) returns (bool){
        if (lockedAccounts[_accountAddress] > block.number){
            return true;
        }
        return false;
    }
    
     
     
     

     
    function getGasForXau(address _to) returns (bool sucess){
        uint256 xaurForGasLimit = dataContract.xaurForGasLimit();
        uint256 weiForXau = dataContract.weiForXau();

        if (balances[msg.sender] > xaurForGasLimit && 
            balances[xaurForGasCurrator] < balances[xaurForGasCurrator]  + xaurForGasLimit &&
            this.balance > dataContract.weiForXau()) {
            if (_to.send(dataContract.weiForXau())){
                balances[msg.sender] -= xaurForGasLimit;
                balances[xaurForGasCurrator] += xaurForGasLimit;
                return true;
            }
        } 
        return false;
    }
    
     
    function fillGas(){
        if (msg.sender != xaurForGasCurrator) { 
            throw; 
        }
    }

     
     
     

    function doMelt(uint256 _xaurAmount, uint256 _goldAmount) returns (bool){
        if (msg.sender == address(meltingContract)){
            totalSupply -= _xaurAmount;
            totalGoldSupply -= _goldAmount;
            Melt(_xaurAmount, _goldAmount);
            return true;
        }
        return false;
    }
    
     
     
     

    

     
     
     
    function doCoinage(address[] _coinageAddresses, uint256[] _coinageAmounts, uint256 _usdAmount, uint256 _xaurCoined, uint256 _goldBought) returns (bool){
        if (msg.sender == address(coinageContract) && 
            _coinageAddresses.length == _coinageAmounts.length){
            
            totalSupply += _xaurCoined;
            totalGoldSupply += _goldBought;
            numberOfCoinages += 1;
            Coinage(numberOfCoinages, _usdAmount, _xaurCoined, _goldBought, totalGoldSupply, totalSupply);
            for (uint256 cnt = 0; cnt < _coinageAddresses.length; cnt++){
                balances[_coinageAddresses[cnt]] += _coinageAmounts[cnt]; 
            }
            return true;
        }
        return false;
    }

     
     
     
    function doBurn(address _from, uint256 _amountToBurn, BurningType _burningType) internal {
        balances[burningAdress] += _amountToBurn;                               
        totalSupply -= _amountToBurn;                                           
        Burn(_from, _amountToBurn, _burningType);                               
    }

    function doBurnFromContract(address _from, uint256 _amount) returns (bool){
        if (msg.sender == address(alliesContract)){
            balances[_from] -= _amount;
            doBurn(_from, _amount, BurningType.AllyDonation);
            return true;
        }
        else if(msg.sender == address(coinageContract)){
            balances[_from] -= _amount;
            doBurn(_from, _amount, BurningType.ServiceFee);
            return true;
        }
        else{
            return false;
        }

    }

     
    function () {
        throw;      
    }
}

contract XaurumMeltingContract {}

contract XaurumAlliesContract {}

contract XaurumCoinageContract {}

contract XaurmProxyContract{

    address public owner;
    address public curator;
    address public dev;

    function XaurmProxyContract(){
        dev = msg.sender;
    }

    function setProxyCurrator(address _newCurratorAdress) returns (bool){
        if (msg.sender == owner || msg.sender == dev){        
            curator = _newCurratorAdress;
            return true;
        }
        return false;
    }

    function setOwner(address _newOwnerAdress) returns (bool){
        if ( msg.sender == dev ){        
            owner = _newOwnerAdress;
            return true;
        }
        return false;
    }

     
    
    address[] approvedProxys; 
    mapping (address => bool) proxyList;
    
     
    function addNewProxy(address _proxyAdress){
        if(msg.sender == curator){
            proxyList[_proxyAdress] = true;
            approvedProxys.push(_proxyAdress);
        }
    }

    function isProxyLegit(address _proxyAddress) returns (bool){
        return proxyList[_proxyAddress];
    }
    
    function getApprovedProxys() returns (address[] proxys){
        return approvedProxys;
    }

    function () {
        throw;
    }
}

contract XaurumDataContract {

     
    uint256 public xauToEur;
    uint256 public goldToEur;
    uint256 public mintingDataUpdatedAtBlock;

     
    uint256 public xaurForGasLimit;
    uint256 public weiForXau;
    uint256 public gasForXaurDataUpdateAtBlock;

     
    uint256 public goldFee;
    uint256 public goldFeeDataUpdatedAtBlock;

    address public owner;
    address public curator;
    address public dev;

    function XaurumDataContract(){
        xaurForGasLimit = 100000000;
        weiForXau = 100000000000000000;
        goldFee = 50000000;
        
	   dev = msg.sender;
    }

    function setProxyCurrator(address _newCurratorAdress) returns (bool){
        if (msg.sender == owner || msg.sender == dev){        
            curator = _newCurratorAdress;
            return true;
        }
        return false;
    }

    function setOwner(address _newOwnerAdress) returns (bool){
        if ( msg.sender == dev ){        
            owner = _newOwnerAdress;
            return true;
        }
        return false;
    }

    function updateMintingData(uint256 _xauToEur, uint256 _goldToEur) returns (bool status){
        if (msg.sender == curator || msg.sender == dev){
            xauToEur = _xauToEur;
            goldToEur = _goldToEur;
            mintingDataUpdatedAtBlock = block.number;
            return true;
        }
        return false;
    }

    function updateGasForXaurData(uint256 _xaurForGasLimit, uint256 _weiForXau) returns (bool status){
        if (msg.sender == curator || msg.sender == dev){
            xaurForGasLimit = _xaurForGasLimit;
            weiForXau = _weiForXau;
            gasForXaurDataUpdateAtBlock = block.number;
            return true;
        }
        return false;
    }

    function updateGoldFeeData(uint256 _goldFee) returns (bool status){
        if (msg.sender == curator || msg.sender == dev){
            goldFee = _goldFee;
            goldFeeDataUpdatedAtBlock = block.number;
            return true;
        }
        return false;
    }

    function () {
        throw;
    }
}