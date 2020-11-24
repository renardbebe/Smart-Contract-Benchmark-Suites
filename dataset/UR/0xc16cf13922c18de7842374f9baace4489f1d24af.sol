 

pragma solidity ^0.4.15;


 


 

 
 
 
 
contract allowanceRecipient {
    function receiveApproval(address _from, uint256 _value, address _inContract, bytes _extraData) returns (bool success);
}


 
 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes _extraData) returns (bool success);
}


contract DEEX {

     

     

     

     
     
    string public name = "deex";

     
     
    string public symbol = "deex";

     
     
    uint8 public decimals = 0;

     
     
     
    uint256 public totalSupply;

     
     
    mapping (address => uint256) public balanceOf;

     
     
    mapping (address => mapping (address => uint256)) public allowance;

     

    uint256 public salesCounter = 0;

    uint256 public maxSalesAllowed;

    bool private transfersBetweenSalesAllowed;

     
    uint256 public tokenPriceInWei = 0;

    uint256 public saleStartUnixTime = 0;  
    uint256 public saleEndUnixTime = 0;   

     
    address public owner;

     
    address public priceSetter;

     
    uint256 private priceMaxWei = 0;
     
    uint256 private priceMinWei = 0;

     
    mapping (address => bool) public isPreferredTokensAccount;

    bool public contractInitialized = false;


     
     
     
    function DEEX() {
        owner = msg.sender;

         
         
        maxSalesAllowed = 2;
         
        transfersBetweenSalesAllowed = true;
    }


    function initContract(address team, address advisers, address bounty) public onlyBy(owner) returns (bool){

        require(contractInitialized == false);
        contractInitialized = true;

        priceSetter = msg.sender;

        totalSupply = 100000000;

         
        balanceOf[this] = 75000000;

         
        balanceOf[team] = balanceOf[team] + 15000000;
        isPreferredTokensAccount[team] = true;

         
        balanceOf[advisers] = balanceOf[advisers] + 7000000;
        isPreferredTokensAccount[advisers] = true;

         
        balanceOf[bounty] = balanceOf[bounty] + 3000000;
        isPreferredTokensAccount[bounty] = true;

    }

     

     
     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed spender, uint256 value);

     
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

     

    event PriceChanged(uint256 indexed newTokenPriceInWei);

    event SaleStarted(uint256 startUnixTime, uint256 endUnixTime, uint256 indexed saleNumber);

    event NewTokensSold(uint256 numberOfTokens, address indexed purchasedBy, uint256 indexed priceInWei);

    event Withdrawal(address indexed to, uint sumInWei);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

     

     
    modifier onlyBy(address _account){
        require(msg.sender == _account);

        _;
    }

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
         

        bool saleFinished = saleIsFinished();
        require(saleFinished || msg.sender == owner || isPreferredTokensAccount[msg.sender]);

         
         
        require(transfersBetweenSalesAllowed || salesCounter == maxSalesAllowed || msg.sender == owner || isPreferredTokensAccount[msg.sender]);

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender]);

         
        require(_value <= balanceOf[_from]);

         
        balanceOf[_from] = balanceOf[_from] - _value;
         
         
        balanceOf[_to] = balanceOf[_to] + _value;

         
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        }

         
        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success){

        require(_value >= 0);

        allowance[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);

        return true;
    }

     

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        approve(_spender, _value);

         
        allowanceRecipient spender = allowanceRecipient(_spender);

         
         
         
        if (spender.receiveApproval(msg.sender, _value, this, _extraData)) {
            DataSentToAnotherContract(msg.sender, _spender, _extraData);
            return true;
        }
        else return false;
    }

    function approveAllAndCall(address _spender, bytes _extraData) public returns (bool success) {
        return approveAndCall(_spender, balanceOf[msg.sender], _extraData);
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _extraData) public returns (bool success){

        transferFrom(msg.sender, _to, _value);

        tokenRecipient receiver = tokenRecipient(_to);

        if (receiver.tokenFallback(msg.sender, _value, _extraData)) {
            DataSentToAnotherContract(msg.sender, _to, _extraData);
            return true;
        }
        else return false;
    }

     
    function transferAllAndCall(address _to, bytes _extraData) public returns (bool success){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     

    function changeOwner(address _newOwner) public onlyBy(owner) returns (bool success){
         
        require(_newOwner != address(0));

        address oldOwner = owner;
        owner = _newOwner;

        OwnerChanged(oldOwner, _newOwner);

        return true;
    }

     

     

    function startSale(uint256 _startUnixTime, uint256 _endUnixTime) public onlyBy(owner) returns (bool success){

        require(balanceOf[this] > 0);
        require(salesCounter < maxSalesAllowed);

         
         
         
        require(
        (saleStartUnixTime == 0 && saleEndUnixTime == 0) || saleIsFinished()
        );
         
        require(_startUnixTime > now && _endUnixTime > now);
         
        require(_endUnixTime - _startUnixTime > 0);

        saleStartUnixTime = _startUnixTime;
        saleEndUnixTime = _endUnixTime;
        salesCounter = salesCounter + 1;

        SaleStarted(_startUnixTime, _endUnixTime, salesCounter);

        return true;
    }

    function saleIsRunning() public constant returns (bool){

        if (balanceOf[this] == 0) {
            return false;
        }

        if (saleStartUnixTime == 0 && saleEndUnixTime == 0) {
            return false;
        }

        if (now > saleStartUnixTime && now < saleEndUnixTime) {
            return true;
        }

        return false;
    }

    function saleIsFinished() public constant returns (bool){

        if (balanceOf[this] == 0) {
            return true;
        }

        else if (
        (saleStartUnixTime > 0 && saleEndUnixTime > 0)
        && now > saleEndUnixTime) {

            return true;
        }

         
        return false;
    }

    function changePriceSetter(address _priceSetter) public onlyBy(owner) returns (bool success) {
        priceSetter = _priceSetter;
        return true;
    }

    function setMinMaxPriceInWei(uint256 _priceMinWei, uint256 _priceMaxWei) public onlyBy(owner) returns (bool success){
        require(_priceMinWei >= 0 && _priceMaxWei >= 0);
        priceMinWei = _priceMinWei;
        priceMaxWei = _priceMaxWei;
        return true;
    }


    function setTokenPriceInWei(uint256 _priceInWei) public onlyBy(priceSetter) returns (bool success){

        require(_priceInWei >= 0);

         
        if (priceMinWei != 0 && _priceInWei < priceMinWei) {
            tokenPriceInWei = priceMinWei;
        }
        else if (priceMaxWei != 0 && _priceInWei > priceMaxWei) {
            tokenPriceInWei = priceMaxWei;
        }
        else {
            tokenPriceInWei = _priceInWei;
        }

        PriceChanged(tokenPriceInWei);

        return true;
    }

     
     
     
     
     
    function() public payable {
        buyTokens();
    }

     
    function buyTokens() public payable returns (bool success){

        if (saleIsRunning() && tokenPriceInWei > 0) {

            uint256 numberOfTokens = msg.value / tokenPriceInWei;

            if (numberOfTokens <= balanceOf[this]) {

                balanceOf[msg.sender] = balanceOf[msg.sender] + numberOfTokens;
                balanceOf[this] = balanceOf[this] - numberOfTokens;

                NewTokensSold(numberOfTokens, msg.sender, tokenPriceInWei);

                return true;
            }
            else {
                 
                revert();
            }
        }
        else {
             
            revert();
        }
    }

     
    function withdrawAllToOwner() public onlyBy(owner) returns (bool) {

         
        require(saleIsFinished());
        uint256 sumInWei = this.balance;

        if (
         
        !msg.sender.send(this.balance)
        ) {
            return false;
        }
        else {
             
            Withdrawal(msg.sender, sumInWei);
            return true;
        }
    }

     

     
     
     
    mapping (bytes32 => bool) private isReferrer;

    uint256 private referralBonus = 0;

    uint256 private referrerBonus = 0;
     
    mapping (bytes32 => uint256) public referrerBalanceOf;

    mapping (bytes32 => uint) public referrerLinkedSales;

    function addReferrer(bytes32 _referrer) public onlyBy(owner) returns (bool success){
        isReferrer[_referrer] = true;
        return true;
    }

    function removeReferrer(bytes32 _referrer) public onlyBy(owner) returns (bool success){
        isReferrer[_referrer] = false;
        return true;
    }

     
    function setReferralBonuses(uint256 _referralBonus, uint256 _referrerBonus) public onlyBy(owner) returns (bool success){
        require(_referralBonus > 0 && _referrerBonus > 0);
        referralBonus = _referralBonus;
        referrerBonus = _referrerBonus;
        return true;
    }

    function buyTokensWithReferrerAddress(address _referrer) public payable returns (bool success){

        bytes32 referrer = keccak256(_referrer);

        if (saleIsRunning() && tokenPriceInWei > 0) {

            if (isReferrer[referrer]) {

                uint256 numberOfTokens = msg.value / tokenPriceInWei;

                if (numberOfTokens <= balanceOf[this]) {

                    referrerLinkedSales[referrer] = referrerLinkedSales[referrer] + numberOfTokens;

                    uint256 referralBonusTokens = (numberOfTokens * (100 + referralBonus) / 100) - numberOfTokens;
                    uint256 referrerBonusTokens = (numberOfTokens * (100 + referrerBonus) / 100) - numberOfTokens;

                    balanceOf[this] = balanceOf[this] - numberOfTokens - referralBonusTokens - referrerBonusTokens;

                    balanceOf[msg.sender] = balanceOf[msg.sender] + (numberOfTokens + referralBonusTokens);

                    referrerBalanceOf[referrer] = referrerBalanceOf[referrer] + referrerBonusTokens;

                    NewTokensSold(numberOfTokens + referralBonusTokens, msg.sender, tokenPriceInWei);

                    return true;
                }
                else {
                     
                    revert();
                }
            }
            else {
                 
                buyTokens();
            }
        }
        else {
             
            revert();
        }
    }

    event ReferrerBonusTokensTaken(address referrer, uint256 bonusTokensValue);

    function getReferrerBonusTokens() public returns (bool success){
        require(saleIsFinished());
        uint256 bonusTokens = referrerBalanceOf[keccak256(msg.sender)];
        balanceOf[msg.sender] = balanceOf[msg.sender] + bonusTokens;
        ReferrerBonusTokensTaken(msg.sender, bonusTokens);
        return true;
    }

}