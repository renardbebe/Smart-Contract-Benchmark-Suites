 

pragma solidity 0.4.21;

 
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract PrivateSaleExchangeRate is Ownable {
    using SafeMath for uint256;
    uint256 public rate;
    uint256 public timestamp;
    event UpdateUsdEthRate(uint256 _rate);
    
    function PrivateSaleExchangeRate(uint256 _rate) public {
        require(_rate > 0);
        rate = _rate;
        timestamp = now;
    }
    
     
    function updateUsdEthRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        require(rate != _rate);
        emit UpdateUsdEthRate(_rate);
        rate = _rate;
        timestamp = now;
    }
    
      
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256){
        
         
        uint256 cost = 550;
        
        if(_weiAmount < 10 ether){ 
            cost = 550; 
        }else if(_weiAmount < 25 ether){ 
            cost = 545; 
        }else if(_weiAmount < 50 ether){ 
            cost = 540; 
        }else if(_weiAmount < 250 ether){ 
            cost = 530; 
        }else if(_weiAmount < 500 ether){ 
            cost = 520; 
        }else if(_weiAmount < 1000 ether){ 
            cost = 510;
        }else{
            cost = 500;
        }
        return _weiAmount.mul(rate).mul(10000).div(cost);
    }
}