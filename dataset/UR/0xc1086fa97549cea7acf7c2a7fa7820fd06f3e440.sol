 

pragma solidity ^0.4.21;

 
 
 
 
 

 


contract Dividends{
     
    uint256 constant TokenSupply = 10000000;
    
    uint256 public TotalPaid = 0;
    
    uint16 public Tax = 1250; 
    
    address dev;
    
    mapping (address => uint256) public MyTokens;
    mapping (address => uint256) public DividendCollectSince;
    
     
    mapping(address => uint256[2]) public SellOrder;
    
     
     
    function GetSellOrderDetails(address who) public view returns (uint256, uint256){
        return (SellOrder[who][0], SellOrder[who][1]);
    }
    
    function ViewMyTokens(address who) public view returns (uint256){
        return MyTokens[who];
    }
    
    function ViewMyDivs(address who) public view returns (uint256){
        uint256 tkns = MyTokens[who];
        if (tkns==0){
            return 0;
        }
        return (GetDividends(who, tkns));
    }
    
    function Bal() public view returns (uint256){
        return (address(this).balance);
    }
    
     
    function Dividends() public {
        dev = msg.sender;
         
        MyTokens[msg.sender] = TokenSupply - 400000;
         
        MyTokens[address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285)] = 200000;
         
        MyTokens[address(0x26581d1983ced8955C170eB4d3222DCd3845a092)] = 200000;
         
        PlaceSellOrder(1600000, (0.5 szabo));  
    }
    
    function GetDividends(address who, uint256 TokenAmount) internal view  returns(uint256){
        if (TokenAmount == 0){
            return 0;
        }
        uint256 TotalContractIn = address(this).balance + TotalPaid;
         
         
        
        uint256 MyBalance = sub(TotalContractIn, DividendCollectSince[who]);
        
        return  ((MyBalance * TokenAmount) / (TokenSupply));
    }
    

    event Sold(address Buyer, address Seller, uint256 price, uint256 tokens);
    function Buy(address who) public payable {
        
         
        uint256[2] memory order = SellOrder[who];
        uint256 amt_available = order[0];
        uint256 price = order[1];
        
        uint256 excess = 0;
        
         
        if (amt_available == 0){
            revert();
        }
        
        uint256 max = amt_available * price; 
        uint256 currval = msg.value;
         
        if (currval > max){
            excess = (currval-max);
            currval = max;
        }
        



        uint256 take = currval / price;
        
        if (take == 0){
            revert();  
        }
        excess = excess + sub(currval, take * price); 

        
        if (excess > 0){
            msg.sender.transfer(excess);
        }
        
        currval = sub(currval,excess);
        
         

        uint256 fee = (Tax * currval)/10000;
        dev.transfer(fee);
        who.transfer(currval-fee);
        
         
         
      
       
      
        _withdraw(who, MyTokens[who]);
        if (MyTokens[msg.sender] > 0){
            
            _withdraw(msg.sender, MyTokens[msg.sender]);
        }
        MyTokens[who] = MyTokens[who] - take; 
        SellOrder[who][0] = SellOrder[who][0]-take; 
        MyTokens[msg.sender] = MyTokens[msg.sender] + take;
     
        DividendCollectSince[msg.sender] = (address(this).balance) + TotalPaid;
        
        emit Sold(msg.sender, who, price, take);
        
    }
    
    function Withdraw() public {
        _withdraw(msg.sender, MyTokens[msg.sender]);
    }
    
    function _withdraw(address who, uint256 amt) internal{
         
         
        if (MyTokens[who] < amt){
            revert();  
        }
        
        uint256 divs = GetDividends(who, amt);
        
        who.transfer(divs);
        TotalPaid = TotalPaid + divs;
        
        DividendCollectSince[who] = TotalPaid + address(this).balance;
    }
    
    event SellOrderPlaced(address who, uint256 amt, uint256 price);
    function PlaceSellOrder(uint256 amt, uint256 price) public {
         
        if (amt > MyTokens[msg.sender]){
            revert();  
        }
        SellOrder[msg.sender] = [amt,price];
        emit SellOrderPlaced(msg.sender, amt, price);
    }
    
    function ChangeTax(uint16 amt) public {
        require (amt <= 2500);
        require(msg.sender == dev);
        Tax=amt;
    }
    
    
     
    function() public payable {
        
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    } 
    
}