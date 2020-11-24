 

pragma solidity ^0.4.19;

contract UTEMIS{    
     
    
     
    uint                                            public constant ICO_DAYS             = 59;

     
    uint                                            public constant MIN_ACCEPTED_VALUE   = 50000000000000000 wei;

     
    uint                                            public constant VALUE_OF_UTS         = 666666599999 wei;

     
    string                                          public constant TOKEN_NAME           = "UTEMIS";
    
     
    string                                          public constant TOKEN_SYMBOL         = "UTS";

     
    uint256                                         public constant TOTAL_SUPPLY         = 1 * 10 ** 12;    

     
    uint256                                         public constant ICO_SUPPLY           = 2 * 10 ** 11;

     
    uint256                                         public constant SOFT_CAP             = 10000 ether;  

     
    uint                                            public constant START_ICO            = 1515430800;
    
     

     
    address                                         public owner;    

     
    uint                                            public deadLine;        

     
    uint                                            public startTime;

     
    mapping(address => uint256)                     public balance_;

     
    uint                                            public remaining;    

     
    uint[4]                                         private bonusTime                  = [3 days    , 17 days    , 31 days   , 59 days];

     
    uint8[4]                                        private bonusBenefit               = [uint8(40) , uint8(25)  , uint8(20) , uint8(15)];
    uint8[4]                                        private bonusPerInvestion_5        = [uint8(0)  , uint8(5)   , uint8(3)  , uint8(2)];
    uint8[4]                                        private bonusPerInvestion_10       = [uint8(0)  , uint8(10)  , uint8(5)  , uint8(3)];    

     
    address                                         private beneficiary;    

     
    bool                                            private ico_started;

     
    uint256                                         public ethers_collected;
    
     
    uint256                                         private ethers_balance;
        

     
    struct Investors{
        uint256 amount;
        uint when;        
    }

     
    mapping(address => Investors) private investorsList;     
    address[] private investorsAddress;

     
    event Transfer(address indexed from , address indexed to , uint256 value);
    event Burn(address indexed from, uint256 value);
    event FundTransfer(address backer , uint amount , address investor);

     
    function safeSub(uint a , uint b) internal pure returns (uint){assert(b <= a);return a - b;}  
    function safeAdd(uint a , uint b) internal pure returns (uint){uint c = a + b;assert(c>=a && c>=b);return c;}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier icoStarted(){
        require(ico_started == true);
        require(now <= deadLine);
        require(now >= START_ICO);
        _;
    }

    modifier icoStopped(){
        require(ico_started == false);
        require(now > deadLine);
        _;        
    }

    modifier minValue(){
        require(msg.value >= MIN_ACCEPTED_VALUE);
        _;
    }

     
    function UTEMIS() public{          
        balance_[msg.sender] = TOTAL_SUPPLY;                                          
        owner               = msg.sender;                                            
        deadLine            = START_ICO + ICO_DAYS * 1 days;                         
        startTime           = now;                                                   
        remaining           = ICO_SUPPLY;                                            
        ico_started         = false;                                                 
    }

     
    function _transfer(address _from , address _to , uint _value) internal{        
        require(_to != 0x0);                                                         
        require(balance_[_from] >= _value);                                           
        require(balance_[_to] + _value > balance_[_to]);                               
        balance_[_from]         = safeSub(balance_[_from] , _value);                  
        balance_[_to]           = safeAdd(balance_[_to]   , _value);                  
        uint previousBalance    = balance_[_from] + balance_[_to];                     
        Transfer(_from , _to , _value);                                              
        assert(balance_[_from] + balance_[_to] == previousBalance);                    
    }

     
    function transfer(address _to , uint _value) public onlyOwner{                                             
        _transfer(msg.sender , _to , _value);                                        
    }
    
     
    function balanceOf(address _owner) constant public returns(uint balances){
        return balance_[_owner];
    }    

     
    function getInvestors() constant public returns(address[] , uint[] , uint[]){
        uint length = investorsAddress.length;                                              
        address[] memory addr = new address[](length);
        uint[] memory amount  = new uint[](length);
        uint[] memory when    = new uint[](length);
        for(uint i = 0; i < length; i++){
            address key = investorsAddress[i];
            addr[i]     = key;
            amount[i]   = investorsList[key].amount;
            when[i]     = investorsList[key].when;
        }
        return (addr , amount , when);        
    }

     
    function getTokensDistributeds() constant public returns(uint){
        return ICO_SUPPLY - remaining;
    }

     
    function getBonus(uint _ethers) public view returns(uint8){        
        uint8 _bonus  = 0;                                                           
        uint8 _bonusPerInvestion = 0;
        uint  starter = now - START_ICO;                                             
        for(uint i = 0; i < bonusTime.length; i++){                                  
            if(starter <= bonusTime[i]){                                             
                if(_ethers >= 5 ether && _ethers < 10 ether){
                    _bonusPerInvestion = bonusPerInvestion_5[i];
                }
                if(_ethers > 10 ether){
                    _bonusPerInvestion = bonusPerInvestion_10[i];
                }
                _bonus = bonusBenefit[i];                                            
                break;                                                               

            }
        }        
        return _bonus + _bonusPerInvestion;
    }
    
     
    function escale(uint _value) private pure returns(uint){
        return _value * 10 ** 18;
    }

     
    function getTokensToSend(uint _ethers) public view returns (uint){
        uint tokensToSend  = 0;                                                      
        uint8 bonus        = getBonus(_ethers);                                      
        uint ethToTokens   = _ethers / VALUE_OF_UTS;                                 
        uint amountBonus   = escale(ethToTokens) / 100 * escale(bonus);
        uint _amountBonus  = amountBonus / 10 ** 36;
             tokensToSend  = ethToTokens + _amountBonus;
        return tokensToSend;
    }

     
    function setBeneficiary(address _beneficiary) public onlyOwner{
        require(msg.sender == owner);                                                
        beneficiary = _beneficiary;                                                  
    }


     
    function startIco() public onlyOwner{
        ico_started = true;                                                          
    }

     
    function stopIco() public onlyOwner{
        ico_started = false;                                                         
    }

     
    function giveBackEthers() public onlyOwner icoStopped{
        require(this.balance >= ethers_collected);                                          
        uint length = investorsAddress.length;                                              
        for(uint i = 0; i < length; i++){
            address investorA = investorsAddress[i];            
            uint amount       = investorsList[investorA].amount;
            if(address(beneficiary) == 0){
                beneficiary = owner;
            }
            _transfer(investorA , beneficiary , balanceOf(investorA));
            investorA.transfer(amount);
        }
    }

    
     
    function () payable public icoStarted minValue{                              
        uint amount_actually_invested = investorsList[msg.sender].amount;            
        
        if(amount_actually_invested == 0){                                           
            uint index                = investorsAddress.length++;
            investorsAddress[index]   = msg.sender;
            investorsList[msg.sender] = Investors(msg.value , now);                  
        }
        
        if(amount_actually_invested > 0){                                            
            investorsList[msg.sender].amount += msg.value;                           
            investorsList[msg.sender].when    = now;                                 
        }

        uint tokensToSend = getTokensToSend(msg.value);                              
        remaining -= tokensToSend;                                                   
        _transfer(owner , msg.sender , tokensToSend);                                
        
        require(balance_[owner] >= (TOTAL_SUPPLY - ICO_SUPPLY));                      
        require(balance_[owner] >= tokensToSend);
        
        if(address(beneficiary) == 0){                                               
            beneficiary = owner;                                                     
        }    
        ethers_collected += msg.value;                                               
        ethers_balance   += msg.value;
        if(!beneficiary.send(msg.value)){
            revert();
        }                                                 

        FundTransfer(owner , msg.value , msg.sender);                                
    }

     
    function extendICO(uint timetoextend) onlyOwner external{
        require(timetoextend > 0);
        deadLine+= timetoextend;
    }
    
     
    function destroyContract() onlyOwner external{
        selfdestruct(owner);
    }


}