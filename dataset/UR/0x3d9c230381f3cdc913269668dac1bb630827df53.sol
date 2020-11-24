 

pragma solidity 0.4.19;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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


 
 
contract HireMe is Ownable {
    struct Bid {  
        bool exists;          
        uint id;              
        uint timestamp;       
        address bidder;       
        uint amount;          
        string email;         
        string organisation;  
    }

    event BidMade(uint indexed id, address indexed bidder, uint indexed amount);
    event Reclaimed(address indexed bidder, uint indexed amount);
    event Donated(uint indexed amount);

    Bid[] public bids;  
    uint[] public bidIds;  

     
    uint private constant MIN_BID = 1 ether;
    uint private constant BID_STEP = 0.01 ether;
    uint private constant INITIAL_BIDS = 4;

    uint private constant EXPIRY_DAYS_BEFORE = 7 days;
    uint private constant EXPIRY_DAYS_AFTER = 3 days;

     
     
     

     
     
    string public constant AUTHORSIGHASH = "8c8b82a2d83a33cb0f45f5f6b22b45c1955f08fc54e7ab4d9e76fb76843c4918";

     
    bool public donated = false;

     
    bool public manuallyEnded = false;

     
     
    mapping (address => uint) public addressBalance;

     
    address public charityAddress = 0x635599b0ab4b5c6B1392e0a2D1d69cF7d1ddDF02;

     
     
    function manuallyEndAuction () public onlyOwner {
        require(manuallyEnded == false);
        require(bids.length == 0);

        manuallyEnded = true;
    }

     
    function bid(string _email, string _organisation) public payable {
        address _bidder = msg.sender;
        uint _amount = msg.value;
        uint _id = bids.length;

         
        require(!hasExpired() && !manuallyEnded);

         
         
        require(_bidder != owner && _bidder != charityAddress);

         
        require(_bidder != address(0));
        require(bytes(_email).length > 0);
        require(bytes(_organisation).length > 0);

         
        require(_amount >= calcCurrentMinBid());

         
        bids.push(Bid(true, _id, now, _bidder, _amount, _email, _organisation));
        bidIds.push(_id);

         
         
        addressBalance[_bidder] = SafeMath.add(addressBalance[_bidder], _amount);

         
        BidMade(_id, _bidder, _amount);
    }

    function reclaim () public {
        address _caller = msg.sender;
        uint _amount = calcAmtReclaimable(_caller);

         
         
        require(bids.length >= 2);

         
        require(!manuallyEnded);

         
        require(_amount > 0);

         
         
        uint _newTotal = SafeMath.sub(addressBalance[_caller], _amount);

         
        assert(_newTotal >= 0);

         
        addressBalance[_caller] = _newTotal;

         
        _caller.transfer(_amount);

         
        Reclaimed(_caller, _amount);
    }

    function donate () public {
         
        assert(donated == false);

         
         
        require(msg.sender == owner || msg.sender == charityAddress);

         
        require(hasExpired());

         
         
        assert(!manuallyEnded);

         
        assert(bids.length > 0);

         
        uint _amount;
        if (bids.length == 1) {
             
            _amount = bids[0].amount;
        } else {
             
            _amount = bids[SafeMath.sub(bids.length, 2)].amount;
        }

         
         
        assert(_amount > 0);

         
        donated = true;

         
        charityAddress.transfer(_amount);
        Donated(_amount);
    }

    function calcCurrentMinBid () public view returns (uint) {
        if (bids.length == 0) {
            return MIN_BID;
        } else {
            uint _lastBidId = SafeMath.sub(bids.length, 1);
            uint _lastBidAmt = bids[_lastBidId].amount;
            return SafeMath.add(_lastBidAmt, BID_STEP);
        }
    }

    function calcAmtReclaimable (address _bidder) public view returns (uint) {
         

         
         

         
         

         
         
         

         
         

        uint _totalAmt = addressBalance[_bidder];

        if (bids.length == 0) {
            return 0;
        }

        if (bids[SafeMath.sub(bids.length, 1)].bidder == _bidder) {
             
            if (hasExpired()) {  
                uint _secondPrice = bids[SafeMath.sub(bids.length, 2)].amount;
                return SafeMath.sub(_totalAmt, _secondPrice);

            } else {  
                uint _highestPrice = bids[SafeMath.sub(bids.length, 1)].amount;
                return SafeMath.sub(_totalAmt, _highestPrice);
            }

        } else {  
             
            return _totalAmt;
        }
    }

    function getBidIds () public view returns (uint[]) {
        return bidIds;
    }

     
    function expiryTimestamp () public view returns (uint) {
        uint _numBids = bids.length;

         
        require(_numBids > 0);

         
        uint _lastBidTimestamp = bids[SafeMath.sub(_numBids, 1)].timestamp;

        if (_numBids <= INITIAL_BIDS) {
            return SafeMath.add(_lastBidTimestamp, EXPIRY_DAYS_BEFORE);
        } else {
            return SafeMath.add(_lastBidTimestamp, EXPIRY_DAYS_AFTER);
        }
    }

    function hasExpired () public view returns (bool) {
        uint _numBids = bids.length;

         
        if (_numBids == 0) {
            return false;
        } else {
             
            return now >= this.expiryTimestamp();
        }
    }
}


 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 