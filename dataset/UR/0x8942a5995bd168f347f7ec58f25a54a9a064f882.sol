 

 

pragma solidity ^0.4.25;


interface HDX20Interface
{
   
    function moveAccountIn( address _customerAddress ) payable external;
  
}

contract HDX20
{
     using SafeMath for uint256;
     
      
     HDX20Interface private NewHDX20Contract = HDX20Interface(0);
     
     
    event OwnershipTransferred(
         address indexed previousOwner,
         address indexed nextOwner
         );
         
   
         
         
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
  
         
    event onBuyEvent(
        address from,
        uint256 tokens
    );
   
     event onSellEvent(
        address from,
        uint256 tokens
    );
    
    
         
    event onAccountMovedOut(
        address indexed from,
        address to,
        uint256 tokens,
        uint256 eth
    );
    
    event onAccountMovedIn(
        address indexed from,
        address to,
        uint256 tokens,
        uint256 eth
    );
    
    event HDXcontractChanged(
        
         address previous,
         address next,
         uint256 timeStamp
         );
    
     
    modifier onlyOwner
    {
        require (msg.sender == owner);
        _;
    }
    
    modifier onlyFromGameWhiteListed
    {
        require (gameWhiteListed[ msg.sender ] == true);
        _;
    }
    
  
    
    modifier onlyGameWhiteListed(address who)
    {
        require (gameWhiteListed[ who ] == true);
        _;
    }
    
    
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }
    
  
 
  
    address public owner;
    
      

    constructor () public
    {
        owner = msg.sender;
       
        
        if ( address(this).balance > 0)
        {
            owner.transfer( address(this).balance );
        }
    }

  
   

     

    string public name = "HDX20 token";
    string public symbol = "HDX20";
    uint8 constant public decimals = 18;
    uint256 constant internal magnitude = 1e18;
    
    
    
    uint8 constant internal referrerFee = 50;     
    uint8 constant internal transferFee = 2;      
    uint8 constant internal buyInFee = 3;        
    uint8 constant internal sellOutFee = 3;      
    uint8 constant internal devFee = 1;           
    
    
    mapping(address => uint256) private tokenBalanceLedger;
  
    
    uint256 private tokenSupply = 0;  
    uint256 private contractValue = 0;
    uint256 private tokenPrice = 0.001 ether;    
  
  
    
    
    mapping(address => bool)   private gameWhiteListed;
    mapping(address => uint8)  private superReferrerRate;
   
    
     
    
      
    function()
        payable
        public
    {
        buyToken(address(0));
    }
    
    
    
    function changeOwner(address _nextOwner) public
    onlyOwner
    {
        require (_nextOwner != owner);
        require(_nextOwner != address(0));
         
        emit OwnershipTransferred(owner, _nextOwner);
         
        owner = _nextOwner;
    }
    
    
 
    
    function changeName(string _name) public
    onlyOwner
    {
        name = _name;
    }
    
  
    function changeSymbol(string _symbol) public
    onlyOwner
    {
        symbol = _symbol;
    }
 
    
    function addGame(address _contractAddress ) public
    onlyOwner
    {
        gameWhiteListed[ _contractAddress ] = true;
    }
    
    function addSuperReferrer(address _contractAddress , uint8 extra_rate) public
    onlyOwner
    {
       superReferrerRate[ _contractAddress ] = extra_rate;
    }
    
    function removeGame(address _contractAddress ) public
    onlyOwner
    {
        gameWhiteListed[ _contractAddress ] = false;
    }
    
    function changeNewHDX20Contract(address _next) public
    onlyOwner
    {
        require (_next != address( NewHDX20Contract ));
        require( _next != address(0));
         
        emit HDXcontractChanged(address(NewHDX20Contract), _next , now);
         
        NewHDX20Contract  = HDX20Interface( _next);
    }
    
    function buyTokenSub( uint256 _eth , address _customerAddress ) private
    returns(uint256)
    {
        
        uint256 _nb_token = (_eth.mul( magnitude)) / tokenPrice;
        
        
        tokenBalanceLedger[ _customerAddress ] =  tokenBalanceLedger[ _customerAddress ].add( _nb_token);
        tokenSupply = tokenSupply.add(_nb_token);
        
        emit onBuyEvent( _customerAddress , _nb_token);
        
        return( _nb_token );
     
    }
    
    function buyTokenFromGame( address _customerAddress , address _referrer_address ) public payable
    onlyFromGameWhiteListed
    returns(uint256)
    {
        uint256 _eth = msg.value;
        
        if (_eth==0) return(0);
        
        
        uint256 _devfee = (_eth.mul( devFee )) / 100;
        
        uint256 _fee = (_eth.mul( buyInFee )) / 100;
        
        if (_referrer_address != address(0) && _referrer_address != _customerAddress )
        {
             uint256 _ethReferrer = (_fee.mul(referrerFee + superReferrerRate[_referrer_address])) / 100;

             buyTokenSub( _ethReferrer , _referrer_address);
             
              
             _fee = _fee.sub( _ethReferrer );
             
        }
        
         
        
        buyTokenSub( (_devfee.mul(100-buyInFee)) / 100 , owner );
        
         
     
        uint256 _nb_token = buyTokenSub( _eth - _fee -_devfee , _customerAddress);
        
         
        contractValue = contractValue.add( _eth );
        
      
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
       
        
        return( _nb_token );
        
    }
  
  
    function buyToken( address _referrer_address ) public payable
    returns(uint256)
    {
        uint256 _eth = msg.value;
        address _customerAddress = msg.sender;
        
        require( _eth>0);
        
        uint256 _devfee = (_eth.mul( devFee )) / 100;
         
        uint256 _fee = (_eth.mul( buyInFee )) / 100;
        
        if (_referrer_address != address(0) && _referrer_address != _customerAddress )
        {
             uint256 _ethReferrer = (_fee.mul(referrerFee + superReferrerRate[_referrer_address])) / 100;

             buyTokenSub( _ethReferrer , _referrer_address);
             
             
             _fee = _fee.sub( _ethReferrer );
             
        }

         

        buyTokenSub( (_devfee.mul(100-buyInFee)) / 100 , owner );
        
         
      
        uint256 _nb_token = buyTokenSub( _eth - _fee -_devfee , _customerAddress);
        
         
        contractValue = contractValue.add( _eth );
        
     
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
        return( _nb_token );
        
    }
    
    function sellToken( uint256 _amount ) public
    onlyTokenHolders
    {
        address _customerAddress = msg.sender;
        
        uint256 balance = tokenBalanceLedger[ _customerAddress ];
        
        require( _amount <= balance);
        
        uint256 _eth = (_amount.mul( tokenPrice )) / magnitude;
        
        uint256 _fee = (_eth.mul( sellOutFee)) / 100;
        
        uint256 _devfee = (_eth.mul( devFee)) / 100;
        
        tokenSupply = tokenSupply.sub( _amount );
       
     
        balance = balance.sub( _amount );
        
        tokenBalanceLedger[ _customerAddress] = balance;
        
         
        buyTokenSub(  (_devfee.mul(100-buyInFee)) / 100 , owner );
        
        
         
        _eth = _eth - _fee - _devfee; 
        
        contractValue = contractValue.sub( _eth );
        
       
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
         emit onSellEvent( _customerAddress , _amount);
        
          
        _customerAddress.transfer( _eth );
        
    }
   
     
  
    function payWithToken( uint256 _eth , address _player_address ) public
    onlyFromGameWhiteListed
    returns(uint256)
    {
        require( _eth>0 && _eth <= ethBalanceOfNoFee(_player_address ));
        
        address _game_contract = msg.sender;
        
        uint256 balance = tokenBalanceLedger[ _player_address ];
        
        uint256 _nb_token = (_eth.mul( magnitude) ) / tokenPrice;
        
        require( _nb_token <= balance);
        
         
        _eth = (_nb_token.mul( tokenPrice)) / magnitude;
        
        balance = balance.sub(_nb_token);
        
        tokenSupply = tokenSupply.sub( _nb_token);
        
        tokenBalanceLedger[ _player_address ] = balance;
        
        contractValue = contractValue.sub( _eth );
        
       
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
         
        _game_contract.transfer( _eth );
      
      
        return( _eth );
    }
    
    function moveAccountOut() public
    onlyTokenHolders
    {
        address _customerAddress = msg.sender;
        
        require( ethBalanceOfNoFee( _customerAddress )>0 && address(NewHDX20Contract) != address(0));
    
        uint256 balance = tokenBalanceLedger[ _customerAddress ];
    
        uint256 _eth = (balance.mul( tokenPrice )) / magnitude;
        
       
        tokenSupply = tokenSupply.sub( balance );
        
        tokenBalanceLedger[ _customerAddress ] = 0;
        
        contractValue = contractValue.sub( _eth );
        
     
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
        emit onAccountMovedOut( _customerAddress , address(NewHDX20Contract), balance , _eth );
      
         
         
        NewHDX20Contract.moveAccountIn.value(_eth)(_customerAddress);
      
    }
    
    function moveAccountIn(address _customerAddress) public
    payable
    onlyFromGameWhiteListed
    {
        
        
        uint256 _eth = msg.value;
      
         
        uint256 _nb_token = buyTokenSub( _eth , _customerAddress );
        
        contractValue = contractValue.add( _eth );
    
      
        if (tokenSupply>magnitude)
        {
            tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
        emit onAccountMovedIn( msg.sender, _customerAddress , _nb_token , _eth );
     
    }
    
    
    function appreciateTokenPrice() public payable
    onlyFromGameWhiteListed
    {
        uint256 _eth =  msg.value;
       
        contractValue = contractValue.add( _eth );
            
         
        if (tokenSupply>magnitude)
        {
                tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
        }
       
        
    }
    
  
    
    function transferSub(address _customerAddress, address _toAddress, uint256 _amountOfTokens)
    private
    returns(bool)
    {
       
        require( _amountOfTokens <= tokenBalanceLedger[_customerAddress] );
        
         
        if (_amountOfTokens>0)
        {
            
           
            {
            
                uint256 _token_fee =  (_amountOfTokens.mul( transferFee )) / 100;
               
                _token_fee /= 2;
               
                
                 
                tokenBalanceLedger[ _customerAddress] = tokenBalanceLedger[ _customerAddress].sub( _amountOfTokens );
                tokenBalanceLedger[ _toAddress] = tokenBalanceLedger[ _toAddress].add( _amountOfTokens - (_token_fee*2) );
              
                 
                tokenBalanceLedger[ owner ] += _token_fee;
                
                 
                tokenSupply = tokenSupply.sub( _token_fee );
              
             
                if (tokenSupply>magnitude)
                {
                    tokenPrice = (contractValue.mul( magnitude)) / tokenSupply;
                }
               
            }
           
           
          
        
        }
      
      
         
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
         
        return true;
       
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
    public
    returns(bool)
    {
        
        return( transferSub( msg.sender ,  _toAddress, _amountOfTokens));
       
    }
    
  
    
    
     
    
  
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function totalContractBalance()
        public
        view
        returns(uint)
    {
        return contractValue;
    }
    
  
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply;
    }
    
  
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
   
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger[_customerAddress];
    }
    
    function sellingPrice( bool includeFees)
        view
        public
        returns(uint256)
    {
        uint256 _fee = 0;
        uint256 _devfee=0;
        
        if (includeFees)
        {
            _fee = (tokenPrice.mul( sellOutFee ) ) / 100;
            _devfee = (tokenPrice.mul( devFee ) ) / 100;
        }
        
        return( tokenPrice - _fee - _devfee );
        
    }
    
    function buyingPrice( bool includeFees)
        view
        public
        returns(uint256)
    {
        uint256 _fee = 0;
        uint256 _devfee=0;
        
        if (includeFees)
        {
            _fee = (tokenPrice.mul( buyInFee ) ) / 100;
            _devfee = (tokenPrice.mul( devFee ) ) / 100;
        }
        
        return( tokenPrice + _fee + _devfee );
        
    }
    
    function ethBalanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        
        uint256 _price = sellingPrice( true );
        
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        
        uint256 _value = (_balance.mul( _price )) / magnitude;
        
        
        return( _value );
    }
    
  
   
    function myEthBalanceOf()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ethBalanceOf(_customerAddress);
    }
   
   
    function ethBalanceOfNoFee(address _customerAddress)
        view
        public
        returns(uint256)
    {
        
        uint256 _price = sellingPrice( false );
        
        uint256 _balance = tokenBalanceLedger[ _customerAddress];
        
        uint256 _value = (_balance.mul( _price )) / magnitude;
        
        
        return( _value );
    }
    
  
   
    function myEthBalanceOfNoFee()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return ethBalanceOfNoFee(_customerAddress);
    }
    
    function checkGameListed(address _contract)
        view
        public
        returns(bool)
    {
      
      return( gameWhiteListed[ _contract]);
    }
    
    function getSuperReferrerRate(address _customerAddress)
        view
        public
        returns(uint8)
    {
      
      return( referrerFee+superReferrerRate[ _customerAddress]);
    }
    
  
    
}


library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a);
        return c;
    }
    
   
    
  
    
   
}