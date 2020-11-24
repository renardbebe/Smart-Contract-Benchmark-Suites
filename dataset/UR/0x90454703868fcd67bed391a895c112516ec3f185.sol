 

pragma solidity ^0.4.21;

 
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


 
 

contract starShipTokenInterface {
    string public name;
    string public symbol;
    uint256 public ID;
    address public owner;

    function transfer(address _to) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to);
}


contract starShipToken is starShipTokenInterface {
    using SafeMath for uint256;

  
  constructor(string _name, string _symbol, uint256 _ID) public {
    name = _name;
    symbol = _symbol;
    ID = _ID;
    owner = msg.sender;
  }

   
  function viewOwner() public view returns (address) {
    return owner;
  }

   
  function transfer(address _to) public returns (bool) {
    require(_to != address(0));
    require(msg.sender == owner);

    owner = _to;
    emit Transfer(msg.sender, _to);
    return true;
  }
}

 
contract hotPotatoAuction {
     
    starShipToken public token;
    
     
    uint256 public totalBids;
    
     
    uint256 public startingPrice;
    
     
    uint256 public currentBid;
    
     
    uint256 public currentMinBid;
    
     
    uint256 public auctionEnd;
    
     
    uint256 public hotPotatoPrize;
    
     
    address public seller;
    
    
    address public highBidder;
    address public loser;

    function hotPotatoAuction(
        starShipToken _token,
        uint256 _startingPrice,
        uint256 _auctionEnd
    )
        public
    {
        token = _token;
        startingPrice = _startingPrice;
        currentMinBid = _startingPrice;
        totalBids = 0;
        seller = msg.sender;
        auctionEnd = _auctionEnd;
        hotPotatoPrize = _startingPrice;
        currentBid = 0;
    }
    
    mapping(address => uint256) public balanceOf;

     
     
    function withdrawBalance(uint256 amount) returns(bool) {
        require(amount <= address(this).balance);
        require (msg.sender == seller);
        seller.transfer(amount);
        return true;
    }

     
    function withdraw() public returns(bool) {
        require(msg.sender != highBidder);
        
        uint256 amount = balanceOf[loser];
        balanceOf[loser] = 0;
        loser.transfer(amount);
        return true;
    }
    

    event Bid(address highBidder, uint256 highBid);

    function bid() public payable returns(bool) {
        require(now < auctionEnd);
        require(msg.value >= startingPrice);
        require (msg.value >= currentMinBid);
        
        if(totalBids !=0)
        {
            loser = highBidder;
        
            require(withdraw());
        }
        
        highBidder = msg.sender;
        
        currentBid = msg.value;
        
        hotPotatoPrize = currentBid/20;
        
        balanceOf[msg.sender] = msg.value + hotPotatoPrize;
        
        if(currentBid < 1000000000000000000)
        {
            currentMinBid = msg.value + currentBid/2;
            hotPotatoPrize = currentBid/20; 
        }
        else
        {
            currentMinBid = msg.value + currentBid/5;
            hotPotatoPrize = currentBid/20;
        }
        
        totalBids = totalBids + 1;
        
        return true;
        emit Bid(highBidder, msg.value);
    }

    function resolve() public {
        require(now >= auctionEnd);
        require(msg.sender == seller);
        require (highBidder != 0);
        
        require (token.transfer(highBidder));

        balanceOf[seller] += balanceOf[highBidder];
        balanceOf[highBidder] = 0;
        highBidder = 0;
    }
     
     
    function getBalanceContract() constant returns(uint){
        return address(this).balance;
    }
}