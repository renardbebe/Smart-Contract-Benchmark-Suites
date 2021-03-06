 

pragma solidity ^0.4.19;
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address _owner ) public view returns (uint balance);
    function allowance( address _owner, address _spender ) public view returns (uint allowance_);

    function transfer( address _to, uint _value)public returns (bool success);
    function transferFrom( address _from, address _to, uint _value)public returns (bool success);
    function approve( address _spender, uint _value )public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed _owner, address indexed _spender, uint value);
}


contract UTEMIS is ERC20{            

        uint8 public constant TOKEN_DECIMAL     = 18;        
        uint256 public constant TOKEN_ESCALE    = 1 * 10 ** uint256(TOKEN_DECIMAL); 
                                              
        uint256 public constant TOTAL_SUPPLY    = 1000000000000 * TOKEN_ESCALE;  
        uint256 public constant ICO_SUPPLY      = 250000000000 * TOKEN_ESCALE;   

        uint public constant MIN_ACCEPTED_VALUE = 50000000000000000 wei;
        uint public constant VALUE_OF_UTS       = 666666599999 wei;

        uint public constant START_ICO          = 1518714000;  

        string public constant TOKEN_NAME       = "UTEMIS";
        string public constant TOKEN_SYMBOL     = "UTS";

     


     
    
        uint[4]  private bonusTime             = [14 days , 45 days , 74 days];        
        uint8[4] private bonusBenefit          = [uint8(50)  , uint8(30)   , uint8(10)];
        uint8[4] private bonusPerInvestion_10  = [uint8(25)  , uint8(15)   , uint8(5)];
        uint8[4] private bonusPerInvestion_50  = [uint8(50)  , uint8(30)   , uint8(20)];
    
     


             
       
        address public owner;
        address public beneficiary;            
        uint public ethersCollecteds;
        uint public tokensSold;
        uint256 public totalSupply = TOTAL_SUPPLY;
        bool public icoStarted;            
        mapping(address => uint256) public balances;    
        mapping(address => Investors) public investorsList;
        mapping(address => mapping (address => uint256)) public allowed;
        address[] public investorsAddress;    
        string public name     = TOKEN_NAME;
        uint8 public decimals  = TOKEN_DECIMAL;
        string public symbol   = TOKEN_SYMBOL;
   
         

    struct Investors{
        uint256 amount;
        uint when;
    }

    event Transfer(address indexed from , address indexed to , uint256 value);
    event Approval(address indexed _owner , address indexed _spender , uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FundTransfer(address backer , uint amount , address investor);

     
    function safeSub(uint a , uint b) internal pure returns (uint){assert(b <= a);return a - b;}  
    function safeAdd(uint a , uint b) internal pure returns (uint){uint c = a + b;assert(c>=a && c>=b);return c;}
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier icoIsStarted(){
        require(icoStarted == true);        
        require(now >= START_ICO);      
        _;
    }

    modifier icoIsStopped(){
        require(icoStarted == false); 
        _;
    }

    modifier minValue(){
        require(msg.value >= MIN_ACCEPTED_VALUE);
        _;
    }

    function UTEMIS() public{
        balances[msg.sender] = totalSupply;
        owner               = msg.sender;        
    }


     
    function balanceOf(address _owner) public view returns(uint256 balance){
        return balances[_owner];
    }

     
    function totalSupply() constant public returns(uint256 supply){
        return totalSupply;
    }



     
    function _transfer(address _from , address _to , uint _value) internal{        
        require(_to != 0x0);                                                           
        require(balances[_from] >= _value);                                            
        require(balances[_to] + _value > balances[_to]);                               
        balances[_from]         = safeSub(balances[_from] , _value);                   
        balances[_to]           = safeAdd(balances[_to]   , _value);                   
        uint previousBalance    = balances[_from] + balances[_to];                     
        Transfer(_from , _to , _value);                                                
        assert(balances[_from] + balances[_to] == previousBalance);                    
    }


     
    function transfer(address _to , uint _value) public returns (bool success){        
        _transfer(msg.sender , _to , _value);
        return true;
    }


        
    function transferFrom(address _from , address _to , uint256 _value) public returns (bool success){
        if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            _transfer(_from , _to , _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender] , _value);
            return true;
        }else{
            return false;
        }
    }

        
    function approve(address _spender , uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender , _spender , _value);
        return true;
    }

        
    function allowance(address _owner , address _spender) public view returns(uint256 allowance_){
        return allowed[_owner][_spender];
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


     
    function getBonus(uint _ethers) public view returns(uint8){        
        uint8 _bonus  = 0;                                                           
        uint8 _bonusPerInvestion = 0;
        uint  starter = now - START_ICO;                                             
        for(uint i = 0; i < bonusTime.length; i++){                                  
            if(starter <= bonusTime[i]){                                             
                if(_ethers > 10 ether && _ethers <= 50 ether){
                    _bonusPerInvestion = bonusPerInvestion_10[i];
                }
                if(_ethers > 50 ether){
                    _bonusPerInvestion = bonusPerInvestion_50[i];
                }
                _bonus = bonusBenefit[i];                                            
                break;                                                               

            }
        }        
        return _bonus + _bonusPerInvestion;
    }

     
    function getTokensToSend(uint _ethers) public view returns (uint){
        uint tokensToSend  = 0;                                                      
        uint8 bonus        = getBonus(_ethers);                                      
        uint ethToTokens   = (_ethers * 10 ** uint256(TOKEN_DECIMAL)) / VALUE_OF_UTS;                                 
        uint amountBonus   = ethToTokens / 100 * bonus;
             tokensToSend  = ethToTokens + amountBonus;
        return tokensToSend;
    }

     
    function () payable public icoIsStarted minValue{                              
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
        tokensSold += tokensToSend;        
        require(balances[owner] >= tokensToSend);
        
        _transfer(owner , msg.sender , tokensToSend);                                
        ethersCollecteds   += msg.value;

        if(beneficiary == address(0)){
            beneficiary = owner;
        }
        beneficiary.transfer(msg.value);
        FundTransfer(owner , msg.value , msg.sender);                                
    }


     
    function startIco() public onlyOwner{
        icoStarted = true;                                                          
    }

     
    function stopIco() public onlyOwner{
        icoStarted = false;                                                         
    }


    function setBeneficiary(address _beneficiary) public onlyOwner{
        beneficiary = _beneficiary;
    }
    
    function destroyContract()external onlyOwner{
        selfdestruct(owner);
    }
    
}