 

pragma solidity ^0.4.24;

 


contract STOCKReceivingContract {
   
  function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}


contract STOCKInterface 
{

    
    
    function transfer(address _to, uint _value) public returns (bool);
     
    function transferAndCall(address _sender, uint _value, bytes _data) public returns(bool);
    function balanceOf(address _customerAddress) public returns(bool);
}

contract MORTGAGEBONDS is STOCKReceivingContract {
     
   


    modifier onlyOwner(){
        
        require(msg.sender == dev);
        _;
    }
    

     
    event onBondPurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 bond,
        uint256 newPrice
    );
    
    event onWithdrawETH(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

      event onWithdrawTokens(
        address customerAddress,
        uint256 ethereumWithdrawn
    );
    
     
    event Transfer(
        address from,
        address to,
        uint256 bond
    );


    
     
    string public name = "MORTGAGEBONDS";
    string public symbol = "YIELD";

    

    uint8 constant public referralRate = 5; 

    uint8 constant public decimals = 18;
  
    uint public totalBondValue = 17000e18;

    uint constant dayBlockFactor = 21600;

    
    
    
    mapping(uint => address) internal bondOwner;
    mapping(uint => uint) public bondPrice;
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

    STOCKInterface public STOCKTOKEN;
   
    address dev;

    uint256 internal tokenSupply_ = 0;

    uint public halfLifeTime = 10;    
    uint public halfLifeRate = 67;    

    bool public allowHalfLife = false;

    bool public allowLocalBuy = false;


    address add1 = 0x41FE3738B503cBaFD01C1Fd8DD66b7fE6Ec11b01;
    address add2 = 0xAe3dC7FA07F9dD030fa56C027E90998eD9Fe9D61;

    


     
     
    constructor(address _exchangeAddress, address _bankRollAddress)
        public
    {

        STOCKTOKEN = STOCKInterface(_exchangeAddress);
        exchangeContract = _exchangeAddress;

         
        bankRoll = _bankRollAddress;





        dev = msg.sender;
        nextAvailableBond = 23;

        bondOwner[1] = add1;
        bondPrice[1] = 1500e18;
        bondPreviousPrice[1] = 0;

        bondOwner[2] = add1;
        bondPrice[2] = 1430e18;
        bondPreviousPrice[2] = 0;

        bondOwner[3] = dev;
        bondPrice[3] = 1360e18;
        bondPreviousPrice[3] = 0;

        bondOwner[4] = dev;
        bondPrice[4] = 1290e18;
        bondPreviousPrice[4] = 0;

        bondOwner[5] = dev;
        bondPrice[5] = 1220e18;
        bondPreviousPrice[5] = 0;

        bondOwner[6] = dev;
        bondPrice[6] = 1150e18;
        bondPreviousPrice[6] = 0;

        bondOwner[7] = dev;
        bondPrice[7] = 1080e18;
        bondPreviousPrice[7] = 0;

        bondOwner[8] = dev;
        bondPrice[8] = 1010e18;
        bondPreviousPrice[8] = 0;

        bondOwner[9] = dev;
        bondPrice[9] = 940e18;
        bondPreviousPrice[9] = 0;

        bondOwner[10] = dev;
        bondPrice[10] = 870e18;
        bondPreviousPrice[10] = 0;

        bondOwner[11] = add2;
        bondPrice[11] = 800e18;
        bondPreviousPrice[11] = 0;

        bondOwner[12] = dev;
        bondPrice[12] = 730e18;
        bondPreviousPrice[12] = 0;

        bondOwner[13] = dev;
        bondPrice[13] = 660e18;
        bondPreviousPrice[13] = 0;

        bondOwner[14] = dev;
        bondPrice[14] = 590e18;
        bondPreviousPrice[14] = 0;

        bondOwner[15] = dev;
        bondPrice[15] = 520e18;
        bondPreviousPrice[15] = 0;

        bondOwner[16] = dev;
        bondPrice[16] = 450e18;
        bondPreviousPrice[16] = 0;

        bondOwner[17] = dev;
        bondPrice[17] = 380e18;
        bondPreviousPrice[17] = 0;

        bondOwner[18] = dev;
        bondPrice[18] = 310e18;
        bondPreviousPrice[18] = 0;

        bondOwner[19] = dev;
        bondPrice[19] = 240e18;
        bondPreviousPrice[19] = 0;

        bondOwner[20] = dev;
        bondPrice[20] = 170e18;
        bondPreviousPrice[20] = 0;

        bondOwner[21] = dev;
        bondPrice[21] = 150e18;
        bondPreviousPrice[21] = 0;

        bondOwner[22] = dev;
        bondPrice[22] = 150e18;
        bondPreviousPrice[22] = 0;

    }



         
      

    function()
        payable
        public
    {

        uint devAmount = SafeMath.div(SafeMath.mul(devDivRate,msg.value),100);
        uint bondAmount = msg.value - devAmount;
        bondFund = SafeMath.add(bondFund, bondAmount);
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev], devAmount);
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
    {
         
            _from = msg.sender;

            ownerAccounts[_from] = SafeMath.sub(ownerAccounts[_from],bondPrice[_bond]);
            buy(_bond, bondPrice[_bond], _from, _referrer);
         
    }



    function addTotalBondValue(uint _new, uint _old)
    internal
    {
         
        totalBondValue = SafeMath.add(totalBondValue, SafeMath.sub(_new,_old));
    }
    
    function buy(uint _bond, uint _value, address _from, address _referrer)
        internal

    {
        require(_bond <= nextAvailableBond);
        require(_value >= bondPrice[_bond]);
         

        
        bondBlockNumber[_bond] = block.number;    

        uint _newPrice = SafeMath.div(SafeMath.mul(_value,bondPriceIncrement),100);

          
        uint _baseDividends = _value - bondPreviousPrice[_bond];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

         
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),100);

        totalBondDivs[_bond] = SafeMath.add(totalBondDivs[_bond],_ownerDividends);
        _ownerDividends = SafeMath.add(_ownerDividends,bondPreviousPrice[_bond]);
            
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends,distDivRate),100);

        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
                
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends,referralRate),100);
            _distDividends = SafeMath.sub(_distDividends,_referralDividends);
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer],_referralDividends);
        }
            


         
        address _previousOwner = bondOwner[_bond];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner],_ownerDividends);
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev],SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),100));

        bondOwner[_bond] = _newOwner;

        distributeYield(_distDividends);
        distributeBondFund();
         
        bondPreviousPrice[_bond] = _value;
        bondPrice[_bond] = _newPrice;
        addTotalBondValue(_newPrice, bondPreviousPrice[_bond]);
        
       
        emit onBondPurchase(msg.sender, _value, _bond, SafeMath.div(SafeMath.mul(_value,bondPriceIncrement),100));
     
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
                uint _life = SafeMath.sub(currentBlock, bondBlockNumber[counter]);

                if (_life > SafeMath.mul(halfLifeTime, dayBlockFactor)) {
                    
                    bondBlockNumber[counter] = currentBlock;   
                    bondPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter], halfLifeRate),100);  
                    bondPreviousPrice[counter] = SafeMath.div(SafeMath.mul(bondPrice[counter],75),100);

                }
                 
            }

            counter = counter + 1;
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
         

        STOCKTOKEN.transfer(_customerAddress, _amount);
         
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


    

 
    
     
    function transfer(address _to, uint _bond )
       
        public
    {
        require(bondOwner[_bond] == msg.sender);

        bondOwner[_bond] = _to;

        emit Transfer(msg.sender, _to, _bond);

    }


       
    function transferTokens(address _to, uint _bond )
       
        public
    {
        require(bondOwner[_bond] == msg.sender);

        bondOwner[_bond] = _to;

        emit Transfer(msg.sender, _to, _bond);

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
        bondPrice[_bond] = _price;
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
        addTotalBondValue(_price, 0);
        
    }

    function setAllowLocalBuy(bool _allow)   
        onlyOwner()
        public
    {
        allowLocalBuy = _allow;
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
        devDivRate = _newDevRate;
        ownerDivRate = _newOwnerRate;
        distDivRate = _newDistRate;
    }

    function setLowerBondPrice(uint _bond, uint _newPrice)    
    
    {
        require(bondOwner[_bond] == msg.sender);
        require(_newPrice < bondPrice[_bond]);
        require(_newPrice >= initialPrice);

        totalBondValue = SafeMath.sub(totalBondValue,SafeMath.sub(bondPrice[_bond],_newPrice));

        bondPreviousPrice[_bond] = SafeMath.div(SafeMath.mul(_newPrice,75),100);

        bondPrice[_bond] = _newPrice;

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

    function getTotalBondValue()
        public
        view
        returns(uint)
    {
      
        return totalBondValue;
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