 

pragma solidity ^0.4.15;

contract Token {

     
     
     
     
    uint public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint);

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint _value) public returns (bool success) {
        if (balances[msg.sender] >= _value &&           
            balances[_to] + _value >= balances[_to]) {  
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { throw; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (balances[_from] >= _value &&                 
            allowed[_from][msg.sender] >= _value &&      
            balances[_to] + _value >= balances[_to]) {   
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else { throw; }
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
}

 

contract SnipCoin is StandardToken {

    string public constant name = "SnipCoin";          
    string public symbol = "SNIP";                     
    uint8 public constant decimals = 18;               
    uint public totalEthReceivedInWei;                 
    uint public totalUsdReceived;                      
    uint public totalUsdValueOfAllTokens;              
    string public version = "1.0";                     
    address public saleWalletAddress;                  

    mapping (address => bool) public uncappedBuyerList;       
    mapping (address => uint) public cappedBuyerList;         

    uint public snipCoinToEtherExchangeRate = 76250;  
    bool public isSaleOpen = false;                    
    bool public transferable = false;                  

    uint public ethToUsdExchangeRate = 282;            

    address public contractOwner;                      
     
    address public accountWithUpdatePermissions = 0x6933784a82F5daDEbB600Bed8670667837aD196f;

    uint public constant PERCENTAGE_OF_TOKENS_SOLD_IN_SALE = 28;      
    uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);    
    uint public constant SALE_CAP_IN_USD = 8000000;                   
    uint public constant MINIMUM_PURCHASE_IN_USD = 50;                
    uint public constant USD_PURCHASE_AMOUNT_REQUIRING_ID = 4500;     

    modifier onlyPermissioned() {
        require((msg.sender == contractOwner) || (msg.sender == accountWithUpdatePermissions));
        _;
    }

    modifier verifySaleNotOver() {
        require(isSaleOpen);
        require(totalUsdReceived < SALE_CAP_IN_USD);  
        _;
    }

    modifier verifyBuyerCanMakePurchase() {
        uint currentPurchaseValueInUSD = uint(msg.value / getWeiToUsdExchangeRate());  
        uint totalPurchaseIncludingCurrentPayment = currentPurchaseValueInUSD +  cappedBuyerList[msg.sender];  

        require(currentPurchaseValueInUSD > MINIMUM_PURCHASE_IN_USD);  

        uint EFFECTIVE_MAX_CAP = SALE_CAP_IN_USD + 1000;   
        require(EFFECTIVE_MAX_CAP - totalUsdReceived > currentPurchaseValueInUSD);  

        if (!uncappedBuyerList[msg.sender])  
        {
            require(cappedBuyerList[msg.sender] > 0);  
            require(totalPurchaseIncludingCurrentPayment < USD_PURCHASE_AMOUNT_REQUIRING_ID);  
        }
        _;
    }

    function SnipCoin() public {
        initializeSaleWalletAddress();
        initializeEthReceived();
        initializeUsdReceived();

        contractOwner = msg.sender;                       
        totalSupply = 10000000000 * DECIMALS_MULTIPLIER;  
        balances[contractOwner] = totalSupply;            
        Transfer(0x0, contractOwner, totalSupply);
    }

    function initializeSaleWalletAddress() internal {
        saleWalletAddress = 0xb4Ad56E564aAb5409fe8e34637c33A6d3F2a0038;  
    }

    function initializeEthReceived() internal {
        totalEthReceivedInWei = 14018 * 1 ether;  
    }

    function initializeUsdReceived() internal {
        totalUsdReceived = 3953076;  
        totalUsdValueOfAllTokens = totalUsdReceived * 100 / PERCENTAGE_OF_TOKENS_SOLD_IN_SALE;  
    }

    function getWeiToUsdExchangeRate() public constant returns(uint) {
        return 1 ether / ethToUsdExchangeRate;  
    }

    function updateEthToUsdExchangeRate(uint newEthToUsdExchangeRate) public onlyPermissioned {
        ethToUsdExchangeRate = newEthToUsdExchangeRate;  
    }

    function updateSnipCoinToEtherExchangeRate(uint newSnipCoinToEtherExchangeRate) public onlyPermissioned {
        snipCoinToEtherExchangeRate = newSnipCoinToEtherExchangeRate;  
    }

    function openOrCloseSale(bool saleCondition) public onlyPermissioned {
        require(!transferable);
        isSaleOpen = saleCondition;  
    }

    function allowTransfers() public onlyPermissioned {
        require(!isSaleOpen);
        transferable = true;
    }

    function addAddressToCappedAddresses(address addr) public onlyPermissioned {
        cappedBuyerList[addr] = 1;  
    }

    function addMultipleAddressesToCappedAddresses(address[] addrList) public onlyPermissioned {
        for (uint i = 0; i < addrList.length; i++) {
            addAddressToCappedAddresses(addrList[i]);  
        }
    }

    function addAddressToUncappedAddresses(address addr) public onlyPermissioned {
        uncappedBuyerList[addr] = true;  
    }

    function addMultipleAddressesToUncappedAddresses(address[] addrList) public onlyPermissioned {
        for (uint i = 0; i < addrList.length; i++) {
            addAddressToUncappedAddresses(addrList[i]);  
        }
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(transferable);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(transferable);
        return super.transferFrom(_from, _to, _value);
    }

    function () public payable verifySaleNotOver verifyBuyerCanMakePurchase {
        uint tokens = snipCoinToEtherExchangeRate * msg.value;
        balances[contractOwner] -= tokens;
        balances[msg.sender] += tokens;
        Transfer(contractOwner, msg.sender, tokens);

        totalEthReceivedInWei = totalEthReceivedInWei + msg.value;  
        uint usdReceivedInCurrentTransaction = uint(msg.value / getWeiToUsdExchangeRate());
        totalUsdReceived = totalUsdReceived + usdReceivedInCurrentTransaction;  
        totalUsdValueOfAllTokens = totalUsdReceived * 100 / PERCENTAGE_OF_TOKENS_SOLD_IN_SALE;  

        if (cappedBuyerList[msg.sender] > 0)
        {
            cappedBuyerList[msg.sender] = cappedBuyerList[msg.sender] + usdReceivedInCurrentTransaction;
        }

        saleWalletAddress.transfer(msg.value);  
    }
}