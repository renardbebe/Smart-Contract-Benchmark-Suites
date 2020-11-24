 

 
pragma solidity ^0.4.11;

 
contract Guarded {

    modifier isValidAmount(uint256 _amount) { 
        require(_amount > 0); 
        _; 
    }

     
    modifier isValidAddress(address _address) {
        require(_address != 0x0 && _address != address(this));
        _;
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

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract FaradTokenSwap is Guarded, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) contributions;           
    uint256 contribCount = 0;

    string public version = '0.1.2';

    uint256 public startBlock = 4280263;                 
    uint256 public endBlock = 4334263;                   

    uint256 public totalEtherCap = 1184834 ether;        
    uint256 public weiRaised = 0;                        
    uint256 public minContrib = 0.05 ether;              

    address public wallet = 0x5dc638EAa4f823612DC278d0f039588bb10112a2;

    event Contribution(address indexed _contributor, uint256 _amount);

    function FaradTokenSwap() {
    }

     
     
    function setStartBlock(uint256 _startBlock) onlyOwner public {
        startBlock = _startBlock;
    }

     
     
    function setEndBlock(uint256 _endBlock) onlyOwner public {
        endBlock = _endBlock;
    }

     
     
    function setWeiRaised(uint256 _weiRaised) onlyOwner public {
        weiRaised = weiRaised.add(_weiRaised);
    }

     
     
    function setWallet(address _wallet) onlyOwner public {
        wallet = _wallet;
    }

     
    function setMinContribution(uint256 _minContrib) onlyOwner public {
        minContrib = _minContrib;
    }

     
    function hasEnded() public constant returns (bool) {
        return block.number >= endBlock;
    }

     
    function isActive() public constant returns (bool) {
        return block.number >= startBlock && block.number <= endBlock;
    }

    function () payable {
        processContributions(msg.sender, msg.value);
    }

     
    function processContributions(address _contributor, uint256 _weiAmount) payable {
        require(validPurchase());

        uint256 updatedWeiRaised = weiRaised.add(_weiAmount);

         
        weiRaised = updatedWeiRaised;

         
        contributions[_contributor] = contributions[_contributor].add(_weiAmount);
        contribCount += 1;
        Contribution(_contributor, _weiAmount);

         
        forwardFunds();
    }

     
    function validPurchase() internal constant returns (bool) {
        uint256 current = block.number;

        bool withinPeriod = current >= startBlock && current <= endBlock;
        bool minPurchase = msg.value >= minContrib;

         
        uint256 totalWeiRaised = weiRaised.add(msg.value);
        bool withinCap = totalWeiRaised <= totalEtherCap;

         
        return withinPeriod && minPurchase && withinCap;
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}