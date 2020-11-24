 

pragma solidity ^ 0.4.17;


library SafeMath {
    function mul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
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

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }

    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }

     
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

     
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value) public;
}


 
contract WhiteList is Ownable {

    function isWhiteListed(address _user) external view returns (bool);        
}

 
contract Vesting is Ownable {

    using SafeMath for uint;

    uint public teamTokensInitial = 2e25;       
    uint public teamTokensCurrent = 0;          
    uint public companyTokensInitial = 15e24;   
    uint public companyTokensCurrent = 0;       
    Token public token;                         
    uint public dateICOEnded;                   
    uint public dateProductCompleted;           


    event LogTeamTokensTransferred(address indexed receipient, uint amouontOfTokens);
    event LogCompanyTokensTransferred(address indexed receipient, uint amouontOfTokens);


     
     
     
    function setToken(Token _token) public onlyOwner() returns(bool) {
        require (token == address(0));  
        token = _token;
        return true;
    }

     
    function setProductCompletionDate() external onlyOwner() {
        dateProductCompleted = now;
    }

     
     
     
    function transferTeamTokens(address _recipient, uint _tokensToTransfer) external onlyOwner() {

        require(_recipient != 0);       
        require(now >= 1533081600);   

        require(dateProductCompleted > 0);
        if (now < dateProductCompleted + 1 years)             
            require(teamTokensCurrent.add(_tokensToTransfer) <= (teamTokensInitial * 30) / 100);
        else if (now < dateProductCompleted + 2 years)        
            require(teamTokensCurrent.add(_tokensToTransfer) <= (teamTokensInitial * 60) / 100);
        else if (now < dateProductCompleted + 3 years)        
            require(teamTokensCurrent.add(_tokensToTransfer) <= (teamTokensInitial * 80) / 100);
        else                                                  
            require(teamTokensCurrent.add(_tokensToTransfer) <= teamTokensInitial);

        teamTokensCurrent = teamTokensCurrent.add(_tokensToTransfer);   
        
        if (!token.transfer(_recipient, _tokensToTransfer))
                revert();

        LogTeamTokensTransferred(_recipient, _tokensToTransfer);
    }

     
     
     
    function transferCompanyTokens(address _recipient, uint _tokensToTransfer) external onlyOwner() {

        require(_recipient != 0);
        require(dateICOEnded > 0);       

        if (now < dateICOEnded + 1 years)    
            require(companyTokensCurrent.add(_tokensToTransfer) <= (companyTokensInitial * 50) / 100);
        else if (now < dateICOEnded + 2 years)  
            require(companyTokensCurrent.add(_tokensToTransfer) <= (companyTokensInitial * 75) / 100);
        else                                     
            require(companyTokensCurrent.add(_tokensToTransfer) <= companyTokensInitial);

        companyTokensCurrent = companyTokensCurrent.add(_tokensToTransfer);   

        if (!token.transfer(_recipient, _tokensToTransfer))
                revert();
        LogCompanyTokensTransferred(_recipient, _tokensToTransfer);
    }
}

 
 
contract CrowdSale is  Pausable, Vesting {

    using SafeMath for uint;

    struct Backer {
        uint weiReceivedOne;  
        uint weiReceivedTwo;   
        uint weiReceivedMain;  
        uint tokensSent;  
        bool claimed;
        bool refunded;
    }

    address public multisig;  
    uint public ethReceivedPresaleOne;  
    uint public ethReceivedPresaleTwo;  
    uint public ethReceiveMainSale;  
    uint public totalTokensSold;  
    uint public startBlock;  
    uint public endBlock;  

    uint public minInvestment;  
    WhiteList public whiteList;  
    uint public dollarPerEtherRatio;  
    uint public returnPercentage;   
    Step public currentStep;   
    uint public minCapTokens;   

    mapping(address => Backer) public backers;  
    address[] public backersIndex;   
    uint public maxCapEth;   
    uint public maxCapTokens;  
    uint public claimCount;   
    uint public refundCount;   
    uint public totalClaimed;   
    uint public totalRefunded;   
    mapping(address => uint) public claimed;  
    mapping(address => uint) public refunded;  



     
    enum Step {
        FundingPresaleOne,   
        FundingPresaleTwo,   
        FundingMainSale,     
        Refunding            
    }


     
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock))
            revert();
        _;
    }

     
    event ReceivedETH(address indexed backer, Step indexed step, uint amount);
    event TokensClaimed(address indexed backer, uint count);
    event Refunded(address indexed backer, uint amount);



     
     
    function CrowdSale(WhiteList _whiteList, address _multisig) public {

        require(_whiteList != address(0x0));
        multisig = _multisig;
        minInvestment = 10 ether;
        maxCapEth = 9000 ether;
        startBlock = 0;  
        endBlock = 0;  
        currentStep = Step.FundingPresaleOne;   
        whiteList = _whiteList;  
        minCapTokens = 6.5e24;   
    }


     
     
    function numberOfBackers() public view returns(uint, uint, uint, uint) {

        uint numOfBackersOne;
        uint numOfBackersTwo;
        uint numOfBackersMain;

        for (uint i = 0; i < backersIndex.length; i++) {
            Backer storage backer = backers[backersIndex[i]];
            if (backer.weiReceivedOne > 0)
                numOfBackersOne ++;
            if (backer.weiReceivedTwo > 0)
                numOfBackersTwo ++;
            if (backer.weiReceivedMain > 0)
                numOfBackersMain ++;
            }
        return ( numOfBackersOne, numOfBackersTwo, numOfBackersMain, backersIndex.length);
    }



     
     
    function setPresaleTwo() public onlyOwner() {
        currentStep = Step.FundingPresaleTwo;
        maxCapEth = 60000 ether;
        minInvestment = 5 ether;
    }

     
     
     
    function setMainSale(uint _ratio) public onlyOwner() {

        require(_ratio > 0);
        currentStep = Step.FundingMainSale;
        dollarPerEtherRatio = _ratio;
        maxCapTokens = 65e24;
        minInvestment = 1 ether / 5;   
        totalTokensSold = (dollarPerEtherRatio * ethReceivedPresaleOne) / 48;   
        totalTokensSold += (dollarPerEtherRatio * ethReceivedPresaleTwo) / 58;   
    }


     
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint,  bool) {

        return (startBlock, endBlock, backersIndex.length, ethReceivedPresaleOne, ethReceivedPresaleTwo, ethReceiveMainSale, maxCapTokens,   minInvestment,  stopped);
    }


     
     
    function () public payable {
        contribute(msg.sender);
    }

     
     
    function fundContract(uint _returnPercentage) external payable onlyOwner() {

        require(_returnPercentage > 0);
        require(msg.value == (ethReceivedPresaleOne.mul(_returnPercentage) / 100) + ethReceivedPresaleTwo + ethReceiveMainSale);
        returnPercentage = _returnPercentage;
        currentStep = Step.Refunding;
    }

     
     
    function start() external onlyOwner() {
        startBlock = block.number;
        endBlock = startBlock + 383904;  
    }

     
     
     
     
    function adjustDuration(uint _block) external onlyOwner() {

        require(_block <= 433440);   
        require(_block > block.number.sub(startBlock));  
        endBlock = startBlock.add(_block);
    }


     
     
     

    function contribute(address _contributor) internal stopInEmergency respectTimeFrame returns(bool res) {


        require(whiteList.isWhiteListed(_contributor));   
        Backer storage backer = backers[_contributor];
        require (msg.value >= minInvestment);   

        if (backer.weiReceivedOne == 0 && backer.weiReceivedTwo == 0 && backer.weiReceivedMain == 0)
            backersIndex.push(_contributor);

        if (currentStep == Step.FundingPresaleOne) {          
            backer.weiReceivedOne = backer.weiReceivedOne.add(msg.value);
            ethReceivedPresaleOne = ethReceivedPresaleOne.add(msg.value);  
            require(ethReceivedPresaleOne <= maxCapEth);   
        }else if (currentStep == Step.FundingPresaleTwo) {           
            backer.weiReceivedTwo = backer.weiReceivedTwo.add(msg.value);
            ethReceivedPresaleTwo = ethReceivedPresaleTwo.add(msg.value);   
            require(ethReceivedPresaleOne + ethReceivedPresaleTwo <= maxCapEth);   
        }else if (currentStep == Step.FundingMainSale) {
            backer.weiReceivedMain = backer.weiReceivedMain.add(msg.value);
            ethReceiveMainSale = ethReceiveMainSale.add(msg.value);   
            uint tokensToSend = dollarPerEtherRatio.mul(msg.value) / 62;   
            totalTokensSold += tokensToSend;
            require(totalTokensSold <= maxCapTokens);   
        }
        multisig.transfer(msg.value);   

        ReceivedETH(_contributor, currentStep, msg.value);  
        return true;
    }


     
     

    function finalizeSale() external onlyOwner() {
        require(dateICOEnded == 0);
        require(currentStep == Step.FundingMainSale);
         
         
        require(block.number >= endBlock || totalTokensSold >= maxCapTokens.sub(1000));
        require(totalTokensSold >= minCapTokens);
        
        companyTokensInitial += maxCapTokens - totalTokensSold;  
        dateICOEnded = now;
        token.unlock();
    }


     
     
     
    function updateContributorAddress(address _contributorOld, address _contributorNew) public onlyOwner() {

        Backer storage backerOld = backers[_contributorOld];
        Backer storage backerNew = backers[_contributorNew];

        require(backerOld.weiReceivedOne > 0 || backerOld.weiReceivedTwo > 0 || backerOld.weiReceivedMain > 0);  
        require(backerNew.weiReceivedOne == 0 && backerNew.weiReceivedTwo == 0 && backerNew.weiReceivedMain == 0);  
        require(backerOld.claimed == false && backerOld.refunded == false);   

         
        backerOld.claimed = true;
        backerOld.refunded = true;

         
        backerNew.weiReceivedOne = backerOld.weiReceivedOne;
        backerNew.weiReceivedTwo = backerOld.weiReceivedTwo;
        backerNew.weiReceivedMain = backerOld.weiReceivedMain;
        backersIndex.push(_contributorNew);
    }

     
     
     
    function claimTokensForUser(address _backer) internal returns(bool) {        

        require(dateICOEnded > 0);  

        Backer storage backer = backers[_backer];

        require (!backer.refunded);  
        require (!backer.claimed);  
        require (backer.weiReceivedOne > 0 || backer.weiReceivedTwo > 0 || backer.weiReceivedMain > 0);    

        claimCount++;
        uint tokensToSend = (dollarPerEtherRatio * backer.weiReceivedOne) / 48;   
        tokensToSend = tokensToSend + (dollarPerEtherRatio * backer.weiReceivedTwo) / 58;   
        tokensToSend = tokensToSend + (dollarPerEtherRatio * backer.weiReceivedMain) / 62;   

        claimed[_backer] = tokensToSend;   
        backer.claimed = true;
        backer.tokensSent = tokensToSend;
        totalClaimed += tokensToSend;

        if (!token.transfer(_backer, tokensToSend))
            revert();  

        TokensClaimed(_backer,tokensToSend);
        return true;
    }


     
     

    function claimTokens() external {
        claimTokensForUser(msg.sender);
    }


     
     
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        claimTokensForUser(_backer);
    }

     
     
     

    function refund() external {

        require(currentStep == Step.Refunding);                                                          
        require(totalTokensSold < maxCapTokens/2);  

        Backer storage backer = backers[msg.sender];

        require (!backer.claimed);  
        require (!backer.refunded);  

        uint totalEtherReceived = ((backer.weiReceivedOne * returnPercentage) / 100) + backer.weiReceivedTwo + backer.weiReceivedMain;   
        assert(totalEtherReceived > 0);

        backer.refunded = true;  
        totalRefunded += totalEtherReceived;
        refundCount ++;
        refunded[msg.sender] = totalRefunded;

        msg.sender.transfer(totalEtherReceived);   
        Refunded(msg.sender, totalEtherReceived);  
    }



     
     
    function refundNonCompliant(address _contributor) payable external onlyOwner() {
    
        Backer storage backer = backers[_contributor];

        require (!backer.claimed);  
        require (!backer.refunded);  
        backer.refunded = true;  

        uint totalEtherReceived = backer.weiReceivedOne + backer.weiReceivedTwo + backer.weiReceivedMain;

        require(msg.value == totalEtherReceived);  
        assert(totalEtherReceived > 0);

         
        ethReceivedPresaleOne -= backer.weiReceivedOne;
        ethReceivedPresaleTwo -= backer.weiReceivedTwo;
        ethReceiveMainSale -= backer.weiReceivedMain;
        
        totalRefunded += totalEtherReceived;
        refundCount ++;
        refunded[_contributor] = totalRefunded;      

        uint tokensToSend = (dollarPerEtherRatio * backer.weiReceivedOne) / 48;   
        tokensToSend = tokensToSend + (dollarPerEtherRatio * backer.weiReceivedTwo) / 58;   
        tokensToSend = tokensToSend + (dollarPerEtherRatio * backer.weiReceivedMain) / 62;   

        if(dateICOEnded == 0) {
            totalTokensSold -= tokensToSend;
        } else {
            companyTokensInitial += tokensToSend;
        }

        _contributor.transfer(totalEtherReceived);   
        Refunded(_contributor, totalEtherReceived);  
    }

     
    function drain() external onlyOwner() {
        multisig.transfer(this.balance);

    }

     
    function tokenDrain() external onlyOwner() {
    if (block.number > endBlock) {
        if (!token.transfer(multisig, token.balanceOf(this)))
                revert();
        }
    }
}





 
contract Token is ERC20,  Ownable {

    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint8 public decimals;  
    string public version = "v0.1";
    uint public totalSupply;
    uint public initialSupply;
    bool public locked;
    address public crowdSaleAddress;
    address public migrationMaster;
    address public migrationAgent;
    uint256 public totalMigrated;
    address public authorized;


    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

     
    modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked)
            revert();
        _;
    }


     
    modifier onlyAuthorized() {
        if (msg.sender != owner && msg.sender != authorized )
            revert();
        _;
    }


     
     
     
    function Token(address _crowdSaleAddress) public {

        require(_crowdSaleAddress != 0);

        locked = true;   
        initialSupply = 1e26;
        totalSupply = initialSupply;
        name = "Narrative";  
        symbol = "NRV";  
        decimals = 18;  
        crowdSaleAddress = _crowdSaleAddress;
        balances[crowdSaleAddress] = initialSupply;
        migrationMaster = owner;
        authorized = _crowdSaleAddress;
    }

     
    function unlock() public onlyAuthorized {
        locked = false;
    }

     
    function lock() public onlyAuthorized {
        locked = true;
    }

     
     
    function setAuthorized(address _authorized) public onlyOwner {

        authorized = _authorized;
    }


     
    event Migrate(address indexed _from, address indexed _to, uint256 _value);

     
     
     
    function migrate(uint256 _value)  external {
         

        require (migrationAgent != 0);
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalMigrated = totalMigrated.add(_value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

     
     
     
     
     
    function setMigrationAgent(address _agent)  external {
         

        require(migrationAgent == 0);
        require(msg.sender == migrationMaster);
        migrationAgent = _agent;
    }

    function setMigrationMaster(address _master) external {
        require(msg.sender == migrationMaster);
        require(_master != 0);
        migrationMaster = _master;
    }

     
     
     
     
    function mint(address _target, uint256 _mintedAmount) public onlyAuthorized() returns(bool) {
        assert(totalSupply.add(_mintedAmount) <= 1975e23);   
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        Transfer(0, _target, _mintedAmount);
        return true;
    }

     
     
     
     
    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {

        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {

        require(_to != address(0));
        require(balances[_from] >= _value);  
        require(_value <= allowed[_from][msg.sender]);  
        balances[_from] -= _value;  
        balances[_to] += _value;  
        allowed[_from][msg.sender] -= _value;   
        Transfer(_from, _to, _value);
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }


     
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
     
     
     
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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