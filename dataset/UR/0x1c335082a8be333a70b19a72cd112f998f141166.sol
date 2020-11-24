 

 




pragma solidity ^0.4.25;


interface HDX20Interface
{
    function() payable external;
    
    
    function buyTokenFromGame( address _customerAddress , address _referrer_address ) payable external returns(uint256);
  
    function payWithToken( uint256 _eth , address _player_address ) external returns(uint256);
  
    function appreciateTokenPrice() payable external;
   
    function totalSupply() external view returns(uint256); 
    
    function ethBalanceOf(address _customerAddress) external view returns(uint256);
  
    function balanceOf(address _playerAddress) external view returns(uint256);
    
    function sellingPrice( bool includeFees) external view returns(uint256);
  
}


contract TorpedoLaunchGame
{
     HDX20Interface private HDXcontract = HDX20Interface(0x8942a5995bd168f347f7ec58f25a54a9a064f882);
     
     using SafeMath for uint256;
     using SafeMath128 for uint128;
     
      
    event OwnershipTransferred(
        
         address previousOwner,
         address nextOwner,
          uint256 timeStamp
         );
         
    event HDXcontractChanged(
        
         address previous,
         address next,
         uint256 timeStamp
         );
 
    event onJackpotWin(
        address customerAddress,
        uint256 val
       
    );
    
    event onChangeAverageScore(
        uint32 score
       
    );
    
    event onChangeJackpotCycle(
        uint32 cycle
       
    );
    
    
     event onChangeMaximumScore(
        uint32 score
       
    );
    
     event onChangeTimeout(
        uint32 timeout
       
    );
	    
     event onWithdrawGains(
        address customerAddress,
        uint256 ethereumWithdrawn,
        uint256 timeStamp
    );
    
    event onNewScore(
		uint256       score,
        address       customerAddress,
        bool          newHighScore,
        uint256		  val,				 
        uint32        torpedoBatchMultiplier   
        
    );
             
    event onBuyTorpedo(
        address     customerAddress,
        uint256     torpedoBatchID,
        uint256     torpedoBatchBlockTimeout,  
        uint256     nbToken,
        uint32      torpedoBatchMultiplier   
        );    
        
        
     event onMaintenance(
        bool        mode,
        uint256     timeStamp

        );    
      
        
    event onChangeBlockTimeAverage(
        
         uint256 blocktimeavg
         
        );    
        
    event onChangeMinimumPrice(
        
         uint256 minimum,
         uint256 timeStamp
         );
         
    event onNewName(
        
         address     customerAddress,
         bytes32     name,
         uint256     timeStamp
         );
        
     
    modifier onlyOwner
    {
        require (msg.sender == owner );
        _;
    }
    
    modifier onlyFromHDXToken
    {
        require (msg.sender == address( HDXcontract ));
        _;
    }
   
     modifier onlyDirectTransaction
    {
        require (msg.sender == tx.origin);
        _;
    }
   
   
  
    
    modifier isMaintenance
    {
        require (maintenanceMode==true);
        _;
    }
    
     modifier isNotMaintenance
    {
        require (maintenanceMode==false);
        _;
    }
   
  
    address public owner;
  
   
    address public signerAuthority = 0xf77444cE64f3F46ba6b63F6b9411dF9c589E3319;
   
    
    

    constructor () public
    {
        owner = msg.sender;
       
		 
		
		uint32 maximumScore = (1350+70)*15;
	   	   
		GameRoundData.extraData[2] = maximumScore/5;
		GameRoundData.extraData[3] = 100;  
        GameRoundData.extraData[4] = maximumScore;
        GameRoundData.extraData[5] = 60*60;  
        
        if ( address(this).balance > 0)
        {
            owner.transfer( address(this).balance );
        }
    }
    
    function changeOwner(address _nextOwner) public
    onlyOwner
    {
        require (_nextOwner != owner);
        require(_nextOwner != address(0));
         
        emit OwnershipTransferred(owner, _nextOwner , now);
         
        owner = _nextOwner;
    }
    
    function changeSigner(address _nextSigner) public
    onlyOwner
    {
        require (_nextSigner != signerAuthority);
        require(_nextSigner != address(0));
      
        signerAuthority = _nextSigner;
    }
    
    function changeHDXcontract(address _next) public
    onlyOwner
    {
        require (_next != address( HDXcontract ));
        require( _next != address(0));
         
        emit HDXcontractChanged(address(HDXcontract), _next , now);
         
        HDXcontract  = HDX20Interface( _next);
    }
  
  
    
    function changeBlockTimeAverage( uint256 blocktimeavg) public
    onlyOwner
    {
        require ( blocktimeavg>0 );
        
       
        blockTimeAverage = blocktimeavg;
        
        emit onChangeBlockTimeAverage( blockTimeAverage );
         
    }
    
    
     
    function changeAverageScore( uint32 score) public
    onlyOwner
    {
       
        GameRoundData.extraData[2] = score;
        
        emit onChangeAverageScore( score );
         
    }
    
     
    function changeJackpotCycle( uint32 cycle) public
    onlyOwner
    {
         
        require( cycle>0 && cycle<=1000);
        
       
        GameRoundData.extraData[3] = cycle;
        
        emit onChangeJackpotCycle( cycle );
         
    }
    
     
    function changeMaximumScore( uint32 score) public
    onlyOwner
    {
         
        require( score > 4000);
        
        GameRoundData.extraData[4] = score;
       
        
        changeAverageScore( score / 5 );
        
        
        emit onChangeMaximumScore( score );
         
    }
    
      
    function changeTimeOut( uint32 timeout) public
    onlyOwner
    {
       
        GameRoundData.extraData[5] = timeout;
        
        emit onChangeTimeout( timeout );
         
    }
    
    function enableMaintenance() public
    onlyOwner
    {
        maintenanceMode = true;
        
        emit onMaintenance( maintenanceMode , now);
        
    }

    function disableMaintenance() public
    onlyOwner
    {
      
        maintenanceMode = false;
        
        emit onMaintenance( maintenanceMode , now);
        
       
      
    }
    
  
    function changeMinimumPrice( uint256 newmini) public
    onlyOwner
    {
      
      if (newmini>0)
      {
          minimumSharePrice = newmini;
      }
       
      emit onChangeMinimumPrice( newmini , now ); 
    }
    
    
      
    
    struct PlayerData_s
    {
   
        uint256 chest;  
        uint256 payoutsTo;
       
		 
		uint256 lockedCredit;	
		
        uint256         torpedoBatchID;         
        uint256         torpedoBatchBlockTimeout;   

		uint32[1]		packedData;		 
						
    }
    
    
    struct GameRoundData_s
    {
	   
	   uint256				jackpotAmount;
	   uint256				treasureAmount;
	   address				currentJackpotWinner;
	          
       uint256              hdx20AppreciationPayout;
       uint256              devAppreciationPayout;
	   
        
	   
	   uint32[6]			extraData;		 
											 
											 
			                                 
	                                         
	                                         
  
    }
      
   
    mapping (address => PlayerData_s)   private PlayerData;
       
    GameRoundData_s   private GameRoundData;
    
    mapping( address => bytes32) private registeredNames;
       
    bool        private maintenanceMode=false;     
    
    uint8 constant private HDX20BuyFees = 5;
     
    uint8 constant private DevFees = 5;
	uint8 constant private AppreciationFees = 15;		
	uint8 constant private JackpotAppreciation = 16;
	uint8 constant private TreasureAppreciation = 64;
   
    uint256 constant internal magnitude = 1e18;
     
    uint256 private minimumSharePrice = 0.01 ether;
    
    uint256 private blockTimeAverage = 15;                


    uint256 constant thresholdForAppreciation = 0.05 ether;
      
     
    
     
    
     function()
     payable
     public
     onlyFromHDXToken 
    {
       
      
      
          
    }
    
    
    function ChargeTreasure() public payable
    {
		uint256 _val = msg.value;
		
		GameRoundData.jackpotAmount = GameRoundData.jackpotAmount.add( _val.mul( 20 ) / 100 );
		
		GameRoundData.treasureAmount = GameRoundData.treasureAmount.add( _val.mul( 80 ) / 100 );
				   
    }
	
	function AddJackpotTreasure( uint256 _val ) private
	{
		 
		GameRoundData.jackpotAmount = GameRoundData.jackpotAmount.add( _val.mul( JackpotAppreciation ) / 100 );
		
		GameRoundData.treasureAmount = GameRoundData.treasureAmount.add( _val.mul( TreasureAppreciation ) / 100 );
		
		 
		
		uint256 _appreciation = SafeMath.mul( _val , AppreciationFees) / 100; 
          
        uint256 _dev = SafeMath.mul( _val , DevFees) / 100;  
		
		_dev = _dev.add( GameRoundData.devAppreciationPayout );
		
		if (_dev>= thresholdForAppreciation )
		{
			GameRoundData.devAppreciationPayout = 0;
			
			HDXcontract.buyTokenFromGame.value( _dev )( owner , address(0));	
		}
		else
		{
			 GameRoundData.devAppreciationPayout = _dev;
		}
	
		_appreciation = _appreciation.add( GameRoundData.hdx20AppreciationPayout );
		
		if (_appreciation>= thresholdForAppreciation)
		{
			GameRoundData.hdx20AppreciationPayout = 0;
			
			HDXcontract.appreciateTokenPrice.value( _appreciation )();
		}
		else
		{
			GameRoundData.hdx20AppreciationPayout = _appreciation;
		}
		
	}
	
    
    
    
    function ValidTorpedoScore( int256 score, uint256 torpedoBatchID , bytes32 r , bytes32 s , uint8 v) public
    onlyDirectTransaction
    {
        address _customer_address = msg.sender;
         
        require( maintenanceMode==false);
  
        GameVar_s memory gamevar;
        gamevar.score = score;
        gamevar.torpedoBatchID = torpedoBatchID;
        gamevar.r = r;
        gamevar.s = s;
        gamevar.v = v;
   
        coreValidTorpedoScore( _customer_address , gamevar  );
    }
    
    
    struct GameVar_s
    {
     
        bool madehigh;
              
               
        uint256  torpedoBatchID;
       
 	    int256   score;
		uint256  scoreMultiplied;
		
		uint32   multiplier;
		
        bytes32  r;
        bytes32  s;
        uint8    v;
    }
    
	function payJackpot() private
	{
		address _winner = GameRoundData.currentJackpotWinner;
		uint256 _j = GameRoundData.jackpotAmount;
		
		
		if (_winner != address(0))
		{
			PlayerData[ _winner ].chest = PlayerData[ _winner ].chest.add( _j ); 
		
		
    		GameRoundData.currentJackpotWinner = address(0);
    		GameRoundData.jackpotAmount = 0;
    		 
    		GameRoundData.extraData[1] = 0;
    		 
    		GameRoundData.extraData[0] = 0;
    		
    		emit onJackpotWin( _winner , _j  );
		}
		
	}
  
    
    function coreValidTorpedoScore( address _player_address , GameVar_s gamevar) private
    {
    
        PlayerData_s storage  _PlayerData = PlayerData[ _player_address];
                
        require((gamevar.torpedoBatchID != 0) && (gamevar.torpedoBatchID == _PlayerData.torpedoBatchID) && ( _PlayerData.lockedCredit>0 ));
                
        gamevar.madehigh = false;

	
        if (block.number>=_PlayerData.torpedoBatchBlockTimeout || (ecrecover(keccak256(abi.encodePacked( gamevar.score,gamevar.torpedoBatchID )) , gamevar.v, gamevar.r, gamevar.s) != signerAuthority))
        {
            gamevar.score = 0;
        }
		
		if (gamevar.score<0) gamevar.score = 0;
				            
        gamevar.scoreMultiplied = uint256(gamevar.score) * uint256(_PlayerData.packedData[0]);
        
        if (gamevar.score>0xffffffff) gamevar.score = 0xffffffff;
        if (gamevar.scoreMultiplied>0xffffffff) gamevar.scoreMultiplied = 0xffffffff;
   		
		 
		if (gamevar.scoreMultiplied > uint256( GameRoundData.extraData[0] ))
		{
			GameRoundData.extraData[0] = uint32( gamevar.scoreMultiplied );
			
			GameRoundData.currentJackpotWinner = _player_address;
			
 			gamevar.madehigh = true;
			 
		}
		
		 
		 GameRoundData.extraData[1]++;
		
		 
		if (GameRoundData.extraData[1]>=GameRoundData.extraData[3])
		{
			payJackpot();
		}
		
	
		 
		
		uint256 _winning =0;
		uint256 _average = uint256( GameRoundData.extraData[2]);
		uint256 _top = _average *2;
		
		uint256 _score = uint256(gamevar.score);
		
		if (_score >=_average )
		{
			 
			
			_winning = _PlayerData.lockedCredit;
			
			 
					
			if (_score > _top) _score = _top;
		
			_score -= _average;
						
			uint256 _gains = GameRoundData.treasureAmount.mul( _score * uint256( _PlayerData.packedData[0] )) / 100;
			
			_gains /= (1+(_top - _average));
			
			
			 
			GameRoundData.treasureAmount = GameRoundData.treasureAmount.sub( _gains );
									
			_winning = _winning.add( _gains );
		}
		else
		{
			 
		
			if (_average>0)
			{
				_winning = _PlayerData.lockedCredit.mul( _score ) / _average;
			}
		}
		
		 
		_PlayerData.chest = _PlayerData.chest.add( _winning );
		
		
		 
		
		if (_PlayerData.lockedCredit> _winning)
		{
			
			AddJackpotTreasure( _PlayerData.lockedCredit - _winning );
		}
		
		 
				
		_score = uint256(gamevar.score);
		
		uint32 maximumScore = GameRoundData.extraData[4];
		
		
		 
		if (_score>_average/3)
		{
			_score = _score.add( _average * 99 );
			_score /= 100;
			
			if (_score< maximumScore/8 ) _score = maximumScore/8;
			if (_score > maximumScore/2) _score = maximumScore/2;
			
			GameRoundData.extraData[2] = uint32( _score );
		}

		 
   
         
        _PlayerData.torpedoBatchID = 0;
        _PlayerData.lockedCredit = 0;
		
        emit onNewScore( gamevar.scoreMultiplied , _player_address , gamevar.madehigh , _winning , _PlayerData.packedData[0] );


    }
    
    
    function BuyTorpedoWithDividends( uint256 eth , int256 score, uint256 torpedoBatchID,  address _referrer_address , bytes32 r , bytes32 s , uint8 v) public
    onlyDirectTransaction
    {
        
        require( maintenanceMode==false  && (eth==minimumSharePrice || eth==minimumSharePrice*10 || eth==minimumSharePrice*100) );
  
        address _customer_address = msg.sender;
        
        GameVar_s memory gamevar;
        gamevar.score = score;
        gamevar.torpedoBatchID = torpedoBatchID;
        gamevar.r = r;
        gamevar.s = s;
        gamevar.v = v;
        
      
        gamevar.multiplier =uint32( eth / minimumSharePrice);
        
        eth = HDXcontract.payWithToken( eth , _customer_address );
       
        require( eth>0 );
        
         
        CoreBuyTorpedo( _customer_address , eth , _referrer_address , gamevar );
        
       
    }
    
    function BuyName( bytes32 name ) public payable
    {
        address _customer_address = msg.sender;
        uint256 eth = msg.value; 
        
        require( maintenanceMode==false  && (eth==minimumSharePrice*10));
        
         
         
        
        eth /= 2;
        
        HDXcontract.buyTokenFromGame.value( eth )( owner , address(0));
       
        HDXcontract.appreciateTokenPrice.value( eth )();
        
        registeredNames[ _customer_address ] = name;
        
        emit onNewName( _customer_address , name , now );
    }
    
    function BuyTorpedo( int256 score, uint256 torpedoBatchID, address _referrer_address , bytes32 r , bytes32 s , uint8 v ) public payable
    onlyDirectTransaction
    {
     
        address _customer_address = msg.sender;
        uint256 eth = msg.value;
        
        require( maintenanceMode==false  && (eth==minimumSharePrice || eth==minimumSharePrice*10 || eth==minimumSharePrice*100));
   
        GameVar_s memory gamevar;
        gamevar.score = score;
        gamevar.torpedoBatchID = torpedoBatchID;
        gamevar.r = r;
        gamevar.s = s;
        gamevar.v = v;
        
       
        gamevar.multiplier =uint32( eth / minimumSharePrice);
   
        CoreBuyTorpedo( _customer_address , eth , _referrer_address, gamevar);
     
    }
    
     
    
    function CoreBuyTorpedo( address _player_address , uint256 eth ,  address _referrer_address , GameVar_s gamevar) private
    {
    
        PlayerData_s storage  _PlayerData = PlayerData[ _player_address];
            
        
         
        if (gamevar.torpedoBatchID !=0 || _PlayerData.torpedoBatchID !=0)
        {
             coreValidTorpedoScore( _player_address , gamevar);
        }
        
        
         
        
        _PlayerData.packedData[0] = gamevar.multiplier;
        _PlayerData.torpedoBatchBlockTimeout = block.number + (uint256(GameRoundData.extraData[5]) / blockTimeAverage);
        _PlayerData.torpedoBatchID = uint256((keccak256(abi.encodePacked( block.number, _player_address , address(this)))));
        
        
         
        uint256 _tempo = (eth.mul(HDX20BuyFees)) / 100;
		
		_PlayerData.lockedCredit =  eth - _tempo;	 
		        
        uint256 _nb_token =   HDXcontract.buyTokenFromGame.value( _tempo )( _player_address , _referrer_address);
        
        
        emit onBuyTorpedo( _player_address, _PlayerData.torpedoBatchID , _PlayerData.torpedoBatchBlockTimeout, _nb_token,  _PlayerData.packedData[0]);
            
        
    }
    
   
    
    function get_Gains(address _player_address) private view
    returns( uint256)
    {
       
        uint256 _gains = PlayerData[ _player_address ].chest;
        
        if (_gains > PlayerData[ _player_address].payoutsTo)
        {
            _gains -= PlayerData[ _player_address].payoutsTo;
        }
        else _gains = 0;
     
    
        return( _gains );
        
    }
    
    
    function WithdrawGains() public 
   
    {
        address _customer_address = msg.sender;
        
        uint256 _gains = get_Gains( _customer_address );
        
        require( _gains>0);
        
        PlayerData[ _customer_address ].payoutsTo = PlayerData[ _customer_address ].payoutsTo.add( _gains );
        
      
        emit onWithdrawGains( _customer_address , _gains , now);
        
        _customer_address.transfer( _gains );
        
        
    }
    
   
    
   
   
  
  
    
      
  
    
    function view_get_Treasure() public
    view
    returns(uint256)
    {
      
      return( GameRoundData.treasureAmount );  
    }
	
	function view_get_Jackpot() public
    view
    returns(uint256)
    {
      
      return( GameRoundData.jackpotAmount );  
    }
 
    function view_get_gameData() public
    view
    returns( uint256 treasure,
			 uint256 jackpot,
			 uint32  highscore ,
			 address highscore_address ,
			 bytes32 highscore_name,
			 uint32  highscore_turn,
			 uint32  score_average,
			 uint256 torpedoBatchID ,
			 uint32 torpedoBatchMultiplier ,
			 uint256 torpedoBatchBlockTimeout   )
    {
        address _player_address = msg.sender;
		
		treasure = GameRoundData.treasureAmount;
		jackpot = GameRoundData.jackpotAmount;
		highscore = GameRoundData.extraData[0];
		highscore_address = GameRoundData.currentJackpotWinner;
		highscore_name = view_get_registeredNames( GameRoundData.currentJackpotWinner  );
		highscore_turn = GameRoundData.extraData[1];
		score_average = GameRoundData.extraData[2];
		      
        torpedoBatchID = PlayerData[_player_address].torpedoBatchID;
        torpedoBatchMultiplier = PlayerData[_player_address].packedData[0];
        torpedoBatchBlockTimeout = PlayerData[_player_address].torpedoBatchBlockTimeout;
       
    }
  
       
  
    
    function view_get_Gains()
    public
    view
    returns( uint256 gains)
    {
        
        address _player_address = msg.sender;
   
      
        uint256 _gains = PlayerData[ _player_address ].chest;
        
        if (_gains > PlayerData[ _player_address].payoutsTo)
        {
            _gains -= PlayerData[ _player_address].payoutsTo;
        }
        else _gains = 0;
     
    
        return( _gains );
        
    }
  
  
    
    function view_get_gameStates() public 
    view
    returns( uint256 minimumshare ,
		     uint256 blockNumberCurrent ,
			 uint256 blockTimeAvg ,
			 uint32  highscore ,
			 address highscore_address ,
			 bytes32 highscore_name,
			 uint32  highscore_turn,
			 uint256 jackpot,
			 bytes32 myname,
			 uint32  jackpotCycle)
    {
       
        
        return( minimumSharePrice ,  block.number , blockTimeAverage , GameRoundData.extraData[0] , GameRoundData.currentJackpotWinner , view_get_registeredNames( GameRoundData.currentJackpotWinner  ) , GameRoundData.extraData[1] , GameRoundData.jackpotAmount,  view_get_registeredNames(msg.sender) , GameRoundData.extraData[3]);
    }
    
    function view_get_pendingHDX20Appreciation()
    public
    view
    returns(uint256)
    {
        return GameRoundData.hdx20AppreciationPayout;
    }
    
    function view_get_pendingDevAppreciation()
    public
    view
    returns(uint256)
    {
        return GameRoundData.devAppreciationPayout;
    }
  
 
 
    function totalEthereumBalance()
    public
    view
    returns(uint256)
    {
        return address(this).balance;
    }
    
    function view_get_maintenanceMode()
    public
    view
    returns(bool)
    {
        return( maintenanceMode);
    }
    
    function view_get_blockNumbers()
    public
    view
    returns( uint256 b1 )
    {
        return( block.number);
        
    }
    
    function view_get_registeredNames(address _player)
    public
    view
    returns( bytes32)
    {
        
        return( registeredNames[ _player ]);
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


library SafeMath128 {
    
   
    function mul(uint128 a, uint128 b) 
        internal 
        pure 
        returns (uint128 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

   
    function sub(uint128 a, uint128 b)
        internal
        pure
        returns (uint128) 
    {
        require(b <= a);
        return a - b;
    }

   
    function add(uint128 a, uint128 b)
        internal
        pure
        returns (uint128 c) 
    {
        c = a + b;
        require(c >= a);
        return c;
    }
    
   
    
  
    
   
}