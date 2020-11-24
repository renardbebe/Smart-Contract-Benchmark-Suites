 

pragma solidity ^0.4.24;

 

contract BossCards {
     



    modifier onlyOwner(){

        require(msg.sender == dev);
        _;
    }


     
    event oncardPurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice
    );

    event onWithdraw(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

     
    event Transfer(
        address from,
        address to,
        uint256 card
    );


     
    string public name = "FOUNDER CARDS";
    string public symbol = "MOBCARD";

    uint8 constant public mobDivRate = 10;
    uint8 constant public ownerDivRate = 50;
    uint8 constant public distDivRate = 40;
    uint8 constant public referralRate = 5;
    uint8 constant public decimals = 18;
    uint public totalCardValue = 7.25 ether;  
    uint public precisionFactor = 9;


    

    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;

    uint cardPriceIncrement = 110;
    uint totalDivsProduced = 0;

    uint public totalCards;

    bool allowReferral = true;

    address dev;
    address bossman;
    address mobDivsAddr;


     
     
    constructor()
        public
    {
        dev = msg.sender;
        bossman = 0x41FE3738B503cBaFD01C1Fd8DD66b7fE6Ec11b01;
        mobDivsAddr = 0x5E38C0BD4E0dDB71E67B6693Ddc4c7D7b4f26b49;

        totalCards = 12;

        cardOwner[0] = bossman;
        cardPrice[0] = 2 ether;
        cardPreviousPrice[0] = cardPrice[0];

        cardOwner[1] = dev;
        cardPrice[1] = 1.5 ether;
        cardPreviousPrice[1] = cardPrice[1];

        cardOwner[2] = dev;
        cardPrice[2] = 1 ether;
        cardPreviousPrice[2] = cardPrice[2];

        cardOwner[3] = dev;
        cardPrice[3] = 0.9 ether;
        cardPreviousPrice[3] = cardPrice[3];

        cardOwner[4] = dev;
        cardPrice[4] = 0.75 ether;
        cardPreviousPrice[4] = cardPrice[4];

        cardOwner[5] = dev;
        cardPrice[5] = 0.50 ether;
        cardPreviousPrice[5] = cardPrice[5];

        cardOwner[6] = dev;
        cardPrice[6] = 0.25 ether;
        cardPreviousPrice[6] = cardPrice[6];

        cardOwner[7] = dev;
        cardPrice[7] = 0.12 ether;
        cardPreviousPrice[7] = cardPrice[7];

        cardOwner[8] = dev;
        cardPrice[8] = 0.08 ether;
        cardPreviousPrice[8] = cardPrice[8];

        cardOwner[9] = dev;
        cardPrice[9] = 0.05 ether;
        cardPreviousPrice[9] = cardPrice[9];

        cardOwner[10] = dev;
        cardPrice[10] = 0.05 ether;
        cardPreviousPrice[10] = cardPrice[10];

        cardOwner[11] = dev;
        cardPrice[11] = 0.05 ether;
        cardPreviousPrice[11] = cardPrice[11];

    }

    function addtotalCardValue(uint _new, uint _old)
    internal
    {
        uint newPrice = SafeMath.div(SafeMath.mul(_new,cardPriceIncrement),100);
        totalCardValue = SafeMath.add(totalCardValue, SafeMath.sub(newPrice,_old));
    }

    function buy(uint _card, address _referrer)
        public
        payable

    {
        require(_card < totalCards);
        require(msg.value == cardPrice[_card]);
        require(msg.sender != cardOwner[_card]);

        addtotalCardValue(msg.value, cardPreviousPrice[_card]);

        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100);

          
        uint _baseDividends = SafeMath.sub(msg.value, cardPreviousPrice[_card]);

        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        uint _mobDividends = SafeMath.div(SafeMath.mul(_baseDividends, mobDivRate),100);

        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);

        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _ownerDividends);

        _ownerDividends = SafeMath.add(_ownerDividends, cardPreviousPrice[_card]);

        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends, distDivRate), 100);

        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {

            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);

            _distDividends = SafeMath.sub(_distDividends, _referralDividends);

            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
        }


         
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);

        mobDivsAddr.transfer(_mobDividends);

        distributeDivs(_distDividends);

         
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;

        emit oncardPurchase(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100));
    }


    function distributeDivs(uint _distDividends) internal{

            for (uint _card=0; _card < totalCards; _card++){

                uint _divShare = SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
                uint _cardDivs = SafeMath.div(SafeMath.mul(_distDividends, _divShare), 10 ** precisionFactor);

                ownerAccounts[cardOwner[_card]] += _cardDivs;

                totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _cardDivs);
            }
        }


    function withdraw()

        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] >= 0.001 ether);

        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;

        _customerAddress.transfer(_dividends);

        emit onWithdraw(_customerAddress, _dividends);
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

    function setcardPrice(uint _card, uint _price)    
        onlyOwner()
        public
    {
        require(cardOwner[_card] == dev);
        cardPrice[_card] = _price;
    }

    function addNewcard(uint _price)
        onlyOwner()
        public
    {
        cardPrice[totalCards-1] = _price;
        cardOwner[totalCards-1] = dev;
        totalCardDivs[totalCards-1] = 0;
        totalCards = totalCards + 1;
    }

    function setAllowReferral(bool _allowReferral)
        onlyOwner()
        public
    {
        allowReferral = _allowReferral;
    }



     
     


    function getMyBalance()
        public
        view
        returns(uint)
    {
        return ownerAccounts[msg.sender];
    }

    function getOwnerBalance(address _cardOwner)
        public
        view
        returns(uint)
    {
        return ownerAccounts[_cardOwner];
    }

    function getcardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return cardPrice[_card];
    }

    function getcardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card < totalCards);
        return cardOwner[_card];
    }

    function gettotalCardDivs(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return totalCardDivs[_card];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
        return totalDivsProduced;
    }

    function getCardDivShare(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
    }

    function getCardDivs(uint  _card, uint _amt)
        public
        view
        returns(uint)
    {
        uint _share = getCardDivShare(_card);
        return SafeMath.div(SafeMath.mul( _share, _amt), 10 ** precisionFactor);
    }

    function gettotalCardValue()
        public
        view
        returns(uint)
    {

        return totalCardValue;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address (this).balance;
    }

    function gettotalCards()
        public
        view
        returns(uint)
    {
        return totalCards;
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