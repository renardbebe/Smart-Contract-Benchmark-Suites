 

pragma solidity ^0.4.24;

contract Bonds {
     

    uint ACTIVATION_TIME = 1540213200;

    modifier onlyOwner(){
        require(msg.sender == dev);
        _;
    }

    modifier isActivated(){
        require(now >= ACTIVATION_TIME);
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


     
    string public name = "BONDS";
    string public symbol = "BOND";

    uint8 constant public nsDivRate = 10;
    uint8 constant public devDivRate = 5;
    uint8 constant public ownerDivRate = 50;
    uint8 constant public distDivRate = 40;
    uint8 constant public referralRate = 5;

    uint8 constant public decimals = 18;

    uint public totalBondValue = 9e18;


    

    mapping(uint => address) internal bondOwner;
    mapping(uint => uint) public bondPrice;
    mapping(uint => uint) internal bondPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalBondDivs;
    mapping(uint => string) internal bondName;

    uint bondPriceIncrement = 110;    
    uint totalDivsProduced = 0;

    uint public maxBonds = 200;

    uint public initialPrice = 1e17;    

    uint public nextAvailableBond;

    bool allowReferral = false;

    bool allowAutoNewBond = false;

    uint public bondFund = 0;

    address dev;
    address fundsDividendAddr;
    address promoter1;
    address promoter2;
    address promoter3;

     
     
    constructor()
        public
    {
        dev = msg.sender;
        fundsDividendAddr = 0xBA209A9533FEAFA3c53Bc117Faf3561b5AB6B6f2;
        promoter1 = 0xEc31176d4df0509115abC8065A8a3F8275aafF2b;
        promoter2 = 0xEafE863757a2b2a2c5C3f71988b7D59329d09A78;
        promoter3 = 0x4ffE17a2A72bC7422CB176bC71c04EE6D87cE329;
        nextAvailableBond = 13;

        bondOwner[1] = dev;
        bondPrice[1] = 2e18; 
        bondPreviousPrice[1] = 0;

        bondOwner[2] = dev;
        bondPrice[2] = 15e17; 
        bondPreviousPrice[2] = 0;

        bondOwner[3] = dev;
        bondPrice[3] = 10e17; 
        bondPreviousPrice[3] = 0;

        bondOwner[4] = promoter1;
        bondPrice[4] = 9e17; 
        bondPreviousPrice[4] = 0;

        bondOwner[5] = promoter1;
        bondPrice[5] = 8e17; 
        bondPreviousPrice[5] = 0;

        bondOwner[6] = promoter1;
        bondPrice[6] = 7e17; 
        bondPreviousPrice[6] = 0;

        bondOwner[7] = promoter2;
        bondPrice[7] = 6e17; 
        bondPreviousPrice[7] = 0;

        bondOwner[8] = promoter2;
        bondPrice[8] = 5e17; 
        bondPreviousPrice[8] = 0;

        bondOwner[9] = promoter2;
        bondPrice[9] = 4e17; 
        bondPreviousPrice[9] = 0;

        bondOwner[10] = promoter3;
        bondPrice[10] = 3e17; 
        bondPreviousPrice[10] = 0;

        bondOwner[11] = promoter3;
        bondPrice[11] = 2e17; 
        bondPreviousPrice[11] = 0;

        bondOwner[12] = promoter3;
        bondPrice[12] = 1e17; 
        bondPreviousPrice[12] = 0;
    }

    function addTotalBondValue(uint _new, uint _old)
    internal
    {
         
        totalBondValue = SafeMath.add(totalBondValue, SafeMath.sub(_new,_old));
    }

    function buy(uint _bond, address _referrer)
        isActivated()
        public
        payable

    {
        require(_bond <= nextAvailableBond);
        require(msg.value >= bondPrice[_bond]);
        require(msg.sender != bondOwner[_bond]);

        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value,bondPriceIncrement),100);

          
        uint _baseDividends = msg.value - bondPreviousPrice[_bond];
        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        uint _nsDividends = SafeMath.div(SafeMath.mul(_baseDividends, nsDivRate),100);
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends,ownerDivRate),100);

        totalBondDivs[_bond] = SafeMath.add(totalBondDivs[_bond],_ownerDividends);
        _ownerDividends = SafeMath.add(_ownerDividends,bondPreviousPrice[_bond]);

        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends,distDivRate),100);


         
        if (allowReferral && _referrer != msg.sender) {
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);
            _distDividends = SafeMath.sub(_distDividends, _referralDividends);

            if (_referrer == 0x0) {
                fundsDividendAddr.transfer(_referralDividends);
            }
            else {
                ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
            }
        }

         
        address _previousOwner = bondOwner[_bond];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner],_ownerDividends);
        fundsDividendAddr.transfer(_nsDividends);

        bondOwner[_bond] = _newOwner;

        distributeYield(_distDividends);
        distributeBondFund();
         
        bondPreviousPrice[_bond] = msg.value;
        bondPrice[_bond] = _newPrice;
        addTotalBondValue(_newPrice, bondPreviousPrice[_bond]);

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
         
        emit onWithdraw(_customerAddress, _dividends);
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
         
        emit onWithdraw(_customerAddress, _amount);
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
        addTotalBondValue(_price, 0);

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

    function getBondDivShare(uint _bond)
    public
    view
    returns(uint)
    {
        require(_bond <= nextAvailableBond);
        return SafeMath.div(SafeMath.mul(bondPrice[_bond],10000),totalBondValue);
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