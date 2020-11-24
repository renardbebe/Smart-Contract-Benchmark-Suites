 

pragma solidity ^0.4.9;

contract SaleOfChametz {
    struct Deal {
        address seller;
    }
    
    Deal[] public deals;
    uint   public nextDealIndex;
    
    mapping(address=>uint) public sellerNumOpenDeals;
    mapping(address=>uint) public buyerNumDeals;
    
    
    event Sell( address indexed seller, uint timestamp );
    event Buy( address indexed buyer, address indexed seller, uint timestamp );
    event ReturnChametz( address indexed buyer, uint payment, uint timestamp );
    event CancelSell( address indexed seller, uint payment, uint timestamp );
    
    
    uint constant public passoverStartTime = 1491840000;
    uint constant public passoverEndTime = 1492401600;                                        
    
    uint constant public downPayment = 30 finney;
    uint constant public buyerBonus = 30 finney;
    
    function SaleOfChametz() {}
    
    function numChametzForSale() constant returns(uint) {
        return deals.length - nextDealIndex;
    }
    
    function sell() payable {
        if( now >= passoverStartTime ) throw;  
        if( msg.value != buyerBonus ) throw;
        
        Deal memory deal;
        deal.seller = msg.sender;
        
        sellerNumOpenDeals[ msg.sender ]++;
        
        deals.push(deal);
        
        Sell( msg.sender, now );
    }
    
    function buy() payable {
        if( now >= passoverStartTime ) throw;  
        if( msg.value != downPayment ) throw;
        if( deals.length <= nextDealIndex ) throw;  
        
        Deal memory deal = deals[nextDealIndex];
        if( sellerNumOpenDeals[ deal.seller ] > 0 ) {
            sellerNumOpenDeals[ deal.seller ]--;
        }
        
        buyerNumDeals[msg.sender]++;
        nextDealIndex++;
        
        Buy( msg.sender, deal.seller, now );
    }
    
    function returnChametz() {
        if( now <= passoverEndTime ) throw;  
        if( buyerNumDeals[msg.sender] == 0 ) throw;  
        uint payment = buyerNumDeals[msg.sender] * (downPayment + buyerBonus);
        buyerNumDeals[msg.sender] = 0;
        if( ! msg.sender.send( payment ) ) throw;
        
        ReturnChametz( msg.sender, payment, now );
    }
    
    function cancelSell() {
       if( now <= passoverStartTime ) throw;  
     
        if( sellerNumOpenDeals[ msg.sender ] == 0 ) throw;  
        uint payment = sellerNumOpenDeals[ msg.sender ] * buyerBonus;
        sellerNumOpenDeals[ msg.sender ] = 0;
        if( ! msg.sender.send( payment ) ) throw;
        
        CancelSell( msg.sender, payment, now );
    }
    
}