 

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  
  event Transfer(address indexed _from, address indexed _to, uint _value);
   
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint _value);
   
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
     
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract BigbomContributorWhiteList is Ownable {
    mapping(address=>uint) public addressMinCap;
    mapping(address=>uint) public addressMaxCap;

    function BigbomContributorWhiteList() public  {}

    event ListAddress( address _user, uint _mincap, uint _maxcap, uint _time );

     
     
    function listAddress( address _user, uint _mincap, uint _maxcap ) public onlyOwner {
        require(_mincap <= _maxcap);
        require(_user != address(0x0));

        addressMinCap[_user] = _mincap;
        addressMaxCap[_user] = _maxcap;
        ListAddress( _user, _mincap, _maxcap, now );
    }

     
    function listAddresses( address[] _users, uint[] _mincap, uint[] _maxcap ) public  onlyOwner {
        require(_users.length == _mincap.length );
        require(_users.length == _maxcap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _mincap[i], _maxcap[i] );
        }
    }

    function getMinCap( address _user ) public constant returns(uint) {
        return addressMinCap[_user];
    }
    function getMaxCap( address _user ) public constant returns(uint) {
        return addressMaxCap[_user];
    }

}

contract BigbomPrivateSaleList is Ownable {
    mapping(address=>uint) public addressCap;

    function BigbomPrivateSaleList() public  {}

    event ListAddress( address _user, uint _amount, uint _time );

     
     
    function listAddress( address _user, uint _amount ) public onlyOwner {
        require(_user != address(0x0));

        addressCap[_user] = _amount;
        ListAddress( _user, _amount, now );
    }

     
    function listAddresses( address[] _users, uint[] _amount ) public onlyOwner {
        require(_users.length == _amount.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _amount[i] );
        }
    }

    function getCap( address _user ) public constant returns(uint) {
        return addressCap[_user];
    }

}

contract BigbomToken is StandardToken, Ownable {
    
    string  public  constant name = "Bigbom";
    string  public  constant symbol = "BBO";
    uint    public  constant decimals = 18;
    uint    public   totalSupply = 2000000000 * 1e18;  

    uint    public  constant founderAmount = 200000000 * 1e18;  
    uint    public  constant coreStaffAmount = 60000000 * 1e18;  
    uint    public  constant advisorAmount = 140000000 * 1e18;  
    uint    public  constant networkGrowthAmount = 600000000 * 1e18;  
    uint    public  constant reserveAmount = 635000000 * 1e18;  
    uint    public  constant bountyAmount = 40000000 * 1e18;  
    uint    public  constant publicSaleAmount = 275000000 * 1e18;  

    address public   bbFounderCoreStaffWallet ;
    address public   bbAdvisorWallet;
    address public   bbAirdropWallet;
    address public   bbNetworkGrowthWallet;
    address public   bbReserveWallet;
    address public   bbPublicSaleWallet;

    uint    public  saleStartTime;
    uint    public  saleEndTime;

    address public  tokenSaleContract;
    BigbomPrivateSaleList public privateSaleList;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint) public frozenTime;
    mapping (address => uint) public maxAllowedAmount;

     
    event FrozenFunds(address target, bool frozen, uint _seconds);
   

    function checkMaxAllowed(address target)  public constant  returns (uint) {
        var maxAmount  = balances[target];
        if(target == bbFounderCoreStaffWallet){
            maxAmount = 10000000 * 1e18;
        }
        if(target == bbAdvisorWallet){
            maxAmount = 10000000 * 1e18;
        }
        if(target == bbAirdropWallet){
            maxAmount = 40000000 * 1e18;
        }
        if(target == bbNetworkGrowthWallet){
            maxAmount = 20000000 * 1e18;
        }
        if(target == bbReserveWallet){
            maxAmount = 6350000 * 1e18;
        }
        return maxAmount;
    }

    function selfFreeze(bool freeze, uint _seconds) public {
         
        require(_seconds <= 7 * 24 * 3600);
         
        if(!freeze){
             
            var frozenEndTime = frozenTime[msg.sender];
             
            require (now >= frozenEndTime);
             
            frozenAccount[msg.sender] = freeze;
             
            _seconds = 0;           
        }else{
            frozenAccount[msg.sender] = freeze;
            
        }
         
        frozenTime[msg.sender] = now + _seconds;
        FrozenFunds(msg.sender, freeze, _seconds);
        
    }

    function freezeAccount(address target, bool freeze, uint _seconds) onlyOwner public {
        
         
        if(!freeze){
             
            var frozenEndTime = frozenTime[target];
             
            require (now >= frozenEndTime);
             
            frozenAccount[target] = freeze;
             
            _seconds = 0;           
        }else{
            frozenAccount[target] = freeze;
            
        }
         
        frozenTime[target] = now + _seconds;
        FrozenFunds(target, freeze, _seconds);
        
    }

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        require(!frozenAccount[to]);                        
        _;
    }
    modifier validFrom(address from){
        require(!frozenAccount[from]);                      
        _;
    }
    modifier onlyWhenTransferEnabled() {
        if( now <= saleEndTime && now >= saleStartTime ) {
            require( msg.sender == tokenSaleContract );
        }
        _;
    }
    modifier onlyPrivateListEnabled(address _to){
        require(now <= saleStartTime);
        uint allowcap = privateSaleList.getCap(_to);
        require (allowcap > 0);
        _;
    }
    function setPrivateList(BigbomPrivateSaleList _privateSaleList)   onlyOwner public {
        require(_privateSaleList != address(0x0));
        privateSaleList = _privateSaleList;

    }
    
    function BigbomToken(uint startTime, uint endTime, address admin, address _bbFounderCoreStaffWallet, address _bbAdvisorWallet,
        address _bbAirdropWallet,
        address _bbNetworkGrowthWallet,
        address _bbReserveWallet, 
        address _bbPublicSaleWallet
        ) public {

        require(admin!=address(0x0));
        require(_bbAirdropWallet!=address(0x0));
        require(_bbAdvisorWallet!=address(0x0));
        require(_bbReserveWallet!=address(0x0));
        require(_bbNetworkGrowthWallet!=address(0x0));
        require(_bbFounderCoreStaffWallet!=address(0x0));
        require(_bbPublicSaleWallet!=address(0x0));

         
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);
         
         
        bbAirdropWallet = _bbAirdropWallet;
        bbAdvisorWallet = _bbAdvisorWallet;
        bbReserveWallet = _bbReserveWallet;
        bbNetworkGrowthWallet = _bbNetworkGrowthWallet;
        bbFounderCoreStaffWallet = _bbFounderCoreStaffWallet;
        bbPublicSaleWallet = _bbPublicSaleWallet;
        
        saleStartTime = startTime;
        saleEndTime = endTime;
        transferOwnership(admin);  
    }

    function setTimeSale(uint startTime, uint endTime) onlyOwner public {
        require (now < saleStartTime || now > saleEndTime);
        require (now < startTime);
        require ( startTime < endTime);
        saleStartTime = startTime;
        saleEndTime = endTime;
    }

    function setTokenSaleContract(address _tokenSaleContract) onlyOwner public {
         
        require(_tokenSaleContract != address(0x0));
         
        require (now < saleStartTime || now > saleEndTime);

        tokenSaleContract = _tokenSaleContract;
    }
    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        validFrom(msg.sender)
        public 
        returns (bool) {
        if (msg.sender == bbFounderCoreStaffWallet || msg.sender == bbAdvisorWallet|| 
            msg.sender == bbAirdropWallet|| msg.sender == bbNetworkGrowthWallet|| msg.sender == bbReserveWallet){

             
            var withdrawAmount =  maxAllowedAmount[msg.sender]; 
            var defaultAllowAmount = checkMaxAllowed(msg.sender);
            var maxAmount = defaultAllowAmount - withdrawAmount;
             
            require(maxAmount >= _value);  

             
            if(maxAmount==_value){
               
                var isTransfer = super.transfer(_to, _value);
                  
                selfFreeze(true, 24 * 3600);  
                maxAllowedAmount[msg.sender] = 0;
                return isTransfer;
            }else{
                 
                maxAllowedAmount[msg.sender] = maxAllowedAmount[msg.sender].add(_value);  
                
            }
        }
        return  super.transfer(_to, _value);
            
    }

    function transferPrivateSale(address _to, uint _value)
        onlyOwner
        onlyPrivateListEnabled(_to) 
        public 
        returns (bool) {
         return transfer( _to,  _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        validFrom(_from)
        public 
        returns (bool) {
            if (_from == bbFounderCoreStaffWallet || _from == bbAdvisorWallet|| 
                _from == bbAirdropWallet|| _from == bbNetworkGrowthWallet|| _from == bbReserveWallet){

                   
                var withdrawAmount =  maxAllowedAmount[_from]; 
                var defaultAllowAmount = checkMaxAllowed(_from);
                var maxAmount = defaultAllowAmount - withdrawAmount; 
                 
                require(maxAmount >= _value); 

                 
                if(maxAmount==_value){
                   
                    var isTransfer = super.transfer(_to, _value);
                      
                    selfFreeze(true, 24 * 3600); 
                    maxAllowedAmount[_from] = 0;
                    return isTransfer;
                }else{
                     
                    maxAllowedAmount[_from] = maxAllowedAmount[_from].add(_value); 
                    
                }
            }
            return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) onlyWhenTransferEnabled
        public 
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyWhenTransferEnabled
        public 
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner public {
        token.transfer( owner, amount );
    }
}

contract BigbomTokenSale {
    address             public admin;
    address             public bigbomMultiSigWallet;
    BigbomToken         public token;
    uint                public raisedWei;
    bool                public haltSale;
    uint                      public openSaleStartTime;
    uint                      public openSaleEndTime;
    BigbomContributorWhiteList public list;

    mapping(address=>uint)    public participated;

    using SafeMath for uint;

    function BigbomTokenSale( address _admin,
                              address _bigbomMultiSigWallet,
                              BigbomContributorWhiteList _whilteListContract,
                              uint _publicSaleStartTime,
                              uint _publicSaleEndTime,
                              BigbomToken _token) public       
    {
        require (_publicSaleStartTime < _publicSaleEndTime);
        require (_admin != address(0x0));
        require (_bigbomMultiSigWallet != address(0x0));
        require (_whilteListContract != address(0x0));
        require (_token != address(0x0));

        admin = _admin;
        bigbomMultiSigWallet = _bigbomMultiSigWallet;
        list = _whilteListContract;
        openSaleStartTime = _publicSaleStartTime;
        openSaleEndTime = _publicSaleEndTime;
        token = _token;
    }
    
    function saleEnded() public constant returns(bool) {
        return now > openSaleEndTime;
    }

    function saleStarted() public constant returns(bool) {
        return now >= openSaleStartTime;
    }

    function setHaltSale( bool halt ) public {
        require( msg.sender == admin );
        haltSale = halt;
    }
     
    function contributorMinCap( address contributor ) public constant returns(uint) {
        return list.getMinCap( contributor );
    }
    function contributorMaxCap( address contributor, uint amountInWei ) public constant returns(uint) {
        uint cap = list.getMaxCap( contributor );
        if( cap == 0 ) return 0;
        uint remainedCap = cap.sub( participated[ contributor ] );

        if( remainedCap > amountInWei ) return amountInWei;
        else return remainedCap;
    }

    function checkMaxCap( address contributor, uint amountInWei ) internal returns(uint) {
        uint result = contributorMaxCap( contributor, amountInWei );
        participated[contributor] = participated[contributor].add( result );
        return result;
    }

    function() payable public {
        buy( msg.sender );
    }



    function getBonus(uint _tokens) public view returns (uint){
        if (now > openSaleStartTime && now <= (openSaleStartTime+3 days)){
            return _tokens.mul(25).div(100);
        }
        else
        {
            return 0;
        }
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei, uint _bonus );
    function buy( address recipient ) payable public returns(uint){
         

        require( ! haltSale );
        require( saleStarted() );
        require( ! saleEnded() );

        uint mincap = contributorMinCap(recipient);

        uint maxcap = checkMaxCap(recipient, msg.value );
        uint allowValue = msg.value;
        require( mincap > 0 );
        require( maxcap > 0 );
         
        require (msg.value >= mincap);
         
        if( msg.value > maxcap  ) {
            allowValue = maxcap;
             
            msg.sender.transfer( msg.value.sub( maxcap ) );
        }

         
        sendETHToMultiSig(allowValue);
        raisedWei = raisedWei.add( allowValue );
         
        uint recievedTokens = allowValue.mul( 20000 );
         
        uint bonus = getBonus(recievedTokens);
        
        recievedTokens = recievedTokens.add(bonus);
        assert( token.transfer( recipient, recievedTokens ) );
         

        Buy( recipient, recievedTokens, allowValue, bonus );

        return msg.value;
    }

    function sendETHToMultiSig( uint value ) internal {
        bigbomMultiSigWallet.transfer( value );
    }

    event FinalizeSale();
     
    function finalizeSale() public {
        require( saleEnded() );
         

         
        token.burn(token.balanceOf(this));

        FinalizeSale();
    }

     
     
    function emergencyDrain(ERC20 anyToken) public returns(bool){
        require( msg.sender == admin );
        require( saleEnded() );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(bigbomMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }

     
     
    function debugBuy() payable public {
        require( msg.value > 0 );
        sendETHToMultiSig( msg.value );
    }
}