 

pragma solidity ^0.4.24;

 


contract BCHIPReceivingContract {
   
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
 
}


contract BCHIPInterface 
{

    
    
    function transfer(address _to, uint _value) public returns (bool);
     
    function transferAndCall(address _sender, uint _value, bytes _data) public returns(bool);
    function balanceOf(address _customerAddress) public returns(bool);
}

contract BLUECHIPBONDS is BCHIPReceivingContract {
     
   


    modifier onlyOwner(){
        
        require(msg.sender == dev);
        _;
    }

    
    modifier onlyActive(){
        
        require(boolContractActive);
        _;
    }

    modifier allowPlayer(){
        
        require(boolAllowPlayer);
        _;
    }
    

     
    event onBondBuy(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 bond,
        uint256 newPrice,
        uint256 halfLifeTime
    );
    
    event onWithdrawETH(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

      event onWithdrawTokens(
        address customerAddress,
        uint256 ethereumWithdrawn
    );
    
     
    event transferBondEvent(
        address from,
        address to,
        uint256 bond
    );

      
    event Halflife(
        uint bond,
        uint price,
        uint newBlockTime
    );


    
     
    string public name = "BLUECHIPBONDS";
    string public symbol = "BLU";

    

    uint8 constant public referralRate = 5; 

    uint8 constant public decimals = 18;
  
    uint public totalBondValue = 17000e18;

    uint public totalOwnerAccounts = 0;

    uint constant dayBlockFactor = 21600;

    uint contractETH = 0;

    
    
    
    mapping(uint => address) internal bondOwner;
    mapping(uint => uint) public bondPrice;
    mapping(uint => uint) public basePrice;
    mapping(uint => uint) internal bondPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalBondDivs;
    mapping(uint => uint) internal totalBondDivsETH;
    mapping(uint => string) internal bondName;

    mapping(uint => uint) internal bondBlockNumber;

    mapping(address => uint) internal ownerAccountsETH;

    uint bondPriceIncrement = 125;    
    uint totalDivsProduced = 0;

    uint public maxBonds = 200;
    
    uint public initialPrice = 170e18;    

    uint public nextAvailableBond;

    bool allowReferral = false;

    bool allowAutoNewBond = false;

    uint8 public devDivRate = 5;
    uint8 public ownerDivRate = 50;
    uint8 public distDivRate = 45;

    uint public bondFund = 0;

    address public exchangeContract;

    address public bankRoll;

    uint contractBalance = 0;

    BCHIPInterface public BCHIPTOKEN;
   
    address dev;

    uint256 internal tokenSupply_ = 0;

    uint public halfLifeTime = 5900;    
    uint public halfLifeRate = 90;    

    bool public allowHalfLife = false;

    bool public allowLocalBuy = true;
    bool public allowPriceLower = false;

    bool public boolContractActive = true;

    bool public boolAllowPlayer = false;


     
    address add2 = 0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61;

    


     
     
    constructor(address _exchangeAddress, address _bankRollAddress)
        public
    {

        BCHIPTOKEN = BCHIPInterface(_exchangeAddress);
        exchangeContract = _exchangeAddress;

         
        bankRoll = _bankRollAddress;





        dev = msg.sender;
        nextAvailableBond = 23;

        bondOwner[1] = dev;
        bondPrice[1] = 1500e18;
        basePrice[1] = bondPrice[1];
        bondPreviousPrice[1] = 0;

        bondOwner[2] = dev;
        bondPrice[2] = 1430e18;
        basePrice[2] = bondPrice[2];
        bondPreviousPrice[2] = 0;

        bondOwner[3] = dev;
        bondPrice[3] = 1360e18;
        basePrice[3] = bondPrice[3];
        bondPreviousPrice[3] = 0;

        bondOwner[4] = dev;
        bondPrice[4] = 1290e18;
        basePrice[4] = bondPrice[4];
        bondPreviousPrice[4] = 0;

        bondOwner[5] = dev;
        bondPrice[5] = 1220e18;
        basePrice[5] = bondPrice[5];
        bondPreviousPrice[5] = 0;

        bondOwner[6] = dev;
        bondPrice[6] = 1150e18;
        basePrice[6] = bondPrice[6];
        bondPreviousPrice[6] = 0;

        bondOwner[7] = dev;
        bondPrice[7] = 1080e18;
        basePrice[7] = bondPrice[7];
        bondPreviousPrice[7] = 0;

        bondOwner[8] = dev;
        bondPrice[8] = 1010e18;
        basePrice[8] = bondPrice[8];
        bondPreviousPrice[8] = 0;

        bondOwner[9] = dev;
        bondPrice[9] = 940e18;
        basePrice[9] = bondPrice[9];
        bondPreviousPrice[9] = 0;

        bondOwner[10] = add2;
        bondPrice[10] = 870e18;
        basePrice[10] = bondPrice[10];
        bondPreviousPrice[10] = 0;

        bondOwner[11] = dev;
        bondPrice[11] = 800e18;
        basePrice[11] = bondPrice[11];
        bondPreviousPrice[11] = 0;

        bondOwner[12] = dev;
        bondPrice[12] = 730e18;
        basePrice[12] = bondPrice[12];
        bondPreviousPrice[12] = 0;

        bondOwner[13] = dev;
        bondPrice[13] = 660e18;
        basePrice[13] = bondPrice[13];
        bondPreviousPrice[13] = 0;

        bondOwner[14] = dev;
        bondPrice[14] = 590e18;
        basePrice[14] = bondPrice[14];
        bondPreviousPrice[14] = 0;

        bondOwner[15] = dev;
        bondPrice[15] = 520e18;
        basePrice[15] = bondPrice[15];
        bondPreviousPrice[15] = 0;

        bondOwner[16] = dev;
        bondPrice[16] = 450e18;
        basePrice[16] = bondPrice[16];
        bondPreviousPrice[16] = 0;

        bondOwner[17] = dev;
        bondPrice[17] = 380e18;
        basePrice[17] = bondPrice[17];
        bondPreviousPrice[17] = 0;

        bondOwner[18] = dev;
        bondPrice[18] = 310e18;
        basePrice[18] = bondPrice[18];
        bondPreviousPrice[18] = 0;

        bondOwner[19] = dev;
        bondPrice[19] = 240e18;
        basePrice[19] = bondPrice[19];
        bondPreviousPrice[19] = 0;

        bondOwner[20] = dev;
        bondPrice[20] = 170e18;
        basePrice[20] = bondPrice[20];
        bondPreviousPrice[20] = 0;

        bondOwner[21] = dev;
        bondPrice[21] = 150e18;
        basePrice[21] = bondPrice[21];
        bondPreviousPrice[21] = 0;

        bondOwner[22] = dev;
        bondPrice[22] = 150e18;
        basePrice[22] = bondPrice[22];
        bondPreviousPrice[22] = 0;

        getTotalBondValue();
       

    }



         
      

    function()
        payable
        public
    {
        
    }



      
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool) {
        require(msg.sender == exchangeContract);
        if (_from == bankRoll) {  
         
            contractBalance = SafeMath.add(contractBalance,_value);


            return true;

        } else {
    
             
             
            ownerAccounts[_from] = SafeMath.add(ownerAccounts[_from],_value);


        }

        return true;
    }


    
     
     
     
     

     
     
     


     

     
    
     
     
     
     

     

     
     

     
    function localBuy(uint _bond, address _from, address _referrer)
        public
        onlyActive()
    {
         
            require(_bond <= nextAvailableBond);
            require(ownerAccounts[_from] >= bondPrice[_bond]);
            _from = msg.sender;

            ownerAccounts[_from] = SafeMath.sub(ownerAccounts[_from],bondPrice[_bond]);
            buy(_bond, bondPrice[_bond], _from, _referrer, msg.sender);
         
    }

    
    function buy(uint _bond, uint _value, address _from, address _referrer, address _sender)
        internal
        onlyActive()
    {
        require(_bond <= nextAvailableBond);
        require(_value >= bondPrice[_bond]);
         

        
        bondBlockNumber[_bond] = block.number;    

         

          
        uint _baseDividends = _value - bondPreviousPrice[_bond];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

         
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),100);

        totalBondDivs[_bond] = SafeMath.add(totalBondDivs[_bond],_ownerDividends);
        _ownerDividends = SafeMath.add(_ownerDividends,bondPreviousPrice[_bond]);
            
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends,distDivRate),100);

        if (allowReferral && (_referrer != _sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
                
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends,referralRate),100);
            _distDividends = SafeMath.sub(_distDividends,_referralDividends);
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer],_referralDividends);
        }
            


         
        address _previousOwner = bondOwner[_bond];
        address _newOwner = _sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner],_ownerDividends);
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev],SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),100));

        bondOwner[_bond] = _newOwner;

        distributeYield(_distDividends);
        distributeBondFund();
         
        bondPreviousPrice[_bond] = _value;
        bondPrice[_bond] = SafeMath.div(SafeMath.mul(_value,bondPriceIncrement),100);
         
        
        getTotalBondValue();
        getTotalOwnerAccounts();
        emit onBondBuy(_sender, _value, _bond, SafeMath.div(SafeMath.mul(_value,bondPriceIncrement),100), halfLifeTime);
     
    }

    function distributeYield(uint _distDividends) internal
     
    {
        uint counter = 1;
        uint currentBlock = block.number;

        while (counter < nextAvailableBond) { 

            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_distDividends, bondPrice[counter]),totalBondValue);
            ownerAccounts[bondOwner[counter]] = SafeMath.add(ownerAccounts[bondOwner[counter]],_distAmountLocal);
            totalBondDivs[counter] = SafeMath.add(totalBondDivs[counter],_distAmountLocal);


              
            if (allowHalfLife) {

                if (bondPrice[counter] > basePrice[counter]) {
                    uint _life = SafeMath.sub(currentBlock, bondBlockNumber[counter]);

                     
                    if (_life > halfLifeTime) {
                    
                        bondBlockNumber[counter] = currentBlock;   
                        if (SafeMath.div(SafeMath.mul(bondPrice[counter], halfLifeRate),100) < basePrice[counter]){
                            
                             
                            bondPrice[counter] = basePrice[counter];
                            
                        }else{

                            bondPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter], halfLifeRate),100);  
                            bondPreviousPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter],75),100);

                        }

                        emit Halflife(counter,  bondPrice[counter], halfLifeTime);

                    }
                     


                }
               
            }
            
            counter = counter + 1;
        } 
        getTotalBondValue();
        getTotalOwnerAccounts();

    }

    function checkHalfLife() public
    
     
    {

        bool _boolDev = (msg.sender == dev);
        if (_boolDev || boolAllowPlayer){

        
        uint counter = 1;
        uint currentBlock = block.number;

        while (counter < nextAvailableBond) { 

             
            if (allowHalfLife) {

                if (bondPrice[counter] > basePrice[counter]) {
                    uint _life = SafeMath.sub(currentBlock, bondBlockNumber[counter]);

                     
                    if (_life > halfLifeTime) {
                    
                        bondBlockNumber[counter] = currentBlock;   
                        if (SafeMath.div(SafeMath.mul(bondPrice[counter], halfLifeRate),100) < basePrice[counter]){
                            
                             
                            bondPrice[counter] = basePrice[counter];
                            
                        }else{

                            bondPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter], halfLifeRate),100);  
                            bondPreviousPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter],75),100);

                        }

                        
                        
                        emit Halflife(counter,  bondPrice[counter], halfLifeTime);

                    }
                     


                }
               
            }
            
            
            counter = counter + 1;
        } 
        getTotalBondValue();
        getTotalOwnerAccounts();

        }

    }
    
    function distributeBondFund() internal
     

    {
        if(bondFund > 0){
            uint counter = 1;

            while (counter < nextAvailableBond) { 

                uint _distAmountLocal = SafeMath.div(SafeMath.mul(bondFund, bondPrice[counter]),totalBondValue);
                ownerAccountsETH[bondOwner[counter]] = SafeMath.add(ownerAccountsETH[bondOwner[counter]],_distAmountLocal);
                totalBondDivsETH[counter] = SafeMath.add(totalBondDivsETH[counter],_distAmountLocal);
                counter = counter + 1;
            } 

            bondFund = 0;
           
        }
    }

    function extDistributeBondFund() public
    onlyOwner()
    {
        if(bondFund > 0){
            uint counter = 1;

            while (counter < nextAvailableBond) { 

                uint _distAmountLocal = SafeMath.div(SafeMath.mul(bondFund, bondPrice[counter]),totalBondValue);
                ownerAccountsETH[bondOwner[counter]] = SafeMath.add(ownerAccountsETH[bondOwner[counter]],_distAmountLocal);
                totalBondDivsETH[counter] = SafeMath.add(totalBondDivsETH[counter],_distAmountLocal);
                counter = counter + 1;
            } 
            bondFund = 0;
            
        }
    }


function returnTokensToExchange()
    
        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] > 0);
        uint _amount = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
         

        BCHIPTOKEN.transfer(_customerAddress, _amount);
         
        emit onWithdrawTokens(_customerAddress, _amount);
    }


    function withdraw()
    
        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccountsETH[_customerAddress] > 0);
        uint _dividends = ownerAccountsETH[_customerAddress];
        ownerAccountsETH[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
         
        emit onWithdrawETH(_customerAddress, _dividends);
    }

    function withdrawPart(uint _amount)
    
        public
        onlyOwner()
    {
        address _customerAddress = msg.sender;
        require(ownerAccountsETH[_customerAddress] > 0);
        require(_amount <= ownerAccountsETH[_customerAddress]);
        ownerAccountsETH[_customerAddress] = SafeMath.sub(ownerAccountsETH[_customerAddress],_amount);
        _customerAddress.transfer(_amount);
         
        emit onWithdrawETH(_customerAddress, _amount);
    }

    function refund(address _to)   
        public
        onlyOwner()
    {
        
        uint _divAmount = SafeMath.sub(address(this).balance, bondFund);
        require (_divAmount <= address(this).balance);
        contractETH = SafeMath.sub(contractETH, _divAmount);
        _to.transfer(_divAmount);
    }

    function deposit(){
        
        contractETH = SafeMath.add(contractETH, msg.value);
        bondFund = SafeMath.add(bondFund, msg.value);
    }
    

 
    
     
    function transferBond(address _to, uint _bond )
       
        public
    {
        require(bondOwner[_bond] == msg.sender);

        bondOwner[_bond] = _to;

        emit transferBondEvent(msg.sender, _to, _bond);

    }

    
     
     
    function setName(string _name)
        onlyOwner()
        public
    {
        name = _name;
    }
    
     
    function setSymbol(string _symbol)
        onlyOwner()
        public
    {
        symbol = _symbol;
    }


    
    function setExchangeAddress(address _newExchangeAddress)
        onlyOwner()
        public
    {
        exchangeContract = _newExchangeAddress;
    }


    function setHalfLifeTime(uint _time)
        onlyOwner()
        public
    {
        halfLifeTime = _time;
    }

    function setHalfLifeRate(uint _rate)
        onlyOwner()
        public
    {
        halfLifeRate = _rate;
    }


    function setInitialPrice(uint _price)
        onlyOwner()
        public
    {
        initialPrice = _price;
    }

    function setMaxbonds(uint _bond)  
        onlyOwner()
        public
    {
        maxBonds = _bond;
    }

    function setBondPrice(uint _bond, uint _price)    
        onlyOwner()
        public
    {
        require(bondOwner[_bond] == dev);
        require(_price < bondPrice[_bond]);

         

        bondPreviousPrice[_bond] = SafeMath.div(SafeMath.mul(_price,75),100);

        bondPrice[_bond] = _price;

        getTotalBondValue();
        getTotalOwnerAccounts();
    }
    
    function addNewbond(uint _price) 
        onlyOwner()
        public
    {
        require(nextAvailableBond < maxBonds);
        bondPrice[nextAvailableBond] = _price;
        bondOwner[nextAvailableBond] = dev;
        totalBondDivs[nextAvailableBond] = 0;
        bondPreviousPrice[nextAvailableBond] = 0;
        nextAvailableBond = nextAvailableBond + 1;
         
        getTotalBondValue();
        getTotalOwnerAccounts();
        
    }

    function setAllowLocalBuy(bool _allow)   
        onlyOwner()
        public
    {
        allowLocalBuy = _allow;
    }

     function setAllowPlayer(bool _allow)   
        onlyOwner()
        public
    {
        boolAllowPlayer = _allow;
    }

    function setAllowPriceLower(bool _allow)   
        onlyOwner()
        public
    {
        allowPriceLower = _allow;
    }

    function setAllowHalfLife(bool _allow)   
        onlyOwner()
        public
    {
        allowHalfLife = _allow;
    }

    function setAllowReferral(bool _allowReferral)   
        onlyOwner()
        public
    {
        allowReferral = _allowReferral;
    }

    function setAutoNewbond(bool _autoNewBond)   
        onlyOwner()
        public
    {
        allowAutoNewBond = _autoNewBond;
    }

    function setRates(uint8 _newDistRate, uint8 _newDevRate,  uint8 _newOwnerRate)   
        onlyOwner()
        public
    {
        require((_newDistRate + _newDevRate + _newOwnerRate) == 100);
        require(_newDevRate <= 10);
        devDivRate = _newDevRate;
        ownerDivRate = _newOwnerRate;
        distDivRate = _newDistRate;
    }

    function setLowerBondPrice(uint _bond, uint _newPrice)    
    
    {
        require(allowPriceLower);
        require(bondOwner[_bond] == msg.sender);
        require(_newPrice < bondPrice[_bond]);
        require(_newPrice >= initialPrice);

         

        bondPreviousPrice[_bond] = SafeMath.div(SafeMath.mul(_newPrice,75),100);

        bondPrice[_bond] = _newPrice;
        getTotalBondValue();
        getTotalOwnerAccounts();
    }

 
    
     
     

  
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }


    function getMyBalance()
        public
        view
        returns(uint)
    {
        return ownerAccounts[msg.sender];
    }

    function getOwnerBalance(address _bondOwner)
        public
        view
        returns(uint)
    {
        require(msg.sender == dev);
        return ownerAccounts[_bondOwner];
    }
    
    function getBondPrice(uint _bond)
        public
        view
        returns(uint)
    {
        require(_bond <= nextAvailableBond);
        return bondPrice[_bond];
    }

    function getBondOwner(uint _bond)
        public
        view
        returns(address)
    {
        require(_bond <= nextAvailableBond);
        return bondOwner[_bond];
    }

    function gettotalBondDivs(uint _bond)
        public
        view
        returns(uint)
    {
        require(_bond <= nextAvailableBond);
        return totalBondDivs[_bond];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
     
        return totalDivsProduced;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address (this).balance;
    }

    function getNextAvailableBond()
        public
        view
        returns(uint)
    {
        return nextAvailableBond;
    }

    function getTotalBondValue()
        internal
        view
        {
            uint counter = 1;
            uint _totalVal = 0;

            while (counter < nextAvailableBond) { 

                _totalVal = SafeMath.add(_totalVal,bondPrice[counter]);
                
                counter = counter + 1;
            } 
            totalBondValue = _totalVal;
            
        }

    function getTotalOwnerAccounts()
        internal
        view
        {
    
        }

    }

 
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