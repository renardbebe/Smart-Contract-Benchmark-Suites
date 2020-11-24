 

pragma solidity 0.4.24;
 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {    
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract admined {
    mapping(address => uint8) level; 
     
     
     

     
    constructor() internal {
        level[msg.sender] = 2;  
        emit AdminshipUpdated(msg.sender,2);
    }

     
    modifier onlyAdmin(uint8 _level) {  
        require(level[msg.sender] >= _level );
        _;
    }

     
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public {  
        require(_newAdmin != address(0));
        level[_newAdmin] = _level;
        emit AdminshipUpdated(_newAdmin,_level);
    }

     
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract ViVICO is admined {

    using SafeMath for uint256;
     
    enum State {
        PreSale,  
        MainSale,
        OnHold,
        Failed,
        Successful
    }
     

     
    State public state = State.PreSale;  
    uint256 public PreSaleStart = now;  
    uint256 constant public PreSaleDeadline = 1529452799;  
    uint256 public MainSaleStart;  
    uint256 public MainSaleDeadline;  
    uint256 public completedAt;  
     
    uint256 public totalRaised;  
    uint256 public PreSaleDistributed;  
    uint256 public totalDistributed;  
    ERC20Basic public tokenReward;  
    uint256 public softCap = 11000000 * (10 ** 18);  
    uint256 public hardCap = 140000000 * (10 ** 18);  
     
    mapping (address => uint256) public ethOnContract;  
    mapping (address => uint256) public tokensSent;  
    mapping (address => uint256) public balance;  
     
    address public creator;
    string public version = '1';

     
    uint256[5] rates = [2520,2070,1980,1890,1800];

     
    mapping (address => bool) public whiteList;  
    mapping (address => bool) public KYCValid;  

     
    event LogFundrisingInitialized(address _creator);
    event LogMainSaleDateSet(uint256 _time);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogRefund(address _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFundingFailed(uint _totalRaised);

     
    modifier notFinishedOrHold() {
        require(state != State.Successful && state != State.OnHold && state != State.Failed);
        _;
    }

     
    constructor(ERC20Basic _addressOfTokenUsedAsReward ) public {

        creator = msg.sender;  
        tokenReward = _addressOfTokenUsedAsReward;  

        emit LogFundrisingInitialized(creator);
    }

     
    function whitelistAddress(address _user, bool _flag) public onlyAdmin(1) {
        whiteList[_user] = _flag;
    }
    
     
    function validateKYC(address _user, bool _flag) public onlyAdmin(1) {
        KYCValid[_user] = _flag;
    }

     
    function setMainSaleStart(uint256 _startTime) public onlyAdmin(2) {
        require(state == State.OnHold);
        require(_startTime > now);
        MainSaleStart = _startTime;
        MainSaleDeadline = MainSaleStart.add(12 weeks);
        state = State.MainSale;

        emit LogMainSaleDateSet(MainSaleStart);
    }

     
    function contribute() public notFinishedOrHold payable {
        require(whiteList[msg.sender] == true);  
        require(msg.value >= 0.1 ether);  
        
        uint256 tokenBought = 0;  

        totalRaised = totalRaised.add(msg.value);  
        ethOnContract[msg.sender] = ethOnContract[msg.sender].add(msg.value);  

         
        if (state == State.PreSale){
            
            require(now >= PreSaleStart);

            tokenBought = msg.value.mul(rates[0]);
            PreSaleDistributed = PreSaleDistributed.add(tokenBought);  
        
        } else if (state == State.MainSale){

            require(now >= MainSaleStart);

            if (now <= MainSaleStart.add(1 weeks)){
                tokenBought = msg.value.mul(rates[1]);
            } else if (now <= MainSaleStart.add(2 weeks)){
                tokenBought = msg.value.mul(rates[2]);
            } else if (now <= MainSaleStart.add(3 weeks)){
                tokenBought = msg.value.mul(rates[3]);
            } else tokenBought = msg.value.mul(rates[4]);
                
        }

        require(totalDistributed.add(tokenBought) <= hardCap);

        if(KYCValid[msg.sender] == true){
             
            uint256 tempBalance = balance[msg.sender];
             
            balance[msg.sender] = 0;
             
            require(tokenReward.transfer(msg.sender, tokenBought.add(tempBalance)));
             
            tokensSent[msg.sender] = tokensSent[msg.sender].add(tokenBought.add(tempBalance));

            emit LogContributorsPayout(msg.sender, tokenBought.add(tempBalance));

        } else{
             
            balance[msg.sender] = balance[msg.sender].add(tokenBought);

        }

        totalDistributed = totalDistributed.add(tokenBought);  
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

         
        if (totalDistributed == hardCap && state != State.Successful){

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            successful();  

        } else if(state == State.PreSale && now > PreSaleDeadline){

            state = State.OnHold;  

        } else if(state == State.MainSale && now > MainSaleDeadline){
             
            if(totalDistributed >= softCap){
                 
                state = State.Successful;  
                completedAt = now;  

                emit LogFundingSuccessful(totalRaised);  
                successful();  

            } else{
                 
                state = State.Failed;  
                completedAt = now;  

                emit LogFundingFailed(totalRaised);  

            }

        }
    }

     
    function successful() public { 
         
        require(state == State.Successful);
         
        if (now > completedAt.add(14 days)){
             
            uint256 remanent = tokenReward.balanceOf(this);
             
            tokenReward.transfer(creator,remanent);
            emit LogContributorsPayout(creator, remanent);
        }
         
        creator.transfer(address(this).balance);

        emit LogBeneficiaryPaid(creator);

    }

    function claimEth() onlyAdmin(2) public {
         
        require(totalDistributed >= softCap);
         
        creator.transfer(address(this).balance);
        emit LogBeneficiaryPaid(creator);
    }

     
    function claimTokensByUser() public {
         
        require(KYCValid[msg.sender] == true);
         
        uint256 tokens = balance[msg.sender];
         
        balance[msg.sender] = 0;
         
        require(tokenReward.transfer(msg.sender, tokens));
         
        tokensSent[msg.sender] = tokensSent[msg.sender].add(tokens);

        emit LogContributorsPayout(msg.sender, tokens);
    }

     
    function claimTokensByAdmin(address _target) onlyAdmin(1) public {
         
        require(KYCValid[_target] == true);
         
        uint256 tokens = balance[_target];
         
        balance[_target] = 0;
         
        require(tokenReward.transfer(_target, tokens));
         
        tokensSent[_target] = tokensSent[_target].add(tokens);

        emit LogContributorsPayout(_target, tokens);       
    }

     
    function refund() public {  
         
        require(state == State.Failed);
         
        if (now < completedAt.add(90 days)){
             
            uint256 holderTokens = tokensSent[msg.sender];
             
            tokensSent[msg.sender] = 0;
             
            balance[msg.sender] = 0;
             
            uint256 holderETH = ethOnContract[msg.sender];
             
            ethOnContract[msg.sender] = 0;
             
            require(tokenReward.transferFrom(msg.sender,address(this),holderTokens));
             
            msg.sender.transfer(holderETH);

            emit LogRefund(msg.sender,holderETH);
        } else{
             
            require(level[msg.sender] >= 2);
             
            uint256 remanent = tokenReward.balanceOf(this);
             
            creator.transfer(address(this).balance);
            tokenReward.transfer(creator,remanent);

            emit LogBeneficiaryPaid(creator);
            emit LogContributorsPayout(creator, remanent);
        }
        
    

    }

     
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(_address != tokenReward);  

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(msg.sender,remainder);  
        
    }

     

    function () public payable {
        
        contribute();

    }
}