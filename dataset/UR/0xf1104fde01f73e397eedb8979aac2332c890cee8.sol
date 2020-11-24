 

pragma solidity ^0.4.24;


 


 


contract ERC20Interface {
    uint public totalSupply;
    uint public tokensSold;
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) 
        public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant 
        returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, 
        uint _value);
}



 

contract Owned {

     
    address public owner;
    address public newOwner;

     
     
     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

 
     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

 

contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;
     
   modifier whenNotPaused() {
    require(!paused);
    _;
  }
   
    
  modifier whenPaused {
    require(paused);
    _;
  }
   
    
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }
   
    
   function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

 

contract Transferable is Owned {
  event Transfer();
  event Untransfer();

  bool public flg_transfer = true;
     
   modifier whenNotTransfer() {
    require(!flg_transfer);
    _;
  }
   
    
  modifier whenTransfer {
    require(flg_transfer);
    _;
  }
   
    
  function transfer() public onlyOwner whenNotTransfer returns (bool) {
    flg_transfer = true;
    emit Transfer();
    return true;
  }
   
    
   function untransfer() public onlyOwner whenTransfer returns (bool) {
    flg_transfer = false;
    emit Untransfer();
    return true;
  }
}



 
library SafeMath {

     

contract SheltercoinTokCfg {

     
    string public constant SYMBOL = "SHLT";
    string public constant NAME = "SHLT Sheltercoin.io";
    uint8 public constant DECIMALS = 8;
    bool public flg001 = false;
    



     
    uint public constant TOKENS_SOFT_CAP = 1 * DECIMALSFACTOR;
    uint public constant TOKENS_HARD_CAP = 1000000000 * DECIMALSFACTOR;  
    uint public constant TOKENS_TOTAL = 1000000000 * DECIMALSFACTOR;
    uint public tokensSold = 0;


     
    uint public constant DECIMALSFACTOR = 10**uint(DECIMALS);

     
    uint public START_DATE = 1582545600;   
    uint public END_DATE = 1614165071;     

     
    uint public CONTRIBUTIONS_MIN = 0;
    uint public CONTRIBUTIONS_MAX = 1000000 ether;
}



 
contract ERC20Token is ERC20Interface, Owned, Pausable, Transferable {
    using SafeMath for uint;

     
    string public symbol;
    string public name;
    uint8 public decimals;

     
    mapping(address => uint) balances;

     
    mapping(address => mapping (address => uint)) allowed;


     
    constructor (
        string _symbol, 
        string _name, 
        uint8 _decimals, 
        uint _tokensSold
    ) Owned() public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        tokensSold = _tokensSold;
        balances[owner] = _tokensSold;
    }


     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount              
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[msg.sender] = balances[msg.sender].safeSub(_amount);
            balances[_to] = balances[_to].safeAdd(_amount);
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
    function approve(
        address _spender,
        uint _amount
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


     
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] = balances[_from].safeSub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_amount);
            balances[_to] = balances[_to].safeAdd(_amount);
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


     
    function allowance(
        address _owner, 
        address _spender
    ) public constant returns (uint remaining) 
    {
        return allowed[_owner][_spender];
    }
}


 
contract SHLTSheltercoinToken is ERC20Token, SheltercoinTokCfg {

     
    bool public finalised = false;
    
     
    uint public tokensPerEther = 2000;    
    uint public tokensPerKEther = 2000000;  
    uint public etherSold = 0;
    uint public weiSold = 0;
    uint public tokens = 0;
    uint public dspTokens = 0;
    uint public dspTokensSold = 0;
    uint public dspEther = 0;
    uint public dspEtherSold = 0;
    uint public dspWeiSold = 0;
    uint public BONUS_VALUE = 0;
    uint public bonusTokens = 0;

 
    string public SCE_Shelter_ID;
    string public SCE_Shelter_Desc;
   
    string public SCE_Emergency_Type;
 
    string public SCE_UN_Programme_ID;
    string public SCE_Country;
    string public SCE_Region; 
  
    uint public SCE_START_DATE;
    uint public SCE_END_DATE; 
    
     
    address public wallet;
    address public tokenContractAdr;
     
    mapping(address => bool) public Whitelisted;
    mapping(address => bool) public Blacklisted;

    modifier isWhitelisted() {
        require(Whitelisted[msg.sender] == true);
        _;
      }
    
    modifier isBlacklisted() {
        require(Blacklisted[msg.sender] == true);
        _;


      }
   
     
    constructor (address _wallet) 
       public ERC20Token(SYMBOL, NAME, DECIMALS, 0)
    {
        wallet = _wallet;
        flg001 = true ;   

    }

     
    function setWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
        emit WalletUpdated(wallet);
    }
    event WalletUpdated(address newWallet);


     
    function settokensPerKEther(uint _tokensPerKEther) public onlyOwner {
        require(now < START_DATE);
        require(_tokensPerKEther > 0);
        tokensPerKEther = _tokensPerKEther;
        emit tokensPerKEtherUpdated(tokensPerKEther);
    }
    event tokensPerKEtherUpdated(uint _tokPerKEther);


     
    function () public payable {
        ICOContribution(msg.sender);
    }


     
    function ICOContribution(address participant) public payable {
         
        require(!finalised);
         
        require(!paused);
         
        require(now >= START_DATE);
         
        require(now <= END_DATE);
         
        require(msg.value >= CONTRIBUTIONS_MIN);
         
        require(CONTRIBUTIONS_MAX == 0 || msg.value < CONTRIBUTIONS_MAX);

         
        require(Whitelisted[msg.sender]);
        require(!Blacklisted[msg.sender]);

         
        require(wallet.send(msg.value)); 

         
         
         
         
        tokens = msg.value * tokensPerKEther / 10**uint(18 - decimals + 3);

         
        bonusTokens = msg.value.safeMul(BONUS_VALUE + 100);

        bonusTokens = bonusTokens.safeDiv(100);
 
        tokens = bonusTokens;

        dspTokens = tokens * tokensPerKEther / 10**uint(18 - decimals + 6);
        dspEther = tokens / 10**uint(18);  
         
       require(totalSupply + tokens <= TOKENS_HARD_CAP);
       require(tokensSold + tokens <= TOKENS_HARD_CAP);
         
         tokenContractAdr = this;
         
        balances[participant] = balances[participant].safeAdd(tokens);
        tokensSold = tokensSold.safeAdd(tokens);
        etherSold = etherSold.safeAdd(dspEther);
        weiSold = weiSold + tokenContractAdr.balance;
         
         
        dspTokensSold = dspTokensSold.safeAdd(dspTokens);
        dspEtherSold = dspEtherSold.safeAdd(dspEther);
        dspWeiSold = dspWeiSold + tokenContractAdr.balance;
        

  
          
        emit Transfer(tokenContractAdr, participant, tokens);
        emit TokensBought(participant,bonusTokens, dspWeiSold, dspEther, dspEtherSold, dspTokens, dspTokensSold, tokensPerEther);

        
     
    }
    event TokensBought(address indexed buyer, uint newWei, 
        uint newWeiBalance, uint newEther, uint EtherTotal, uint _toks, uint newTokenTotal, 
        uint _toksPerEther);


     
    function finalise() public onlyOwner {
         
        require(tokensSold >= TOKENS_SOFT_CAP || now > END_DATE);
        
        require(!finalised);
           
         tokenContractAdr = this;    
         
        emit TokensBought(tokenContractAdr, 0, dspWeiSold, dspEther, dspEtherSold, dspTokens, dspTokensSold, tokensPerEther);
         
        finalised = true;
    }


     
    function ICOAddPrecommitment(address participant, uint balance) public onlyOwner {
          
        require(!paused);
         
         
         
         
        require(balance > 0);
         
        require(address(participant) != 0x0);
         
        tokenContractAdr = this;
        balances[participant] = balances[participant].safeAdd(balance);
        tokensSold = tokensSold.safeAdd(balance);
        emit Transfer(tokenContractAdr, participant, balance);
    }
    event ICOcommitmentAdded(address indexed participant, uint balance, uint tokensSold );

     
    function ICOdt(uint START_DATE_NEW, uint END_DATE_NEW ) public onlyOwner {
         
        require(!finalised);
         
        require(!paused);
         
         
        require(START_DATE_NEW > 0);
        require(END_DATE_NEW > 0);
        tokenContractAdr = this;
        START_DATE = START_DATE_NEW;
        END_DATE = END_DATE_NEW;
        emit ICOdate(START_DATE, END_DATE);
     }
    event ICOdate(uint ST_DT, uint END_DT);

     
    function transfer(address _to, uint _amount) public returns (bool success) {
         
         
         
         
         
         
        return super.transfer(_to, _amount);
    }


     
    function transferFrom(address _from, address _to, uint _amount) 
        public returns (bool success)
    {
         
         
         
         
         
        return super.transferFrom(_from, _to, _amount);
    }


  
    function mintFrom(
        address _from,
        uint _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][0x0] >= _amount            
            && _amount > 0                               
            && balances[0x0] + _amount > balances[0x0]   
        ) {
            balances[_from] = balances[_from].safeSub(_amount);
            allowed[_from][0x0] = allowed[_from][0x0].safeSub(_amount);
            balances[0x0] = balances[0x0].safeAdd(_amount);
            tokensSold = tokensSold.safeSub(_amount);
            emit Transfer(_from, 0x0, _amount);
            return true;
        } else {
            return false;
        }
    
 
     }  
    

 
    function setBonus(uint _bonus) public onlyOwner

        returns (bool success) {
        require (!finalised);
        if (_bonus >= 0)                
          {
            BONUS_VALUE = _bonus;
            return true;
        } else {
            return false;
        }
          emit BonusSet(_bonus);
        }
    event BonusSet(uint _bonus);

     
   
   
    function AddToWhitelist(address participant) public onlyOwner {
        Whitelisted[participant] = true;
        emit AddedToWhitelist(participant);
    }
    event AddedToWhitelist(address indexed participant);

    function IsWhitelisted(address participant) 
        public view returns (bool) {
      return bool(Whitelisted[participant]);
    }
    
    function RemoveFromWhitelist(address participant) public onlyOwner {
        Whitelisted[participant] = false;
        emit RemovedFromWhitelist(participant);
    }
    event RemovedFromWhitelist(address indexed participant);

    function AddToBlacklist(address participant) public onlyOwner {
        Blacklisted[participant] = true;
        emit AddedToBlacklist(participant);
    }
    event AddedToBlacklist(address indexed participant);

    function IsBlacklisted(address participant) 
        public view returns (bool) {
      return bool(Blacklisted[participant]);
    }
    function RemoveFromBlackList(address participant) public onlyOwner {
        Blacklisted[participant] = false;
        emit RemovedFromBlacklist(participant);
    }
    event RemovedFromBlacklist(address indexed participant);

    function SCEmergency(string _Shelter_ID, string _Shelter_Description, string _Emergency_Type, string _UN_Programme_ID, string _Country, string _Region, uint START_DATE_SCE, uint END_DATE_SCE ) public onlyOwner {
 
         
        finalised = true;
        require(finalised);
         
         
         
         require(START_DATE_SCE > 0);
         
        tokenContractAdr = this;
        SCE_Shelter_ID = _Shelter_ID;
        SCE_Shelter_Desc = _Shelter_Description;
        SCE_Emergency_Type = _Emergency_Type;
        SCE_UN_Programme_ID = _UN_Programme_ID;
        SCE_Country = _Country;
        SCE_Region = _Region; 
        SCE_START_DATE = START_DATE_SCE;
        SCE_END_DATE = END_DATE_SCE; 
        emit SC_Emergency(SCE_Shelter_ID, SCE_Shelter_Desc, SCE_Emergency_Type, SCE_UN_Programme_ID, SCE_Country, SCE_Region, SCE_START_DATE, SCE_END_DATE );
       
    }
    event SC_Emergency(string _str_Shelter_ID, string _str_Shelter_Descrip, string _str_Emergency_Type, string _str_UN_Prog_ID, string _str_Country, string _str_Region, uint SC_ST_DT, uint SC_END_DT);
    

}