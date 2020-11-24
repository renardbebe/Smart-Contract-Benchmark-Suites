 

pragma solidity ^0.4.21;

 

contract BONDS {
     
   


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
    
    event onWithdraw(
        address customerAddress,
        uint256 ethereumWithdrawn
    );
    
     
    event Transfer(
        address from,
        address to,
        uint256 bond
    );

    
     
    string public name = "REDSTREETBONDS";
    string public symbol = "REDBOND";

    

    uint8 constant public referralRate = 5; 

    uint8 constant public decimals = 18;
  
    uint public totalBondValue = 0;

    bool public contractActive = false;


    
    
    
    mapping(uint => address) internal bondOwner;
    mapping(uint => uint) public bondPrice;
    mapping(uint => uint) internal bondPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalBondDivs;
    mapping(uint => string) internal bondName;

    uint bondPriceIncrement = 125;    
    uint totalDivsProduced = 0;

    uint public maxBonds = 200;
    
    uint public initialPrice = 5e17;    

    uint public nextAvailableBond;

    bool allowReferral = false;

    bool allowAutoNewBond = false;

    uint8 public devDivRate = 10;
    uint8 public ownerDivRate = 50;
    uint8 public distDivRate = 40;

    uint public bondFund = 0;
   
    address dev;

    
    


     
     
    function BONDS()
        public
    {
        dev = msg.sender;
        nextAvailableBond = 11;

        bondOwner[1] = dev;
        bondPrice[1] = 5e18; 
        bondPreviousPrice[1] = 0;

        bondOwner[2] = dev;
        bondPrice[2] = 3e18; 
        bondPreviousPrice[2] = 0;

        bondOwner[3] = dev;
        bondPrice[3] = 2e18; 
        bondPreviousPrice[3] = 0;

        bondOwner[4] = dev;
        bondPrice[4] = 1e18; 
        bondPreviousPrice[4] = 0;

        bondOwner[5] = dev;
        bondPrice[5] = 8e17; 
        bondPreviousPrice[5] = 0;

        bondOwner[6] = dev;
        bondPrice[6] = 6e17; 
        bondPreviousPrice[6] = 0;

        bondOwner[7] = dev;
        bondPrice[7] = 5e17; 
        bondPreviousPrice[7] = 0;

        bondOwner[8] = dev;
        bondPrice[8] = 3e17; 
        bondPreviousPrice[8] = 0;

        bondOwner[9] = dev;
        bondPrice[9] = 2e17; 
        bondPreviousPrice[9] = 0;

        bondOwner[10] = dev;
        bondPrice[10] = 1e17; 
        bondPreviousPrice[10] = 0;

        getTotalBondValue();


    }


    function addTotalBondValue(uint _new, uint _old)
    internal
    {
         
        totalBondValue = SafeMath.add(totalBondValue, SafeMath.sub(_new,_old));
    }
    
    function buy(uint _bond, address _referrer)
        public
        payable
       
    {
        require(contractActive);
        require(_bond <= nextAvailableBond);
        require(msg.value >= bondPrice[_bond]);
        require(msg.sender != bondOwner[_bond]);

        
  

        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value,bondPriceIncrement),100);

          
        uint _baseDividends = msg.value - bondPreviousPrice[_bond];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        uint _devDividends = SafeMath.div(SafeMath.mul(_baseDividends,devDivRate),100);
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
        ownerAccounts[dev] = SafeMath.add(ownerAccounts[dev],_devDividends);

        bondOwner[_bond] = _newOwner;

        distributeYield(_distDividends);
        distributeBondFund();
         
        bondPreviousPrice[_bond] = msg.value;
        bondPrice[_bond] = _newPrice;
         
        getTotalBondValue();
       
        emit onBondPurchase(msg.sender, msg.value, _bond, SafeMath.div(SafeMath.mul(msg.value,bondPriceIncrement),100));
     
    }

    function distributeYield(uint _distDividends) internal
    
    {
        uint counter = 1;

        while (counter < nextAvailableBond) { 

            uint _distAmountLocal = SafeMath.div(SafeMath.mul(_distDividends, bondPrice[counter]),totalBondValue);
            ownerAccounts[bondOwner[counter]] = SafeMath.add(ownerAccounts[bondOwner[counter]],_distAmountLocal);
            totalBondDivs[counter] = SafeMath.add(totalBondDivs[counter],_distAmountLocal);
            counter = counter + 1;
        } 

    }
    
    function distributeBondFund() internal
    
    {
        if(bondFund > 0){
            uint counter = 1;

            while (counter < nextAvailableBond) { 

                uint _distAmountLocal = SafeMath.div(SafeMath.mul(bondFund, bondPrice[counter]),totalBondValue);
                ownerAccounts[bondOwner[counter]] = SafeMath.add(ownerAccounts[bondOwner[counter]],_distAmountLocal);
                totalBondDivs[counter] = SafeMath.add(totalBondDivs[counter],_distAmountLocal);
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
                ownerAccounts[bondOwner[counter]] = SafeMath.add(ownerAccounts[bondOwner[counter]],_distAmountLocal);
                totalBondDivs[counter] = SafeMath.add(totalBondDivs[counter],_distAmountLocal);
                counter = counter + 1;
            } 
            bondFund = 0;
        }
    }


    function withdraw()
    
        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] > 0);
        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
         
        onWithdraw(_customerAddress, _dividends);
    }

    function withdrawPart(uint _amount)
    
        public
        onlyOwner()
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] > 0);
        require(_amount <= ownerAccounts[_customerAddress]);
        ownerAccounts[_customerAddress] = SafeMath.sub(ownerAccounts[_customerAddress],_amount);
        _customerAddress.transfer(_amount);
         
        onWithdraw(_customerAddress, _amount);
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
    
     
    function transfer(address _to, uint _bond )
       
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
         
        getTotalBondValue();
        
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

    function setActive(bool _Active)
        onlyOwner()
        public
    {
        contractActive = _Active;
    }

    function setLowerBondPrice(uint _bond, uint _newPrice)    
    
    {
        require(bondOwner[_bond] == msg.sender);
        require(_newPrice < bondPrice[_bond]);
        require(_newPrice >= initialPrice);

         

        bondPrice[_bond] = _newPrice;
        getTotalBondValue();

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