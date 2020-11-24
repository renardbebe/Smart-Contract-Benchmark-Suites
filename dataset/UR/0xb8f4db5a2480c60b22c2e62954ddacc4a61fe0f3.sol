 

 
 
 
 

 

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract synthMainInterface{
    function minimumDepositAmount (  ) external view returns ( uint256 );
  function exchangeEtherForSynthsAtRate ( uint256 guaranteedRate ) external payable returns ( uint256 );
  function synthsReceivedForEther ( uint256 amount ) external view returns ( uint256 );
  function synth (  ) external view returns ( address );
  function exchangeSynthsForSynthetix ( uint256 synthAmount ) external returns ( uint256 );
  function nominateNewOwner ( address _owner ) external;
  function setPaused ( bool _paused ) external;
  function initiationTime (  ) external view returns ( uint256 );
  function exchangeEtherForSynths (  ) external payable returns ( uint256 );
  function setSelfDestructBeneficiary ( address _beneficiary ) external;
  function fundsWallet (  ) external view returns ( address );
  function priceStalePeriod (  ) external view returns ( uint256 );
  function setPriceStalePeriod ( uint256 _time ) external;
  function terminateSelfDestruct (  ) external;
  function setSynth ( address _synth ) external;
  function pricesAreStale (  ) external view returns ( bool );
  function updatePrices ( uint256 newEthPrice, uint256 newSynthetixPrice, uint256 timeSent ) external;
  function lastPriceUpdateTime (  ) external view returns ( uint256 );
  function totalSellableDeposits (  ) external view returns ( uint256 );
  function nominatedOwner (  ) external view returns ( address );
  function exchangeSynthsForSynthetixAtRate ( uint256 synthAmount, uint256 guaranteedRate ) external returns ( uint256 );
  function paused (  ) external view returns ( bool );
  function setFundsWallet ( address _fundsWallet ) external;
  function depositStartIndex (  ) external view returns ( uint256 );
  function synthetix (  ) external view returns ( address );
  function acceptOwnership (  ) external;
  function exchangeEtherForSynthetix (  ) external payable returns ( uint256 );
  function setOracle ( address _oracle ) external;
  function exchangeEtherForSynthetixAtRate ( uint256 guaranteedEtherRate, uint256 guaranteedSynthetixRate ) external payable returns ( uint256 );
  function oracle (  ) external view returns ( address );
  function withdrawMyDepositedSynths (  ) external;
  function owner (  ) external view returns ( address );
  function lastPauseTime (  ) external view returns ( uint256 );
  function selfDestruct (  ) external;
  function synthetixReceivedForSynths ( uint256 amount ) external view returns ( uint256 );
  function SELFDESTRUCT_DELAY (  ) external view returns ( uint256 );
  function setMinimumDepositAmount ( uint256 _amount ) external;
  function feePool (  ) external view returns ( address );
  function deposits ( uint256 ) external view returns ( address user, uint256 amount );
  function selfDestructInitiated (  ) external view returns ( bool );
  function usdToEthPrice (  ) external view returns ( uint256 );
  function initiateSelfDestruct (  ) external;
  function tokenFallback ( address from, uint256 amount, bytes data ) external returns ( bool );
  function selfDestructBeneficiary (  ) external view returns ( address );
  function smallDeposits ( address ) external view returns ( uint256 );
  function synthetixReceivedForEther ( uint256 amount ) external view returns ( uint256 );
  function depositSynths ( uint256 amount ) external;
  function withdrawSynthetix ( uint256 amount ) external;
  function usdToSnxPrice (  ) external view returns ( uint256 );
  function ORACLE_FUTURE_LIMIT (  ) external view returns ( uint256 );
  function depositEndIndex (  ) external view returns ( uint256 );
  function setSynthetix ( address _synthetix ) external;
}

contract synthConvertInterface{
    function name (  ) external view returns ( string );
  function setGasPriceLimit ( uint256 _gasPriceLimit ) external;
  function approve ( address spender, uint256 value ) external returns ( bool );
  function removeSynth ( bytes32 currencyKey ) external;
  function issueSynths ( bytes32 currencyKey, uint256 amount ) external;
  function mint (  ) external returns ( bool );
  function setIntegrationProxy ( address _integrationProxy ) external;
  function nominateNewOwner ( address _owner ) external;
  function initiationTime (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function setFeePool ( address _feePool ) external;
  function exchange ( bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress ) external returns ( bool );
  function setSelfDestructBeneficiary ( address _beneficiary ) external;
  function transferFrom ( address from, address to, uint256 value ) external returns ( bool );
  function decimals (  ) external view returns ( uint8 );
  function synths ( bytes32 ) external view returns ( address );
  function terminateSelfDestruct (  ) external;
  function rewardsDistribution (  ) external view returns ( address );
  function exchangeRates (  ) external view returns ( address );
  function nominatedOwner (  ) external view returns ( address );
  function setExchangeRates ( address _exchangeRates ) external;
  function effectiveValue ( bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey ) external view returns ( uint256 );
  function transferableSynthetix ( address account ) external view returns ( uint256 );
  function validateGasPrice ( uint256 _givenGasPrice ) external view;
  function balanceOf ( address account ) external view returns ( uint256 );
  function availableCurrencyKeys (  ) external view returns ( bytes32[] );
  function acceptOwnership (  ) external;
  function remainingIssuableSynths ( address issuer, bytes32 currencyKey ) external view returns ( uint256 );
  function availableSynths ( uint256 ) external view returns ( address );
  function totalIssuedSynths ( bytes32 currencyKey ) external view returns ( uint256 );
  function addSynth ( address synth ) external;
  function owner (  ) external view returns ( address );
  function setExchangeEnabled ( bool _exchangeEnabled ) external;
  function symbol (  ) external view returns ( string );
  function gasPriceLimit (  ) external view returns ( uint256 );
  function setProxy ( address _proxy ) external;
  function selfDestruct (  ) external;
  function integrationProxy (  ) external view returns ( address );
  function setTokenState ( address _tokenState ) external;
  function collateralisationRatio ( address issuer ) external view returns ( uint256 );
  function rewardEscrow (  ) external view returns ( address );
  function SELFDESTRUCT_DELAY (  ) external view returns ( uint256 );
  function collateral ( address account ) external view returns ( uint256 );
  function maxIssuableSynths ( address issuer, bytes32 currencyKey ) external view returns ( uint256 );
  function transfer ( address to, uint256 value ) external returns ( bool );
  function synthInitiatedExchange ( address from, bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 value, bytes data ) external returns ( bool );
  function feePool (  ) external view returns ( address );
  function selfDestructInitiated (  ) external view returns ( bool );
  function setMessageSender ( address sender ) external;
  function initiateSelfDestruct (  ) external;
  function transfer ( address to, uint256 value, bytes data ) external returns ( bool );
  function supplySchedule (  ) external view returns ( address );
  function selfDestructBeneficiary (  ) external view returns ( address );
  function setProtectionCircuit ( bool _protectionCircuitIsActivated ) external;
  function debtBalanceOf ( address issuer, bytes32 currencyKey ) external view returns ( uint256 );
  function synthetixState (  ) external view returns ( address );
  function availableSynthCount (  ) external view returns ( uint256 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function escrow (  ) external view returns ( address );
  function tokenState (  ) external view returns ( address );
  function burnSynths ( bytes32 currencyKey, uint256 amount ) external;
  function proxy (  ) external view returns ( address );
  function issueMaxSynths ( bytes32 currencyKey ) external;
  function exchangeEnabled (  ) external view returns ( bool );
}





library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

   
    contract Portfolio1 {

       
       synthMainInterface sInt = synthMainInterface(0x172e09691dfbbc035e37c73b62095caa16ee2388);

       synthConvertInterface sIntJPY = synthConvertInterface(0x42d03f506c2308ecd06ae81d8fa22352bc7a8f2b);
       synthConvertInterface sIntEUR = synthConvertInterface(0xc011a72400e58ecd99ee497cf89e3775d4bd732f);
        synthConvertInterface sIntCHF = synthConvertInterface(0xc011a72400e58ecd99ee497cf89e3775d4bd732f);
         synthConvertInterface sIntGBP = synthConvertInterface(0xc011a72400e58ecd99ee497cf89e3775d4bd732f);
       
       

       address jpyTokenAddress = 0xf6b1c627e95bfc3c1b4c9b825a032ff0fbf3e07d;
       address eurTokenAddress = 0xd71ecff9342a5ced620049e616c5035f1db98620;
       address chfTokenAddress = 0x0f83287ff768d1c1e17a42f44d644d7f22e8ee1d;
       address gbpTokenAddress = 0x97fe22e7341a0cd8db6f6c021a24dc8f4dad855f;
       address usdTokenAddress = 0x57ab1e02fee23774580c119740129eac7081e9d3;

       ERC20 jpyToken = ERC20(jpyTokenAddress);
       ERC20 eurToken = ERC20(eurTokenAddress);
       ERC20 chfToken = ERC20(chfTokenAddress);
       ERC20 gbpToken = ERC20(gbpTokenAddress);
       ERC20 usdToken = ERC20(usdTokenAddress);

      
         
        bytes32 sourceKey= 0x7355534400000000000000000000000000000000000000000000000000000000;

         
        bytes32 destKeyJPY = 0x734a505900000000000000000000000000000000000000000000000000000000;


          
        bytes32 destKeyEUR = 0x7345555200000000000000000000000000000000000000000000000000000000;

          
        bytes32 destKeyCHF = 0x7343484600000000000000000000000000000000000000000000000000000000;


          
        bytes32 destKeyGBP = 0x7347425000000000000000000000000000000000000000000000000000000000;



    
        uint256 sUSDBack = 0;

        using SafeMath for uint256;
        
       
    

       
        function () payable{

          buyPackage();
          
        }
        
        
        function getLastUSDBack() constant returns (uint256){
            return sUSDBack;
        }

       


        function buyPackage() payable returns(bool){

         


           
            uint256 amountEthUsing = msg.value;
            
            

            sUSDBack= sInt.exchangeEtherForSynths.value(amountEthUsing)();

            uint256 usdPortion = sUSDBack.mul(42).div(100);
            uint256 eurPortion = sUSDBack.mul(32).div(100);
            uint256 chfPortion = sUSDBack.mul(11).div(100);
            uint256 jpyPortion = sUSDBack.mul(8).div(100);
            uint256 gbpPortion = sUSDBack.mul(7).div(100);


            sIntEUR.exchange(sourceKey, eurPortion, destKeyEUR, this);
            sIntCHF.exchange(sourceKey, chfPortion, destKeyCHF, this);
            sIntJPY.exchange(sourceKey, jpyPortion, destKeyJPY, this);
            sIntGBP.exchange(sourceKey, gbpPortion, destKeyGBP, this);

           
            uint256 amountUSD= usdToken.balanceOf(this);
            usdToken.transfer(msg.sender, amountUSD);

            uint256 amountEUR = eurToken.balanceOf(this);
            eurToken.transfer(msg.sender, amountEUR);

            uint256 amountCHF = chfToken.balanceOf(this);
            chfToken.transfer(msg.sender, amountCHF);

            uint256 amountJPY = jpyToken.balanceOf(this);
            jpyToken.transfer(msg.sender, amountJPY);

            uint256 amountGBP = gbpToken.balanceOf(this);
            gbpToken.transfer(msg.sender, amountGBP);


            return true;

        }
}